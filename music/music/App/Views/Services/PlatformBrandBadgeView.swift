import SwiftUI

/// Pixel-perfect vector brand badges for music streaming providers
public struct PlatformBrandBadgeView: View {
    let type: MusicProviderType
    var size: CGFloat = 46
    
    public init(type: MusicProviderType, size: CGFloat = 46) {
        self.type = type
        self.size = size
    }
    
    public var body: some View {
        ZStack {
            switch type {
            case .spotify:
                spotifyBadge
            case .appleMusic:
                appleMusicBadge
            case .yandexMusic:
                yandexMusicBadge
            }
        }
        .frame(width: size, height: size)
        .shadow(color: Color(hex: type.brandColorHex).opacity(0.35), radius: 8, x: 0, y: 3)
    }
    
    // MARK: - Spotify Official Vector Badge
    private var spotifyBadge: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "#1ED760"))
            
            // 3 Iconic Curved Sound Arcs
            Canvas { context, sz in
                let w = sz.width
                let h = sz.height
                let strokeColor = Color(hex: "#000000")
                
                // Top Arc
                var topArc = Path()
                topArc.addArc(
                    center: CGPoint(x: w * 0.44, y: h * 0.58),
                    radius: w * 0.31,
                    startAngle: .degrees(-65),
                    endAngle: .degrees(-15),
                    clockwise: false
                )
                context.stroke(topArc, with: .color(strokeColor), style: StrokeStyle(lineWidth: w * 0.09, lineCap: .round))
                
                // Middle Arc
                var midArc = Path()
                midArc.addArc(
                    center: CGPoint(x: w * 0.44, y: h * 0.60),
                    radius: w * 0.22,
                    startAngle: .degrees(-63),
                    endAngle: .degrees(-17),
                    clockwise: false
                )
                context.stroke(midArc, with: .color(strokeColor), style: StrokeStyle(lineWidth: w * 0.08, lineCap: .round))
                
                // Bottom Arc
                var botArc = Path()
                botArc.addArc(
                    center: CGPoint(x: w * 0.44, y: h * 0.62),
                    radius: w * 0.135,
                    startAngle: .degrees(-60),
                    endAngle: .degrees(-20),
                    clockwise: false
                )
                context.stroke(botArc, with: .color(strokeColor), style: StrokeStyle(lineWidth: w * 0.07, lineCap: .round))
            }
        }
    }
    
    // MARK: - Apple Music Official Vector Badge
    private var appleMusicBadge: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#FA233B"), Color(hex: "#FB5C74"), Color(hex: "#FF2D55")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Image(systemName: "music.note")
                .font(.system(size: size * 0.54, weight: .bold))
                .foregroundColor(.white)
        }
    }
    
    // MARK: - Yandex Music Official Vector Badge
    private var yandexMusicBadge: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#FFDD00"), Color(hex: "#FF9900")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Stylized Yandex sonic wave / flame burst
            Image(systemName: "waveform")
                .font(.system(size: size * 0.50, weight: .heavy))
                .foregroundColor(Color(hex: "#101012"))
        }
    }
}

