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

/// Core audio playback engine with Spotify-grade Dual-Deck Crossfade, Gapless Transitions,
/// Dynamic Island, Lock Screen, and background audio support
@MainActor
public final class AudioPlayerManager: ObservableObject {
    public static let shared = AudioPlayerManager()
    
    // Playback state
    @Published public private(set) var currentTrack: UniversalTrack?
    @Published public private(set) var isPlaying: Bool = false
    @Published public private(set) var currentTime: Double = 0.0
    @Published public private(set) var duration: Double = 210.0
    @Published public private(set) var progress: Double = 0.0 // 0.0 to 1.0
    
    // Spotify-Grade Crossfade
    @Published public var crossfadeDuration: Double = 3.5 // seconds of equal-power overlap
    @Published public private(set) var isCrossfading: Bool = false
    
    // Loop & Shuffle
    @Published public var loopMode: LoopMode = .off
    @Published public var isShuffled: Bool = false
    
    // Favorites registry
    @Published public private(set) var favoriteTrackIds: Set<UUID> = []
    
    // MARK: - Formatted Time Strings (Apple HUD Standard)
    public var formattedCurrentTime: String {
        formatSeconds(currentTime)
    }
    
    public var formattedDuration: String {
        formatSeconds(duration)
    }
    
    public var formattedRemainingTime: String {
        let rem = max(0, duration - currentTime)
        return "-" + formatSeconds(rem)
    }
    
    public var secondsHUDText: String {
        "\(formattedCurrentTime) / \(formattedDuration)"
    }
    
    private func formatSeconds(_ sec: Double) -> String {
        let total = max(0, Int(sec))
        let min = total / 60
        let s = total % 60
        return String(format: "%d:%02d", min, s)
    }
    
    // Dual-Deck Audio Players for Seamless Crossfading
    private var primaryPlayer: AVPlayer?
    private var secondaryPlayer: AVPlayer?
    private var prebufferedTrack: UniversalTrack?
    
    private var displayLinkTimer: Timer?
    private var playlistQueue: [UniversalTrack] = []
    private var currentIndex: Int = 0
    
    // Royalty-free preview stream for seamless testing
    private let defaultPreviewStreamURL = URL(string: "https://commondatastorage.googleapis.com/codeskulptor-demos/riceracer_assets/music/race.ogg")
        ?? URL(fileURLWithPath: "/dev/null")
    
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
            print("Failed to configure AVAudioSession: \(error)")
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
    
    // MARK: - Playback Control (with Smooth Micro-Crossfade on track switch)
    public func play(track: UniversalTrack, in playlist: [UniversalTrack] = []) {
        if let idx = playlist.firstIndex(of: track) {
            self.playlistQueue = playlist
            self.currentIndex = idx
        } else {
            self.playlistQueue = [track]
            self.currentIndex = 0
        }
        
        let previousPlayer = primaryPlayer
        let wasPlaying = isPlaying
        
        // Prepare new primary deck
        let playerItem = AVPlayerItem(url: defaultPreviewStreamURL)
        let newPlayer = AVPlayer(playerItem: playerItem)
        newPlayer.volume = wasPlaying ? 0.0 : 1.0
        newPlayer.play()
        
        self.primaryPlayer = newPlayer
        self.currentTrack = track
        self.duration = Double(track.durationMs) / 1000.0
        self.currentTime = 0.0
        self.progress = 0.0
        self.isPlaying = true
        self.isCrossfading = false
        self.secondaryPlayer = nil
        self.prebufferedTrack = nil
        
        // Equal-Power 350ms micro-fade if transitioning from another track
        if let oldPlayer = previousPlayer, wasPlaying {
            let steps = 7
            let interval = 0.35 / Double(steps)
            for i in 1...steps {
                let frac = Double(i) / Double(steps)
                DispatchQueue.main.asyncAfter(deadline: .now() + (Double(i) * interval)) { [weak self, weak oldPlayer, weak newPlayer] in
                    guard let _ = self else { return }
                    let outVol = Float(cos(Double.pi / 2.0 * frac))
                    let inVol = Float(sin(Double.pi / 2.0 * frac))
                    oldPlayer?.volume = outVol
                    newPlayer?.volume = inVol
                    if i == steps {
                        oldPlayer?.pause()
                    }
                }
            }
        }
        
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
        primaryPlayer?.pause()
        secondaryPlayer?.pause()
        isPlaying = false
        stopTimer()
        updateNowPlayingInfo()
        HapticManager.lightImpact()
    }
    
