import SwiftUI

/// Floating HUD Mini-Player Island: Apple HUD Oval Capsule (Strict Dark Luxury)
public struct FloatingMiniPlayerView: View {
    @ObservedObject private var player = AudioPlayerManager.shared
    @ObservedObject private var coordinator = ServicesCoordinator.shared
    @State private var showingFullPlayer: Bool = false
    @State private var vinylRotation: Double = 0
    
    public init() {}
    
    private var activeTrack: UniversalTrack {
        player.currentTrack ?? UniversalTrack(
            isrc: "SP-DEMO-01",
            title: "Ruby Rosary",
            artists: ["A$AP Rocky", "J. Cole", "The Alchemist"],
            album: "Single",
            durationMs: 165000,
            spotifyId: "demo_ruby"
        )
    }
    
    public var body: some View {
        ZStack(alignment: .bottom) {
            // Container: Sleek Oval Capsule with glowing border, glass highlight & frosted charcoal base
            Capsule(style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#1E2026").opacity(0.95), Color(hex: "#121318").opacity(0.97)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    // Dual-layer stroke: active emerald halo or warm oat hairline border
                    Capsule(style: .continuous)
                        .stroke(
                            player.isPlaying ? PastelTheme.emeraldSuccess.opacity(0.75) : PastelTheme.cardBorderFocused,
                            lineWidth: 1.5
                        )
                )
                .overlay(
                    // Specular light streak along top glass rim
                    VStack {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.0),
                                        Color.white.opacity(0.45),
                                        Color.white.opacity(0.65),
                                        Color.white.opacity(0.45),
                                        Color.white.opacity(0.0)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 1)
                            .padding(.horizontal, 24)
                            .padding(.top, 1)
                        Spacer()
                    }
                )
                .shadow(
                    color: player.isPlaying ? PastelTheme.emeraldSuccess.opacity(0.35) : Color.black.opacity(0.90),
                    radius: 20,
                    x: 0,
                    y: 10
                )
            
            // Content Row inside Oval Capsule
            HStack(spacing: 12) {
                // Left: Recessed Turntable Bay with Micro Anisotropic Vinyl Disc
                ZStack {
                    // Recessed circular well
                    Circle()
                        .fill(Color(hex: "#090A0D"))
                        .frame(width: 46, height: 46)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                    
                    // Spinning vinyl disc with micro grooves
                    ZStack {
                        Circle()
                            .fill(
                                AngularGradient(
                                    gradient: Gradient(colors: [
                                        Color(hex: "#111317"),
                                        Color(hex: "#2C2F38"),
                                        Color(hex: "#111317"),
                                        Color(hex: "#1C1E24"),
                                        Color(hex: "#111317"),
                                        Color(hex: "#2C2F38"),
                                        Color(hex: "#111317"),
                                        Color(hex: "#1C1E24"),
                                        Color(hex: "#111317")
                                    ]),
                                    center: .center,
                                    startAngle: .degrees(45),
                                    endAngle: .degrees(405)
                                )
                            )
                            .frame(width: 42, height: 42)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.14), lineWidth: 0.8)
                            )
                        
                        // Concentric micro-groove
                        Circle()
                            .stroke(Color.white.opacity(0.08), style: StrokeStyle(lineWidth: 0.8, dash: [1.5, 2.5]))
                            .frame(width: 30, height: 30)
                        
