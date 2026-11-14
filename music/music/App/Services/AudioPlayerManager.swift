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
    
    /// True when current audio is a real preview_url (not a stand-in stream)
    @Published public private(set) var isPreviewPlayback: Bool = false
    /// False when the selected track has no playable preview URL
    @Published public private(set) var hasPlayablePreview: Bool = true
    
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
    private var endObserver: NSObjectProtocol?
    private var playlistQueue: [UniversalTrack] = []
    private var currentIndex: Int = 0
    
    private static let favoritesDefaultsKey = "soundshift_favorite_track_ids"
    
    private init() {
        loadPersistedFavorites()
        setupAudioSession()
        setupRemoteCommands()
    }
    
    private func loadPersistedFavorites() {
        let raw = UserDefaults.standard.stringArray(forKey: Self.favoritesDefaultsKey) ?? []
        favoriteTrackIds = Set(raw.compactMap(UUID.init(uuidString:)))
    }
    
    private func persistFavorites() {
        UserDefaults.standard.set(
            favoriteTrackIds.map(\.uuidString).sorted(),
            forKey: Self.favoritesDefaultsKey
        )
    }
    
    private static func playbackURL(for track: UniversalTrack) -> URL? {
        guard let preview = track.previewURL, let url = URL(string: preview) else {
            return nil
        }
        return url
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
        
        self.currentTrack = track
        // Preview streams are ~30s — don't use full track durationMs until AVPlayer reports real length.
        self.duration = min(30.0, max(1.0, Double(track.durationMs) / 1000.0))
        self.currentTime = 0.0
        self.progress = 0.0
        self.isCrossfading = false
        secondaryPlayer?.pause()
        self.secondaryPlayer = nil
        self.prebufferedTrack = nil
        clearEndObserver()
        
        // Honest playback: never substitute an unrelated stand-in stream for missing previews
        guard let streamURL = Self.playbackURL(for: track) else {
            primaryPlayer?.pause()
            primaryPlayer = nil
            isPlaying = false
            isPreviewPlayback = false
            hasPlayablePreview = false
            stopTimer()
            updateNowPlayingInfo()
            HapticManager.lightImpact()
            return
        }
        
        hasPlayablePreview = true
        isPreviewPlayback = true
        
        let previousPlayer = primaryPlayer
        let wasPlaying = isPlaying
        
        let playerItem = AVPlayerItem(url: streamURL)
        let newPlayer = AVPlayer(playerItem: playerItem)
        newPlayer.volume = wasPlaying ? 0.0 : 1.0
        newPlayer.play()
        
        self.primaryPlayer = newPlayer
        self.isPlaying = true
        observeItemEnd(playerItem)
        
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
        // No preview / no AVPlayer — never fake-play with a running timer
        guard primaryPlayer != nil, hasPlayablePreview else {
            isPlaying = false
            stopTimer()
            updateNowPlayingInfo()
            return
        }
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
    
    // MARK: - Queue Management
    public var currentQueue: [UniversalTrack] {
        playlistQueue
    }
    
    public func addToQueue(track: UniversalTrack) {
        playlistQueue.append(track)
        HapticManager.lightImpact()
    }
    
    public func addToQueueNext(track: UniversalTrack) {
        if currentIndex + 1 < playlistQueue.count {
            playlistQueue.insert(track, at: currentIndex + 1)
        } else {
            playlistQueue.append(track)
        }
        HapticManager.lightImpact()
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
    
    /// Local SoundShift bookmark only — never writes Liked Songs on Spotify / Apple / Yandex.
    public func toggleFavorite(track: UniversalTrack) {
        HapticManager.lightImpact()
        if favoriteTrackIds.contains(track.id) {
            favoriteTrackIds.remove(track.id)
        } else {
            favoriteTrackIds.insert(track.id)
        }
        persistFavorites()
    }
    
    // MARK: - 50ms High-Precision Crossfade & Gapless Automix Engine
    private func startTimer() {
        stopTimer()
        displayLinkTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, self.isPlaying else { return }
                
                // Drive UI from AVPlayer clock / item duration (preview ≈ 30s), not full track length.
                if let player = self.primaryPlayer, let item = player.currentItem {
                    let t = CMTimeGetSeconds(player.currentTime())
                    let d = CMTimeGetSeconds(item.duration)
                    if t.isFinite, t >= 0 {
                        self.currentTime = t
                    }
                    if d.isFinite, d > 0 {
                        self.duration = d
                    }
                } else {
                    self.currentTime += 0.05
                }
                
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
                if self.duration > 0, self.currentTime >= self.duration - 0.05 {
                    self.finalizeTrackTransition()
                }
            }
        }
    }
    
    private func observeItemEnd(_ item: AVPlayerItem) {
        clearEndObserver()
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.finalizeTrackTransition()
            }
        }
    }
    
    private func clearEndObserver() {
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
            self.endObserver = nil
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
        
        guard let preview = nextTrack.previewURL, let url = URL(string: preview) else {
            // No real preview for next track — skip fake stand-in crossfade
            return
        }
        let playerItem = AVPlayerItem(url: url)
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
            // Preview streams are ~30s — don't advertise full catalog duration after crossfade.
            if let itemDuration = primaryPlayer?.currentItem?.duration,
               itemDuration.isNumeric, itemDuration.seconds.isFinite, itemDuration.seconds > 0 {
                self.duration = itemDuration.seconds
            } else {
                self.duration = min(30.0, max(1.0, Double(nextTrack.durationMs) / 1000.0))
            }
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
