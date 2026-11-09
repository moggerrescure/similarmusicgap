import SwiftUI
import Combine

/// Luxury Top-Down Album Vault Screen (Apple HIG HUD Standard)
/// Unfolds smoothly from the top of the phone screen when tapping any album crate in the feed.
/// Features:
/// 1. Top Navigation Bar with "← Назад" pill, centered "ALBUM VAULT" title, and "✕" close button
/// 2. Physical Gatefold Sleeve with protruding marbled vinyl disc that rotates when playing
/// 3. Play All and Shuffle actions
/// 4. Complete tracklist with 1-tap play and "Add to Queue"
public struct VaultAlbumTopDownView: View {
    public let album: SpotifyHomeFeedView.VaultAlbumItem
    public let onDismiss: () -> Void
    
    @ObservedObject private var player = AudioPlayerManager.shared
    @State private var toastMessage: String? = nil
    @State private var showToast: Bool = false
    
    public init(album: SpotifyHomeFeedView.VaultAlbumItem, onDismiss: @escaping () -> Void) {
        self.album = album
        self.onDismiss = onDismiss
    }
    
    private var isAlbumPlaying: Bool {
        guard let current = player.currentTrack else { return false }
        return player.isPlaying && (current.album == album.title || album.tracks.contains(where: { $0.id == current.id }))
    }
    
    public var body: some View {
        ZStack {
            // OLED Cashmere Charcoal Base
            PastelTheme.canvas.ignoresSafeArea()
            
            // Dynamic Ambient Gradient Wash Top
            AmbientWashBackgroundView(tab: .home)
            
            VStack(spacing: 0) {
                // Top-Down Navigation Bar
                topNavigationBar
                
                // Scrollable Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        // 1. Large Physical Sleeve + Rotating Marbled Disc
                        albumHeaderView
                            .padding(.top, 10)
                        
                        // 2. Play All & Shuffle Actions
                        actionButtonsView
                            .padding(.horizontal, 20)
                        
                        // 3. Tracklist Header
                        HStack {
                            Text("TRACKLIST")
                                .font(.system(size: 11, weight: .heavy))
                                .tracking(0.8)
                                .foregroundColor(Color(hex: "#9CA3AF"))
                            
                            Spacer()
                            
                            Text("\(album.tracks.count) TRACKS")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(PastelTheme.warmAmber)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 6)
                        
                        // 4. Tracklist Rows
                        tracklistSection
                            .padding(.horizontal, 16)
                            .padding(.bottom, 130) // Clearance for floating bottom mini-player
                    }
                }
            }
            
            // Floating HUD Toast
            if showToast, let msg = toastMessage {
                VStack {
                    Spacer()
                    queueToastView(message: msg)
                        .padding(.bottom, 96)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: showToast)
            }
        }
    }
    
    // MARK: - Top-Down Navigation Bar
    private var topNavigationBar: some View {
        HStack {
            // "← Назад" Frosted Pill Button
            Button {
                HapticManager.lightImpact()
                onDismiss()
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .bold))
                    Text("Назад")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(PastelTheme.pastelOat)
                .padding(.horizontal, 14)
                .frame(height: 32)
                .background(Color.white.opacity(0.08))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(PastelTheme.cardBorder, lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            // Center Pill
            Text("ALBUM VAULT")
                .font(.system(size: 11, weight: .heavy))
                .tracking(1.0)
                .foregroundColor(Color(hex: "#9CA3AF"))
            
            Spacer()
            
            // Close "✕" Button
            Button {
                HapticManager.lightImpact()
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(hex: "#9CA3AF"))
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(PastelTheme.cardBorder, lineWidth: 1)
                    )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .background(Color(hex: "#0E0F12").opacity(0.96))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.white.opacity(0.06)),
            alignment: .bottom
        )
    }
    
    // MARK: - Album Header View (Physical Sleeve + Protruding Disc)
    private var albumHeaderView: some View {
        HStack(spacing: 16) {
            // Sleeve + Rotating Vinyl Disc
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
                
                // Front Album Jacket
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
            
            // Metadata: Title, Artist, Genre, Duration
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
        .padding(.vertical, 14)
        .background(PastelTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(PastelTheme.cardBorder, lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }
    
    // MARK: - Action Buttons
    private var actionButtonsView: some View {
        HStack(spacing: 12) {
            // Play All Primary Capsule
            Button {
                HapticManager.successNotification()
                playAllTracks()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: isAlbumPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 13, weight: .bold))
                    Text(isAlbumPlaying ? "Pause Album" : "Play All")
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
            
            // Shuffle Button
            Button {
                HapticManager.lightImpact()
                shufflePlayTracks()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "shuffle")
                        .font(.system(size: 13, weight: .bold))
                    Text("Shuffle")
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
        }
    }
    
    // MARK: - Tracklist Section
    private var tracklistSection: some View {
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
    
    private func trackRow(
        index: Int,
        track: UniversalTrack,
        isCurrent: Bool,
        isPlaying: Bool
    ) -> some View {
        HStack(spacing: 12) {
            // Track Number / Animated EQ
            ZStack {
                if isPlaying {
                    WaveformBarsView(color: PastelTheme.athleticEmerald, isAnimating: true)
                        .frame(width: 18, height: 14)
                } else {
                    Text(String(format: "%02d", index))
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(isCurrent ? PastelTheme.athleticEmerald : Color(hex: "#6B7280"))
                }
            }
            .frame(width: 24)
            
            // Track Title & Artists
            VStack(alignment: .leading, spacing: 2) {
                Text(track.title)
                    .font(.system(size: 14, weight: isCurrent ? .bold : .semibold))
                    .foregroundColor(isCurrent ? PastelTheme.athleticEmerald : .white)
                    .lineLimit(1)
                
                Text(track.artists.joined(separator: ", "))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(hex: "#9CA3AF"))
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Duration
            Text(formatDuration(ms: track.durationMs))
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(Color(hex: "#6B7280"))
            
            // "Add to Queue" Quick Button
            Button {
                player.addToQueue(track: track)
                showQueueToastFeedback(trackTitle: track.title)
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(PastelTheme.pastelOat)
                    .frame(width: 28, height: 28)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Circle())
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(isCurrent ? Color(hex: "#1C1D25") : PastelTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(isCurrent ? PastelTheme.athleticEmerald.opacity(0.55) : PastelTheme.cardBorder, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            HapticManager.selectionChanged()
            player.play(track: track, in: album.tracks)
        }
    }
    
    // MARK: - Actions
    private func playAllTracks() {
        if isAlbumPlaying {
            player.pause()
        } else {
            if let first = album.tracks.first {
                player.play(track: first, in: album.tracks)
            }
        }
    }
    
    private func shufflePlayTracks() {
        guard let randomTrack = album.tracks.randomElement() else { return }
        player.play(track: randomTrack, in: album.tracks.shuffled())
    }
    
    private func showQueueToastFeedback(trackTitle: String) {
        HapticManager.lightImpact()
        toastMessage = "Added to queue: \(trackTitle)"
        withAnimation { showToast = true }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation { showToast = false }
        }
    }
    
    private func queueToastView(message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(PastelTheme.athleticEmerald)
                .font(.system(size: 14))
            
            Text(message)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(hex: "#1E2026").opacity(0.95))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(PastelTheme.athleticEmerald.opacity(0.4), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.6), radius: 12, y: 6)
    }
    
    private func formatDuration(ms: Int) -> String {
        let totalSeconds = ms / 1000
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