                        // Center label with spindle dot
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [PastelTheme.pastelOat, Color(hex: "#D4C5B3")],
                                        center: .center,
                                        startRadius: 1,
                                        endRadius: 8
                                    )
                                )
                                .frame(width: 16, height: 16)
                                .overlay(
                                    Circle()
                                        .stroke(Color.black.opacity(0.3), lineWidth: 0.5)
                                )
                            
                            // Center spindle hole
                            Circle()
                                .fill(Color(hex: "#090A0D"))
                                .frame(width: 3.5, height: 3.5)
                        }
                    }
                    .rotationEffect(.degrees(player.isPlaying ? vinylRotation : 0))
                }
                .padding(.leading, 8)
                .onAppear {
                    withAnimation(.linear(duration: 3.6).repeatForever(autoreverses: false)) {
                        vinylRotation = 360
                    }
                }
                
                // Track Info in Single Horizontal Flow with Smooth Marquee Ticker
                MiniMarqueeTrackView(
                    title: activeTrack.title,
                    artists: activeTrack.artists.joined(separator: ", ")
                )
                .frame(maxWidth: .infinity)
                
                // Right Controls inside Oval
                HStack(spacing: 12) {
                    // Phosphor LED Equalizer Wave (4 bars, oscillating when playing)
                    if player.isPlaying {
                        MiniLiveWaveView()
                            .frame(width: 18, height: 16)
                    }
                    
                    // Favorite button
                    Button {
                        HapticManager.lightImpact()
                        player.toggleFavorite(track: activeTrack)
                    } label: {
                        Image(systemName: player.isFavorite(track: activeTrack) ? "heart.fill" : "heart")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(player.isFavorite(track: activeTrack) ? PastelTheme.emeraldSuccess : Color.white.opacity(0.8))
                            .frame(width: 26, height: 32)
                    }
                    .buttonStyle(PlayerCleanButtonStyle())
                    
                    // Tactile Oat Play/Pause Round Thumb Dish Button
                    Button {
                        HapticManager.lightImpact()
                        player.togglePlayPause()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [Color.white, PastelTheme.pastelOat, Color(hex: "#D4C5B3")],
                                        center: UnitPoint(x: 0.35, y: 0.3),
                                        startRadius: 2,
                                        endRadius: 18
                                    )
                                )
                                .frame(width: 36, height: 36)
                                .shadow(color: Color.black.opacity(0.6), radius: 4, x: 0, y: 2)
                            
                            Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 11.5, weight: .black))
                                .foregroundColor(PastelTheme.textOnOat)
                        }
                    }
                    .buttonStyle(PlayerCleanButtonStyle(scale: 0.90))
                }
                .padding(.trailing, 12)
            }
            .frame(height: 62)
            
            // Precision laser optical progress bar embedded along bottom edge inside the oval
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 2)
                    
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [PastelTheme.emeraldSuccess, Color(hex: "#34D399"), Color(hex: "#6EE7B7")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, (geo.size.width - 56) * CGFloat(player.progress)), height: 2)
                        .shadow(color: PastelTheme.emeraldSuccess.opacity(0.8), radius: 3, x: 0, y: 0)
                }
                .padding(.horizontal, 28)
            }
            .frame(height: 2)
            .padding(.bottom, 2.5)
        }
        .frame(height: 62)
        .contentShape(Capsule())
        .onTapGesture {
            HapticManager.lightImpact()
            showingFullPlayer = true
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 56) // Cleanly positioned inside screen at bottom above TabBar
        .sheet(isPresented: $showingFullPlayer) {
            FullPlayerSheet(track: activeTrack)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

/// Single-line Marquee ticker for [Title] • [Artists]
private struct MiniMarqueeTrackView: View {
    let title: String
    let artists: String
    @State private var offset: CGFloat = 0
    @State private var textWidth: CGFloat = 0
    @State private var containerWidth: CGFloat = 0
    
    var body: some View {
        GeometryReader { geo in
            let shouldAnimate = textWidth > geo.size.width && geo.size.width > 0
            HStack(spacing: 28) {
                trackLockup
                    .background(
                        GeometryReader { textGeo in
                            Color.clear.onAppear {
                                textWidth = textGeo.size.width
                                containerWidth = geo.size.width
                                if shouldAnimate {
                                    startMarquee()
                                }
                            }
                        }
                    )
                if shouldAnimate {
                    trackLockup
                }
            }
            .offset(x: offset)
            .onAppear {
                containerWidth = geo.size.width
                if shouldAnimate {
                    startMarquee()
                }
            }
            .onChange(of: title) {
                offset = 0
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if textWidth > containerWidth {
                        startMarquee()
                    }
                }
            }
        }
        .frame(height: 22)
        .clipped()
        .mask(
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .black, location: 0.05),
                    .init(color: .black, location: 0.93),
                    .init(color: .clear, location: 1.0)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }
    
    private var trackLockup: some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.system(size: 13.5, weight: .bold, design: .rounded))
                .foregroundColor(Color.white)
                .shadow(color: Color.white.opacity(0.4), radius: 6, x: 0, y: 0)
                .fixedSize()
            
            Text("•")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(PastelTheme.pastelOat.opacity(0.65))
            
            Text(artists)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(hex: "#D1D5DB"))
                .fixedSize()
        }
    }
    
    private func startMarquee() {
        offset = 0
        let speedDuration = max(6.0, Double(textWidth / 22))
        withAnimation(.linear(duration: speedDuration).repeatForever(autoreverses: false)) {
            offset = -(textWidth + 28)
        }
    }
}

/// Mini 4-bar phosphor animated audio equalizer for oval mini player
private struct MiniLiveWaveView: View {
    @State private var bar1Height: CGFloat = 3
    @State private var bar2Height: CGFloat = 11
    @State private var bar3Height: CGFloat = 6
    @State private var bar4Height: CGFloat = 14
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 2.2) {
            RoundedRectangle(cornerRadius: 1.2)
                .fill(LinearGradient(colors: [Color(hex: "#34D399"), PastelTheme.emeraldSuccess], startPoint: .top, endPoint: .bottom))
                .frame(width: 2.5, height: bar1Height)
            RoundedRectangle(cornerRadius: 1.2)
                .fill(LinearGradient(colors: [Color(hex: "#34D399"), PastelTheme.emeraldSuccess], startPoint: .top, endPoint: .bottom))
                .frame(width: 2.5, height: bar2Height)
            RoundedRectangle(cornerRadius: 1.2)
                .fill(LinearGradient(colors: [Color(hex: "#34D399"), PastelTheme.emeraldSuccess], startPoint: .top, endPoint: .bottom))
                .frame(width: 2.5, height: bar3Height)
            RoundedRectangle(cornerRadius: 1.2)
                .fill(LinearGradient(colors: [Color(hex: "#34D399"), PastelTheme.emeraldSuccess], startPoint: .top, endPoint: .bottom))
                .frame(width: 2.5, height: bar4Height)
        }
        .shadow(color: PastelTheme.emeraldSuccess.opacity(0.45), radius: 3)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.45).repeatForever(autoreverses: true)) {
                bar1Height = 14
            }
            withAnimation(.easeInOut(duration: 0.65).repeatForever(autoreverses: true).delay(0.1)) {
                bar2Height = 4
            }
            withAnimation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true).delay(0.2)) {
                bar3Height = 15
            }
            withAnimation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true).delay(0.15)) {
                bar4Height = 5
            }
        }
    }
}
