import SwiftUI
import Combine

/// Luxury Album Detail Sheet (Apple HIG HUD Standard)
/// Features:
/// 1. Large 3D Album Sleeve with Protruding Vinyl Disc that rotates when any track from the album is playing
/// 2. Complete tracklist with playback controls (1-tap play)
/// 3. "Add to Queue" (ставить в очередь) button and context menu with tactile haptics & HUD toast
/// 4. Play All and Shuffle controls
public struct VaultAlbumDetailSheet: View {
    public let album: SpotifyHomeFeedView.VaultAlbumItem
    
    @ObservedObject private var player = AudioPlayerManager.shared
    @ObservedObject private var coordinator = ServicesCoordinator.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var toastMessage: String? = nil
    @State private var showToast: Bool = false
    
    public init(album: SpotifyHomeFeedView.VaultAlbumItem) {
        self.album = album
    }
    
    /// True when album rows resolve to synced library ids (not designer fixtures).
    private var usesSyncedLibrary: Bool {
        album.tracks.contains { track in
            coordinator.allTracks.contains(where: { $0.id == track.id })
        }
    }
    
    private var isAlbumPlaying: Bool {
        guard let current = player.currentTrack else { return false }
        return player.isPlaying && (current.album == album.title || album.tracks.contains(where: { $0.id == current.id }))
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                // OLED Cashmere Charcoal Base
                PastelTheme.canvas.ignoresSafeArea()
                
                // Dynamic Ambient Gradient Wash Top
                AmbientWashBackgroundView(tab: .home)
                
                VStack(spacing: 0) {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            // 1. Album Header (Large Sleeve + Rotating Vinyl Disc)
                            albumHeaderView
                                .padding(.top, 14)
                            
                            // 2. Action Controls (Play All & Shuffle)
                            actionButtonsView
                                .padding(.horizontal, 20)
                            
                            if !usesSyncedLibrary {
                                HStack(alignment: .top, spacing: 10) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(PastelTheme.amberWarning)
                                    Text("Connect & Sync to play real previews — showcase titles won’t invent audio.")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(PastelTheme.textSecondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(PastelTheme.amberWarning.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .padding(.horizontal, 16)
                            }
                            
                            // 3. Tracklist Section
                            tracklistSection
                                .padding(.horizontal, 16)
                                .padding(.bottom, 40)
                        }
                    }
                }
                
                // 4. Floating "Added to Queue" HUD Toast
                if showToast, let msg = toastMessage {
                    VStack {
                        Spacer()
                        queueToastView(message: msg)
                            .padding(.bottom, 24)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: showToast)
                }
            }
            .inlineNavigationBarTitle()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        HapticManager.lightImpact()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color(hex: "#9CA3AF"))
                    }
                }
            }
        }
    }
    
    // MARK: - 1. Album Header View
    private var albumHeaderView: some View {
        HStack(spacing: 16) {
            // Sleeve + Rotating Vinyl Disc (Guaranteed clearance: disc ends at 132, text starts at 150)
            ZStack(alignment: .leading) {
                // Vinyl Disc - Protruding by 28pt inside 134pt box, NEVER overlapping text
                SheetSpinningVinylDiscView(
                    isPlaying: isAlbumPlaying,
                    waxGradient: album.waxGradient,
                    labelGradient: album.labelGradient,
                    labelTextColor: album.labelTextColor,
                    symbolOrInitial: album.symbolOrInitial,
                    glowColor: album.glowColor,
                    diameter: 104
                )
                .offset(x: 28)
                .shadow(color: Color.black.opacity(0.85), radius: 10, x: 6, y: 3)
                
                // Front Album Jacket (Covers left part of disc)
                ZStack(alignment: .bottomLeading) {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: album.gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 104, height: 104)
                    
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(PastelTheme.cardBorder, lineWidth: 1)
                        .frame(width: 104, height: 104)
                    
                    // Sleeve Mouth Shadow
                    HStack {
                        Spacer()
                        LinearGradient(
                            colors: [Color.black.opacity(0.85), Color.clear],
                            startPoint: .trailing,
                            endPoint: .leading
                        )
                        .frame(width: 14, height: 104)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .frame(width: 104, height: 104)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(album.title)
                            .font(.system(size: 11, weight: .black))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text(album.symbolOrInitial)
                            .font(.system(size: 9, weight: .heavy, design: .rounded))
                            .foregroundColor(PastelTheme.warmAmber)
                    }
                    .padding(8)
                }
                .frame(width: 104, height: 104)
                .shadow(color: Color.black.opacity(0.5), radius: 8, y: 4)
            }
            .frame(width: 134, height: 106)
            
            // Metadata: Title, Artist, Genre, Duration (Clear of Disc!)
            VStack(alignment: .leading, spacing: 4) {
                Text(album.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(album.artist)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(PastelTheme.warmAmber)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Text(album.releaseYear)
                    Text("•")
                    Text(album.genre)
                }
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(Color(hex: "#9CA3AF"))
                .lineLimit(1)
                
                Text("\(album.tracks.count) tracks • \(album.totalDuration)")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(Color(hex: "#9CA3AF"))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - 2. Action Buttons (Play All & Shuffle)
    private var actionButtonsView: some View {
        HStack(spacing: 12) {
            // Play All Primary Capsule
            Button {
                HapticManager.successNotification()
                playAllTracks()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: isAlbumPlaying ? "pause.fill" : (usesSyncedLibrary ? "play.fill" : "link"))
                        .font(.system(size: 13, weight: .bold))
                    Text(
                        isAlbumPlaying
                        ? "Pause Album"
                        : (usesSyncedLibrary ? "Play All" : "Connect to Play")
                    )
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundColor(PastelTheme.textOnOat)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(PastelTheme.pastelOat)
                .clipShape(Capsule())
                .shadow(color: PastelTheme.pastelOat.opacity(0.22), radius: 8, y: 3)
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel(usesSyncedLibrary ? "Play album" : "Connect to play album")
            
            // Shuffle Button
            Button {
                HapticManager.lightImpact()
                shufflePlayTracks()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: usesSyncedLibrary ? "shuffle" : "link")
                        .font(.system(size: 13, weight: .bold))
                    Text(usesSyncedLibrary ? "Shuffle" : "Connect")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .frame(height: 44)
                .background(PastelTheme.card)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(PastelTheme.cardBorder, lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel(usesSyncedLibrary ? "Shuffle album" : "Connect to shuffle")
        }
    }
    
    // MARK: - 3. Tracklist Section
    private var tracklistSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TRACKS")
                .font(.system(size: 11, weight: .heavy))
                .tracking(0.8)
                .foregroundColor(Color(hex: "#9CA3AF"))
                .padding(.leading, 4)
                .padding(.bottom, 2)
            
            VStack(spacing: 6) {
                ForEach(Array(album.tracks.enumerated()), id: \.element.id) { index, track in
                    let isCurrent = player.currentTrack?.id == track.id
                    let isPlayingThis = isCurrent && player.isPlaying
                    
                    trackRow(
                        index: index + 1,
                        track: track,
                        isCurrent: isCurrent,
                        isPlaying: isPlayingThis
                    )
                }
            }
        }
    }
    
    private func trackRow(
        index: Int,
        track: UniversalTrack,
        isCurrent: Bool,
        isPlaying: Bool
    ) -> some View {
        HStack(spacing: 12) {
            // Track Number / Equalizer
            ZStack {
                if isPlaying {
                    WaveformBarsView()
                        .frame(width: 18, height: 14)
                } else {
                    Text(String(format: "%02d", index))
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(isCurrent ? PastelTheme.emeraldSuccess : Color(hex: "#6B7280"))
                }
            }
            .frame(width: 24)
            
            // Track Info (Tapping Plays the Track)
            Button {
                HapticManager.lightImpact()
                if isCurrent {
                    player.togglePlayPause()
                } else {
                    playSyncedOrPrompt(track)
                }
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(track.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(isCurrent ? PastelTheme.warmAmber : .white)
                        .lineLimit(1)
                    
                    Text(track.artists.joined(separator: ", "))
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Color(hex: "#9CA3AF"))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Duration
            Text(formatDuration(ms: track.durationMs))
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(Color(hex: "#9CA3AF"))
            
            Button {
                guard usesSyncedLibrary else {
                    showQueueToastFeedback(trackTitle: "Connect & Sync to queue real tracks")
                    return
                }
                player.addToQueue(track: track)
                showQueueToastFeedback(trackTitle: track.title)
            } label: {
                Image(systemName: "text.badge.plus")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(usesSyncedLibrary ? PastelTheme.pastelOat : PastelTheme.textTertiary)
                    .padding(8)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Circle())
            }
            .buttonStyle(BorderlessButtonStyle())
            .disabled(!usesSyncedLibrary)
            .accessibilityLabel(usesSyncedLibrary ? "Add to queue" : "Connect to queue tracks")
            
            // Ellipsis Context Menu
            Menu {
                Button {
                    playSyncedOrPrompt(track)
                } label: {
                    Label(usesSyncedLibrary ? "Play Now" : "Connect to play", systemImage: "play.fill")
                }
                
                if usesSyncedLibrary {
                    Button {
                        player.addToQueueNext(track: track)
                        showQueueToastFeedback(trackTitle: track.title)
                    } label: {
                        Label("Play Next", systemImage: "text.insert")
                    }
                    
                    Button {
                        player.addToQueue(track: track)
                        showQueueToastFeedback(trackTitle: track.title)
                    } label: {
                        Label("Add to Queue", systemImage: "text.badge.plus")
                    }
                    
                    Button {
                        player.toggleFavorite(track: track)
                    } label: {
                        Label(
                            player.isFavorite(track: track)
                                ? "Remove \(MigratorChrome.localSavedAccessibility)"
                                : MigratorChrome.localSavedAccessibility,
                            systemImage: player.isFavorite(track: track) ? "heart.slash" : "heart"
                        )
                    }
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(hex: "#6B7280"))
                    .frame(width: 24, height: 32)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isCurrent ? Color(hex: "#1B1C23") : PastelTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(isCurrent ? PastelTheme.cardBorderFocused : PastelTheme.cardBorder, lineWidth: 0.8)
        )
    }
    
    // MARK: - 4. Queue Toast View
    private func queueToastView(message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(PastelTheme.emeraldSuccess)
                .font(.system(size: 14, weight: .bold))
            
            Text(message)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(hex: "#1B1C23"))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(PastelTheme.cardBorderFocused, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.6), radius: 10, y: 4)
    }
    
    // MARK: - Actions
    private func playSyncedOrPrompt(_ track: UniversalTrack) {
        guard usesSyncedLibrary else {
            dismiss()
            NavigationCoordinator.shared.navigateToConnect()
            return
        }
        let queue = album.tracks.compactMap { row in
            coordinator.allTracks.first(where: { $0.id == row.id })
        }
        let playable = coordinator.allTracks.first(where: { $0.id == track.id }) ?? track
        player.play(track: playable, in: queue.isEmpty ? [playable] : queue)
    }
    
    private func playAllTracks() {
        if isAlbumPlaying {
            player.togglePlayPause()
            return
        }
        guard usesSyncedLibrary, let first = album.tracks.first else {
            dismiss()
            NavigationCoordinator.shared.navigateToConnect()
            return
        }
        playSyncedOrPrompt(first)
    }
    
    private func shufflePlayTracks() {
        guard usesSyncedLibrary, let randomTrack = album.tracks.randomElement() else {
            dismiss()
            NavigationCoordinator.shared.navigateToConnect()
            return
        }
        playSyncedOrPrompt(randomTrack)
    }
    
    private func showQueueToastFeedback(trackTitle: String) {
        toastMessage = usesSyncedLibrary
            ? "Added to Queue • \(trackTitle)"
            : trackTitle
        showToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                showToast = false
            }
        }
    }
    
    private func formatDuration(ms: Int) -> String {
        let totalSec = ms / 1000
        let min = totalSec / 60
        let sec = totalSec % 60
        return String(format: "%d:%02d", min, sec)
    }
}

