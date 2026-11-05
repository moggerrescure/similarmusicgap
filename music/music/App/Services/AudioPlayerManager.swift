import Foundation
import AVFoundation
import MediaPlayer
import Combine
import SwiftUI

/// Loop playback state
public enum LoopMode: String, CaseIterable {
    case off = "off"
    case all = "all"
    case single = "single"
    
    public var iconName: String {
        switch self {
        case .off: return "repeat"
        case .all: return "repeat"
        case .single: return "repeat.1"
        }
    }
}

/// Core audio playback engine with Dynamic Island, Lock Screen, and background audio support
@MainActor
public final class AudioPlayerManager: ObservableObject {
    public static let shared = AudioPlayerManager()
    
    // Playback state
    @Published public private(set) var currentTrack: UniversalTrack?
    @Published public private(set) var isPlaying: Bool = false
    @Published public private(set) var currentTime: Double = 0.0
    @Published public private(set) var duration: Double = 210.0
    @Published public private(set) var progress: Double = 0.0 // 0.0 to 1.0
    
    // Loop & Shuffle
    @Published public var loopMode: LoopMode = .off
    @Published public var isShuffled: Bool = false
    
    // Favorites registry
    @Published public private(set) var favoriteTrackIds: Set<UUID> = []
    
    // Audio Player & Timer
    private var avPlayer: AVPlayer?
    private var displayLinkTimer: Timer?
    private var playlistQueue: [UniversalTrack] = []
    private var currentIndex: Int = 0
    
    private init() {
        setupAudioSession()
        setupRemoteCommands()
    }
    
    // MARK: - Audio Session Configuration
    private func setupAudioSession() {
        #if os(iOS)
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
        } catch {
            print("⚠️ [AudioPlayerManager] Failed to configure AVAudioSession: \(error)")
        }
        #endif
    }
    
    // MARK: - Remote Media Center (Lock Screen / Dynamic Island)
    private func setupRemoteCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            self.resume()
            return .success
        }
        
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            self.pause()
            return .success
        }
        
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            self.togglePlayPause()
            return .success
        }
        
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            self.playNext()
            return .success
        }
        
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            self.playPrevious()
            return .success
        }
        
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let self = self, let positionEvent = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            self.seek(to: positionEvent.positionTime)
            return .success
        }
    }
    
    private func updateNowPlayingInfo() {
        guard let track = currentTrack else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }
        
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: track.title,
            MPMediaItemPropertyArtist: track.primaryArtist,
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0
        ]
        
        if let album = track.album {
            info[MPMediaItemPropertyAlbumTitle] = album
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
    
    // MARK: - Playback Control
    public func play(track: UniversalTrack, in playlist: [UniversalTrack] = []) {
        if let idx = playlist.firstIndex(of: track) {
            self.playlistQueue = playlist
            self.currentIndex = idx
        } else {
            self.playlistQueue = [track]
            self.currentIndex = 0
        }
        
        self.currentTrack = track
        self.duration = Double(track.durationMs) / 1000.0
        self.currentTime = 0.0
        self.progress = 0.0
        
        // High-fidelity royalty-free ambient music stream preview for live testing
        let previewStreamURL = URL(string: "https://commondatastorage.googleapis.com/codeskulptor-demos/riceracer_assets/music/race.ogg")
            ?? URL(fileURLWithPath: "/dev/null")
        
        let playerItem = AVPlayerItem(url: previewStreamURL)
        self.avPlayer = AVPlayer(playerItem: playerItem)
        self.avPlayer?.play()
        self.isPlaying = true
        
        startTimer()
        updateNowPlayingInfo()
        HapticManager.lightImpact()
    }
    
    public func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            resume()
        }
    }
    
    public func pause() {
        avPlayer?.pause()
        isPlaying = false
        stopTimer()
        updateNowPlayingInfo()
        HapticManager.lightImpact()
    }
    
    public func resume() {
        guard currentTrack != nil else { return }
        avPlayer?.play()
        isPlaying = true
        startTimer()
        updateNowPlayingInfo()
        HapticManager.lightImpact()
    }
    
    public func playNext() {
        guard !playlistQueue.isEmpty else { return }
        
        if loopMode == .single {
            seek(to: 0)
            resume()
            return
        }
        
        if isShuffled {
            currentIndex = Int.random(in: 0..<playlistQueue.count)
        } else {
            currentIndex = (currentIndex + 1) % playlistQueue.count
        }
        
        let nextTrack = playlistQueue[currentIndex]
        play(track: nextTrack, in: playlistQueue)
    }
    
    public func playPrevious() {
        guard !playlistQueue.isEmpty else { return }
        
        if currentTime > 3.0 {
            seek(to: 0)
            return
        }
        
        currentIndex = (currentIndex - 1 + playlistQueue.count) % playlistQueue.count
        let prevTrack = playlistQueue[currentIndex]
        play(track: prevTrack, in: playlistQueue)
    }
    
    public func seek(to time: Double) {
        currentTime = min(max(0, time), duration)
        progress = duration > 0 ? (currentTime / duration) : 0
        let targetTime = CMTime(seconds: currentTime, preferredTimescale: 600)
        avPlayer?.seek(to: targetTime)
        updateNowPlayingInfo()
    }
    
    public func seekPercentage(_ pct: Double) {
        let clamped = min(max(0.0, pct), 1.0)
        seek(to: clamped * duration)
    }
    
    // MARK: - Loop & Shuffle Modes
    public func toggleLoopMode() {
        HapticManager.lightImpact()
        switch loopMode {
        case .off:
            loopMode = .all
        case .all:
            loopMode = .single
        case .single:
            loopMode = .off
        }
    }
    
    public func toggleShuffle() {
        HapticManager.lightImpact()
        isShuffled.toggle()
    }
    
    // MARK: - Favorites
    public func isFavorite(track: UniversalTrack) -> Bool {
        favoriteTrackIds.contains(track.id)
    }
    
    public func toggleFavorite(track: UniversalTrack) {
        HapticManager.lightImpact()
        if favoriteTrackIds.contains(track.id) {
            favoriteTrackIds.remove(track.id)
        } else {
            favoriteTrackIds.insert(track.id)
        }
    }
    
    // MARK: - Timer for 60fps Smooth Progress & Waveform
    private func startTimer() {
        stopTimer()
        displayLinkTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, self.isPlaying else { return }
            
            self.currentTime += 0.1
            if self.duration > 0 {
                self.progress = min(1.0, self.currentTime / self.duration)
            }
            
            // Handle track completion
            if self.currentTime >= self.duration {
                switch self.loopMode {
                case .single:
                    self.seek(to: 0)
                case .all:
                    self.playNext()
                case .off:
                    if self.currentIndex < self.playlistQueue.count - 1 {
                        self.playNext()
                    } else {
                        self.pause()
                        self.seek(to: 0)
                    }
                }
            }
        }
    }
    
    private func stopTimer() {
        displayLinkTimer?.invalidate()
        displayLinkTimer = nil
    }
}
