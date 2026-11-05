import SwiftUI

/// Full-Screen Luxury HUD Music Player with interactive 3D liquid wave scrubber
public struct FullPlayerSheet: View {
    public let track: UniversalTrack
    @ObservedObject private var player = AudioPlayerManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var isDraggingScrubber: Bool = false
    @State private var dragProgress: Double = 0.0
    
    public init(track: UniversalTrack) {
        self.track = track
    }
    
    public var body: some View {
        ZStack {
            PastelTheme.canvas
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Top Dismiss Grabber
                Capsule()
                    .fill(PastelTheme.cardBorder)
                    .frame(width: 36, height: 5)
                    .padding(.top, 12)
                
                Spacer()
                
                // MARK: - Album Artwork
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(PastelTheme.card)
                        .frame(width: 270, height: 270)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(PastelTheme.cardBorder, lineWidth: 1)
                        )
                    
                    Image(systemName: "music.note")
                        .font(.system(size: 80, weight: .light))
                        .foregroundColor(PastelTheme.pastelOat.opacity(0.8))
                }
                .shadow(color: Color.black.opacity(0.4), radius: 24, y: 12)
                
                Spacer()
                
                // MARK: - Title & Artist & Favorite
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(track.title)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(PastelTheme.textPrimary)
                            .lineLimit(1)
                        
                        Text(track.primaryArtist)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(PastelTheme.textSecondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Favorite Toggle
                    Button {
                        player.toggleFavorite(track: track)
                    } label: {
                        Image(systemName: player.isFavorite(track: track) ? "heart.fill" : "heart")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(player.isFavorite(track: track) ? PastelTheme.emeraldSuccess : PastelTheme.textTertiary)
                            .frame(width: 44, height: 44)
                    }
                }
                .padding(.horizontal, 28)
                
                // MARK: - 3D Liquid Wave Scrubber
                VStack(spacing: 8) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            // Track background
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(PastelTheme.card)
                            
                            // 3D Liquid Wave Fill
                            LiquidWaveProgressView(
                                progress: isDraggingScrubber ? dragProgress : player.progress,
                                color: PastelTheme.pastelOat,
                                secondaryColor: PastelTheme.emeraldSuccess.opacity(0.8)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(PastelTheme.cardBorderFocused, lineWidth: 1)
                        )
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    isDraggingScrubber = true
                                    let pct = min(max(0.0, value.location.x / geo.size.width), 1.0)
                                    dragProgress = pct
                                }
                                .onEnded { value in
                                    let pct = min(max(0.0, value.location.x / geo.size.width), 1.0)
                                    player.seekPercentage(pct)
                                    isDraggingScrubber = false
                                }
                        )
                    }
                    .frame(height: 32)
                    
                    // Time Labels
                    HStack {
                        Text(formatTime(isDraggingScrubber ? dragProgress * player.duration : player.currentTime))
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundColor(PastelTheme.textTertiary)
                        
                        Spacer()
                        
                        Text(formatTime(player.duration))
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundColor(PastelTheme.textTertiary)
                    }
                }
                .padding(.horizontal, 28)
                
                // MARK: - Playback Controls
                HStack(spacing: 28) {
                    // Shuffle
                    Button {
                        player.toggleShuffle()
                    } label: {
                        Image(systemName: "shuffle")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(player.isShuffled ? PastelTheme.pastelOat : PastelTheme.textTertiary)
                            .frame(width: 36, height: 36)
                    }
                    
                    // Previous
                    Button {
                        player.playPrevious()
                    } label: {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(PastelTheme.textPrimary)
                    }
                    
                    // Big Play/Pause CTA
                    Button {
                        player.togglePlayPause()
                    } label: {
                        Circle()
                            .fill(PastelTheme.pastelOat)
                            .frame(width: 68, height: 68)
                            .overlay(
                                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                                    .font(.system(size: 26, weight: .bold))
                                    .foregroundColor(PastelTheme.textOnOat)
                            )
                    }
                    .buttonStyle(TouchFeedbackButtonStyle())
                    
                    // Next
                    Button {
                        player.playNext()
                    } label: {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(PastelTheme.textPrimary)
                    }
                    
                    // Loop Mode
                    Button {
                        player.toggleLoopMode()
                    } label: {
                        Image(systemName: player.loopMode.iconName)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(player.loopMode != .off ? PastelTheme.pastelOat : PastelTheme.textTertiary)
                            .frame(width: 36, height: 36)
                    }
                }
                .padding(.top, 8)
                
                Spacer()
                
                // Service deep link chip
                HStack(spacing: 8) {
                    if let yandexId = track.yandexId {
                        Button { DeepLinkManager.openTrack(track: track, in: .yandexMusic) } label: {
                            Label("Yandex", systemImage: "arrow.up.right")
                        }
                    }
                    if let spotifyId = track.spotifyId {
                        Button { DeepLinkManager.openTrack(track: track, in: .spotify) } label: {
                            Label("Spotify", systemImage: "arrow.up.right")
                        }
                    }
                    if let appleId = track.appleMusicId {
                        Button { DeepLinkManager.openTrack(track: track, in: .appleMusic) } label: {
                            Label("Apple Music", systemImage: "arrow.up.right")
                        }
                    }
                }
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(PastelTheme.textSecondary)
                .padding(.bottom, 20)
            }
        }
    }
    
    private func formatTime(_ seconds: Double) -> String {
        let totalSeconds = Int(max(0, seconds))
        let mins = totalSeconds / 60
        let secs = totalSeconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