// MARK: - Sheet Spinning Vinyl Disc View
public struct SheetSpinningVinylDiscView: View {
    public let isPlaying: Bool
    public let waxGradient: [Color]
    public let labelGradient: [Color]
    public let labelTextColor: Color
    public let symbolOrInitial: String
    public let glowColor: Color
    public let diameter: CGFloat
    
    public init(
        isPlaying: Bool,
        waxGradient: [Color],
        labelGradient: [Color],
        labelTextColor: Color,
        symbolOrInitial: String,
        glowColor: Color,
        diameter: CGFloat
    ) {
        self.isPlaying = isPlaying
        self.waxGradient = waxGradient
        self.labelGradient = labelGradient
        self.labelTextColor = labelTextColor
        self.symbolOrInitial = symbolOrInitial
        self.glowColor = glowColor
        self.diameter = diameter
    }
    
    @StateObject private var motionTracker = SheetRotationTracker()
    
    public var body: some View {
        TimelineView(.animation(paused: !isPlaying)) { timeline in
            let playTime = motionTracker.advance(currentDate: timeline.date, isPlaying: isPlaying)
            let rotation = (playTime.truncatingRemainder(dividingBy: 3.5) / 3.5) * 360.0
            
            ZStack {
                // 1. Marbled Colored Wax Base
                Circle()
                    .fill(
                        AngularGradient(
                            colors: [
                                waxGradient.first ?? Color(hex: "#2E1A22"),
                                waxGradient.last ?? Color(hex: "#0E070A"),
                                waxGradient.first?.opacity(0.7) ?? Color(hex: "#2E1A22"),
                                waxGradient.first?.opacity(0.95) ?? Color(hex: "#450A0A"),
                                Color.white.opacity(0.18),
                                waxGradient.last?.opacity(0.85) ?? Color(hex: "#0E070A"),
                                waxGradient.first ?? Color(hex: "#2E1A22")
                            ],
                            center: .center
                        )
                    )
                    .frame(width: diameter, height: diameter)
                    .overlay(
                        Circle().stroke(Color.white.opacity(0.20), lineWidth: 1.0)
                    )
                    .shadow(color: glowColor.opacity(isPlaying ? 0.6 : 0.3), radius: isPlaying ? 12 : 6)
                
                // 2. Physical Concentric Micro-Grooves
                ForEach(0..<5) { i in
                    let inset = CGFloat(10 + (i * 9))
                    Circle()
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.75)
                        .frame(width: max(0, diameter - (inset * 2)), height: max(0, diameter - (inset * 2)))
                }
                
                // 3. Anisotropic Specular Light Sheen ("Виниловый крест света")
                AngularGradient(
                    colors: [
                        Color.clear,
                        Color.white.opacity(0.18),
                        Color.clear,
                        Color.white.opacity(0.18),
                        Color.clear
                    ],
                    center: .center
                )
                .frame(width: diameter, height: diameter)
                .clipShape(Circle())
                
                // Outer Rim
                Circle()
                    .stroke(Color.white.opacity(0.22), lineWidth: 1.2)
                    .frame(width: diameter, height: diameter)
                
                // 4. Deluxe Center Paper Label with Rotating Two-Tone Art & Micro-Typography
                let labelSize = diameter * 0.34
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: labelGradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: labelSize, height: labelSize)
                        .overlay(Circle().stroke(Color.black.opacity(0.6), lineWidth: 1.2))
                    
                    // Two-tone semi-circle arc for high-contrast visible rotation tracking
                    Circle()
                        .trim(from: 0.0, to: 0.5)
                        .fill(Color.black.opacity(0.25))
                        .frame(width: labelSize, height: labelSize)
                    
                    // Micro-Typography
                    VStack(spacing: 8) {
                        Text("SIDE A")
                            .font(.system(size: 5.0, weight: .black, design: .monospaced))
                            .foregroundColor(labelTextColor.opacity(0.85))
                        Text("33 ⅓")
                            .font(.system(size: 4.5, weight: .bold, design: .monospaced))
                            .foregroundColor(labelTextColor.opacity(0.75))
                    }
                    
                    // Center Artist Initial / SF Symbol
                    Text(symbolOrInitial)
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundColor(labelTextColor)
                    
                    // Spindle Hole
                    Circle()
                        .fill(Color(hex: "#090A0D"))
                        .frame(width: 7, height: 7)
                }
            }
            .rotationEffect(.degrees(rotation))
        }
    }
}

public final class SheetRotationTracker: ObservableObject {
    @Published public var tick: Bool = false
    public var accumulatedTime: Double = 0.0
    public var lastDate: Date? = nil
    
    public init() {}
    
    public func advance(currentDate: Date, isPlaying: Bool) -> Double {
        guard isPlaying else {
            lastDate = nil
            return accumulatedTime
        }
        
        if let last = lastDate {
            let delta = currentDate.timeIntervalSince(last)
            if delta > 0 && delta < 0.5 {
                accumulatedTime += delta
            }
        }
        lastDate = currentDate
        return accumulatedTime
    }
}
