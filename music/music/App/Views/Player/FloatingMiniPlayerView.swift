import SwiftUI

/// Floating HUD Mini-Player docking above bottom navigation with 3D fluid water-fill progress
public struct FloatingMiniPlayerView: View {
    @ObservedObject private var player = AudioPlayerManager.shared
    @State private var showingFullPlayer: Bool = false
    
    public init() {}
    
    public var body: some View {
        if let track = player.currentTrack {
            ZStack(alignment: .bottom) {
                // Background Card with 3D Liquid Wave fill
                ZStack {
                    PastelTheme.card
                    
                    // Liquid water-fill layer
                    LiquidWaveProgressView(
                        progress: player.progress,
                        color: PastelTheme.pastelOat.opacity(0.18),
                        secondaryColor: PastelTheme.emeraldSuccess.opacity(0.12)
                    )
                }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(PastelTheme.cardBorderFocused, lineWidth: 1)
                )
                
                // Content Row
                HStack(spacing: 12) {
                    // Artwork with pulsing glow
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(PastelTheme.cardSubtle)
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "music.note")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(PastelTheme.pastelOat)
                            .scaleEffect(player.isPlaying ? 1.08 : 1.0)
                            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: player.isPlaying)
                    }
                    
                    // Title & Artist
                    VStack(alignment: .leading, spacing: 2) {
                        Text(track.title)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(PastelTheme.textPrimary)
                            .lineLimit(1)
                        
                        Text(track.primaryArtist)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(PastelTheme.textSecondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Favorite Toggle
                    Button {
                        player.toggleFavorite(track: track)
                    } label: {
                        Image(systemName: player.isFavorite(track: track) ? "heart.fill" : "heart")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(player.isFavorite(track: track) ? PastelTheme.emeraldSuccess : PastelTheme.textTertiary)
                            .frame(width: 32, height: 32)
                    }
                    
                    // Play/Pause Button
                    Button {
                        player.togglePlayPause()
                    } label: {
                        Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(PastelTheme.textOnOat)
                            .frame(width: 34, height: 34)
                            .background(PastelTheme.pastelOat)
                            .clipShape(Circle())
                    }
                    .buttonStyle(TouchFeedbackButtonStyle())
                    
                    // Next Button
                    Button {
                        player.playNext()
                    } label: {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(PastelTheme.textPrimary)
                            .frame(width: 32, height: 32)
                    }
                }
                .padding(.horizontal, 14)
                .frame(height: 56)
                
                // Subtle 2pt bottom progress hairline
                GeometryReader { geo in
                    Rectangle()
                        .fill(PastelTheme.pastelOat)
                        .frame(width: geo.size.width * CGFloat(player.progress), height: 2)
                }
                .frame(height: 2)
            }
            .frame(height: 56)
            .padding(.horizontal, 12)
            .padding(.bottom, 54) // floats just above the bottom tab bar
            .contentShape(Rectangle())
            .onTapGesture {
                HapticManager.lightImpact()
                showingFullPlayer = true
            }
            .fullScreenOrSheet(isPresented: $showingFullPlayer) {
                FullPlayerSheet(track: track)
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}
