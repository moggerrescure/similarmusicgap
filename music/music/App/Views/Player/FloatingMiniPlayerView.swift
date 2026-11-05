import SwiftUI

/// Floating HUD Mini-Player docking above bottom navigation with Left-to-Right 3D fluid water-fill progress
public struct FloatingMiniPlayerView: View {
    @ObservedObject private var player = AudioPlayerManager.shared
    @State private var showingFullPlayer: Bool = false
    
    public init() {}
    
    public var body: some View {
        if let track = player.currentTrack {
            ZStack(alignment: .bottom) {
                // Background Card with Horizontal Left-to-Right Liquid Wave Fill
                ZStack(alignment: .leading) {
                    PastelTheme.card
                    
                    // Left-to-Right Fluid Water Fill Layer
                    HorizontalLiquidWaveProgressView(
                        progress: player.progress,
                        currentTime: player.currentTime,
                        duration: player.duration,
                        primaryColor: PastelTheme.pastelOat,
                        secondaryColor: PastelTheme.emeraldSuccess
                    )
                }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(PastelTheme.cardBorderFocused, lineWidth: 1)
                )
                
                // Content Row
                HStack(spacing: 12) {
                    // Artwork / Playback Pulse
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(PastelTheme.cardSubtle)
                            .frame(width: 40, height: 40)
                        
                        if player.isPlaying {
                            WaveformBarsView()
                                .frame(width: 24, height: 16)
                        } else {
                            Image(systemName: "music.note")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(PastelTheme.pastelOat)
                        }
                    }
                    
                    // Title, Artist, & Live Seconds HUD
                    VStack(alignment: .leading, spacing: 2) {
                        Text(track.title)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(PastelTheme.textPrimary)
                            .lineLimit(1)
                        
                        HStack(spacing: 5) {
                            Text(track.primaryArtist)
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(PastelTheme.textSecondary)
                                .lineLimit(1)
                            
                            Text("•")
                                .font(.system(size: 10))
                                .foregroundColor(PastelTheme.textTertiary)
                            
                            // High-legibility Seconds Counter (Left-to-Right Water Sync)
                            Text(player.secondsHUDText)
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(PastelTheme.emeraldSuccess)
                                .contentTransition(.numericText())
                        }
                    }
                    
                    Spacer()
                    
                    // Favorite Toggle Button (Independent Tap Zone)
                    Button {
                        HapticManager.lightImpact()
                        player.toggleFavorite(track: track)
                    } label: {
                        Image(systemName: player.isFavorite(track: track) ? "heart.fill" : "heart")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(player.isFavorite(track: track) ? PastelTheme.emeraldSuccess : PastelTheme.textTertiary)
                            .frame(width: 34, height: 34)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    
                    // Play/Pause Button
                    Button {
                        HapticManager.lightImpact()
                        player.togglePlayPause()
                    } label: {
                        Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(PastelTheme.textOnOat)
                            .frame(width: 34, height: 34)
                            .background(PastelTheme.pastelOat)
                            .clipShape(Circle())
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    
                    // Next Track Button
                    Button {
                        HapticManager.lightImpact()
                        player.playNext()
                    } label: {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(PastelTheme.textPrimary)
                            .frame(width: 32, height: 32)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
                .padding(.horizontal, 14)
                .frame(height: 58)
                
                // Luminous 2pt bottom progress indicator with specular glint
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(PastelTheme.cardBorder)
                            .frame(height: 2)
                        
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [PastelTheme.emeraldSuccess, PastelTheme.pastelOat],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(0, geo.size.width * CGFloat(player.progress)), height: 2)
                    }
                }
                .frame(height: 2)
            }
            .frame(height: 58)
            .padding(.horizontal, 12)
            .padding(.bottom, 54) // floats right above the bottom tab bar
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
