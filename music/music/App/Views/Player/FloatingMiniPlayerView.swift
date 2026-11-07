import SwiftUI

/// Floating HUD Mini-Player replicating Spotify Mobile Production UI
public struct FloatingMiniPlayerView: View {
    @ObservedObject private var player = AudioPlayerManager.shared
    @ObservedObject private var coordinator = ServicesCoordinator.shared
    @State private var showingFullPlayer: Bool = false
    
    public init() {}
    
    private var activeTrack: UniversalTrack {
        player.currentTrack ?? UniversalTrack(
            isrc: "SP-DEMO-01",
            title: "будка",
            artists: ["CUPSIZE"],
            album: "Single",
            durationMs: 165000,
            spotifyId: "demo_budka"
        )
    }
    
    public var body: some View {
        ZStack(alignment: .bottom) {
            // Container: 56px height, background #282828, border-radius 8px
            Color(hex: "#282828")
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            
            // Content Row
            HStack(spacing: 10) {
                // Left Thumbnail: 40px x 40px rounded square (4px radius)
                ZStack {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color(hex: "#1E1E1E"))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "music.note")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "#B3B3B3"))
                }
                .padding(.leading, 8)
                
                // Track Info (Title: white #FFFFFF, 14px bold; Artist: muted gray #B3B3B3, 12px)
                VStack(alignment: .leading, spacing: 2) {
                    Text(activeTrack.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.white)
                        .lineLimit(1)
                        .contentTransition(.opacity)
                    
                    Text(activeTrack.primaryArtist)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Color(hex: "#B3B3B3"))
                        .lineLimit(1)
                        .contentTransition(.opacity)
                }
                .animation(.smooth(duration: 0.35), value: activeTrack.id)
                
                Spacer()
                
                // Right Controls (3 icons with 16px gap)
                HStack(spacing: 16) {
                    // 1. Connect Device / Speaker icon
                    Button {
                        HapticManager.lightImpact()
                    } label: {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color.white)
                            .frame(width: 28, height: 32)
                    }
                    .buttonStyle(PlayerCleanButtonStyle())
                    
                    // 2. Plus inside circle icon (⊕ / favorite / add to playlist)
                    Button {
                        HapticManager.lightImpact()
                        player.toggleFavorite(track: activeTrack)
                    } label: {
                        Image(systemName: player.isFavorite(track: activeTrack) ? "checkmark.circle.fill" : "plus.circle")
                            .font(.system(size: 19, weight: .semibold))
                            .foregroundColor(player.isFavorite(track: activeTrack) ? Color(hex: "#1ED760") : Color.white)
                            .frame(width: 28, height: 32)
                    }
                    .buttonStyle(PlayerCleanButtonStyle())
                    
                    // 3. Solid white Play / Pause triangle icon
                    Button {
                        HapticManager.lightImpact()
                        player.togglePlayPause()
                    } label: {
                        Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 19, weight: .bold))
                            .foregroundColor(Color.white)
                            .frame(width: 28, height: 32)
                    }
                    .buttonStyle(PlayerCleanButtonStyle(scale: 0.90))
                }
                .padding(.trailing, 12)
            }
            .frame(height: 56)
            
            // Thin 2px progress bar along bottom edge: #4D4D4D track, #FFFFFF fill
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(hex: "#4D4D4D"))
                        .frame(height: 2)
                    
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: max(0, geo.size.width * CGFloat(player.progress)), height: 2)
                }
            }
            .frame(height: 2)
        }
        .frame(height: 56)
        .padding(.horizontal, 8) // margin: 0 8px
        .padding(.bottom, 66)    // positioned right above 64px bottom nav bar
        .contentShape(Rectangle())
        .onTapGesture {
            HapticManager.lightImpact()
            showingFullPlayer = true
        }
        .sheet(isPresented: $showingFullPlayer) {
            FullPlayerSheet(track: activeTrack)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}