    public func resume() {
        guard currentTrack != nil else { return }
        primaryPlayer?.play()
        if isCrossfading {
            secondaryPlayer?.play()
        }
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
        primaryPlayer?.seek(to: targetTime)
        
        // Reset crossfade if user scrubbed back
        if currentTime < duration - crossfadeDuration {
            secondaryPlayer?.pause()
            secondaryPlayer = nil
            isCrossfading = false
            prebufferedTrack = nil
            primaryPlayer?.volume = 1.0
        }
        
        updateNowPlayingInfo()
    }
    
    public func seekPercentage(_ pct: Double) {
        let clamped = min(max(0.0, pct), 1.0)
        seek(to: clamped * duration)
    }
    
    public func skipForward(by seconds: Double = 15.0) {
        seek(to: currentTime + seconds)
        HapticManager.lightImpact()
    }
    
    public func skipBackward(by seconds: Double = 15.0) {
        seek(to: currentTime - seconds)
        HapticManager.lightImpact()
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
    
    // MARK: - 100ms High-Precision Crossfade & Gapless Automix Engine
    private func startTimer() {
        stopTimer()
        displayLinkTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, self.isPlaying else { return }
            
            self.currentTime += 0.1
            if self.duration > 0 {
                self.progress = min(1.0, self.currentTime / self.duration)
            }
            
            let timeLeft = self.duration - self.currentTime
            
            // 1. Pre-buffer next track at 6 seconds remaining
            if timeLeft <= 6.0 && self.secondaryPlayer == nil && !self.playlistQueue.isEmpty {
                self.prepareNextTrackDeck()
            }
            
            // 2. Initiate Equal-Power Crossfade when inside crossfadeDuration window
            if timeLeft <= self.crossfadeDuration && timeLeft > 0 {
                self.performCrossfadeTick(timeLeft: timeLeft)
            }
            
            // 3. Finalize transition when track reaches completion
            if self.currentTime >= self.duration {
                self.finalizeTrackTransition()
            }
        }
    }
    
    private func prepareNextTrackDeck() {
        let nextIndex: Int
        if loopMode == .single {
            nextIndex = currentIndex
        } else if isShuffled {
            nextIndex = Int.random(in: 0..<playlistQueue.count)
        } else {
            nextIndex = (currentIndex + 1) % playlistQueue.count
        }
        
        guard nextIndex < playlistQueue.count else { return }
        let nextTrack = playlistQueue[nextIndex]
        self.prebufferedTrack = nextTrack
        
        let playerItem = AVPlayerItem(url: defaultPreviewStreamURL)
        let deckB = AVPlayer(playerItem: playerItem)
        deckB.volume = 0.0
        self.secondaryPlayer = deckB
    }
    
    private func performCrossfadeTick(timeLeft: Double) {
        guard let deckB = secondaryPlayer else { return }
        
        if !isCrossfading {
            isCrossfading = true
            deckB.play()
        }
        
        let elapsedFade = crossfadeDuration - timeLeft
        let frac = min(1.0, max(0.0, elapsedFade / crossfadeDuration))
        
        // Equal-Power Law (sin / cos curve): maintains total acoustic energy
        let outVol = Float(cos(Double.pi / 2.0 * frac))
        let inVol = Float(sin(Double.pi / 2.0 * frac))
        
        primaryPlayer?.volume = outVol
        deckB.volume = inVol
    }
    
    private func finalizeTrackTransition() {
        if isCrossfading, let deckB = secondaryPlayer, let nextTrack = prebufferedTrack {
            // Seamless Deck Swap with ZERO pause or click
            primaryPlayer?.pause()
            deckB.volume = 1.0
            
            self.primaryPlayer = deckB
            self.secondaryPlayer = nil
            self.isCrossfading = false
            
            if let idx = playlistQueue.firstIndex(of: nextTrack) {
                self.currentIndex = idx
            }
            self.currentTrack = nextTrack
            self.duration = Double(nextTrack.durationMs) / 1000.0
            self.currentTime = 0.0
            self.progress = 0.0
            self.prebufferedTrack = nil
            
            updateNowPlayingInfo()
        } else {
            switch loopMode {
            case .single:
                seek(to: 0)
            case .all:
                playNext()
            case .off:
                if currentIndex < playlistQueue.count - 1 {
                    playNext()
                } else {
                    pause()
                    seek(to: 0)
                }
            }
        }
    }
    
    private func stopTimer() {
        displayLinkTimer?.invalidate()
        displayLinkTimer = nil
    }
}
