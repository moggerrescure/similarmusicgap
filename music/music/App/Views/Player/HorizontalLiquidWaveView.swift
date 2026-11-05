import SwiftUI

/// Visual physics and aesthetic style for the left-to-right player flask fill
public enum FlaskFillingStyle: String, CaseIterable, Identifiable, Codable {
    case chronosStardust = "chronosStardust" // Default: Хроно-Песок (Stardust & Dunes)
    case mercuryOcean = "mercuryOcean"       // Меркури-Океан (Bioluminescent Water & Bubbles)
    case quantumPlasma = "quantumPlasma"     // Квант-Плазма (Magnetic Ferrofluid & Surges)
    case acousticPrism = "acousticPrism"     // Звук-Призма (Acoustic Spectrum Wave)
    
    public var id: String { rawValue }
    
    public var title: String {
        switch self {
        case .chronosStardust: return "Хроно-Песок"
        case .mercuryOcean: return "Меркури-Океан"
        case .quantumPlasma: return "Квант-Плазма"
        case .acousticPrism: return "Звук-Призма"
        }
    }
    
    public var subtitle: String {
        switch self {
        case .chronosStardust: return "Звёздная пыль, кристаллы и дюны (По умолчанию)"
        case .mercuryOcean: return "Био-вода, волны и всплывающие пузырьки"
        case .quantumPlasma: return "Магнитный феррофлюид и выбросы энергии"
        case .acousticPrism: return "Живой спектр частот и звуковая призма"
        }
    }
    
    public var icon: String {
        switch self {
        case .chronosStardust: return "sparkles"
        case .mercuryOcean: return "drop.fill"
        case .quantumPlasma: return "bolt.fill"
        case .acousticPrism: return "waveform.path"
        }
    }
    
    public var primaryColor: Color {
        switch self {
        case .chronosStardust: return PastelTheme.pastelOat
        case .mercuryOcean: return PastelTheme.emeraldSuccess
        case .quantumPlasma: return PastelTheme.warmAmber
        case .acousticPrism: return PastelTheme.pastelSlate
        }
    }
    
    public var accentGlowColor: Color {
        switch self {
        case .chronosStardust: return Color(hex: "#FFF8EC")
        case .mercuryOcean: return Color(hex: "#10B981")
        case .quantumPlasma: return Color(hex: "#FDE68A")
        case .acousticPrism: return Color(hex: "#34D399")
        }
    }
}

/// Horizontal liquid water-fill shape that fills from Left to Right
/// with organic fluid meniscus wave undulation at the leading edge.
public struct HorizontalLiquidWaveShape: Shape {
    public var progress: CGFloat // 0.0 to 1.0
    public var phase: CGFloat    // continuous angle in radians
    public var amplitude: CGFloat = 4.5 // wave crest depth
    
    public var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(progress, phase) }
        set {
            progress = newValue.first
            phase = newValue.second
        }
    }
    
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        let clampedProgress = max(0.0, min(1.0, progress))
        let targetX = width * clampedProgress
        
        if clampedProgress <= 0.001 {
            return path
        }
        
        path.move(to: CGPoint(x: 0, y: 0))
        
        if clampedProgress >= 0.999 {
            path.addLine(to: CGPoint(x: width, y: 0))
            path.addLine(to: CGPoint(x: width, y: height))
            path.addLine(to: CGPoint(x: 0, y: height))
            path.closeSubpath()
            return path
        }
        
        // Top edge up to wave front
        let topWaveX = targetX + sin(phase) * amplitude
        path.addLine(to: CGPoint(x: topWaveX, y: 0))
        
        // Fluid vertical meniscus curve from y = 0 down to y = height
        let steps = 24
        let stepHeight = height / CGFloat(steps)
        for i in 1...steps {
            let y = CGFloat(i) * stepHeight
            let normalizedY = y / height
            
            let wave1 = sin(normalizedY * .pi * 2.5 + phase) * amplitude
            let wave2 = cos(normalizedY * .pi * 5.0 + phase * 1.3) * (amplitude * 0.4)
            let currentX = targetX + wave1 + wave2
            
            path.addLine(to: CGPoint(x: currentX, y: y))
        }
        
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        return path
    }
}

/// Dynamic Left-to-Right Flask Fill View supporting all 4 visual styles
/// Defaults to Chronos Stardust across the entire application, and reacts dynamically to profile selection.
public struct HorizontalLiquidWaveProgressView: View {
    @ObservedObject private var coordinator = ServicesCoordinator.shared
    
    public var progress: Double // 0.0 to 1.0
    public var currentTime: Double = 0.0
    public var duration: Double = 0.0
    public var showSecondsHUD: Bool = true
    
    public var primaryColor: Color? = nil
    public var secondaryColor: Color? = nil
    public var styleOverride: FlaskFillingStyle? = nil
    
    @State private var phase: CGFloat = 0.0
    
    public init(
        progress: Double,
        currentTime: Double = 0.0,
        duration: Double = 0.0,
        showSecondsHUD: Bool = true,
        primaryColor: Color? = nil,
        secondaryColor: Color? = nil,
        styleOverride: FlaskFillingStyle? = nil
    ) {
        self.progress = progress
        self.currentTime = currentTime
        self.duration = duration
        self.showSecondsHUD = showSecondsHUD
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
        self.styleOverride = styleOverride
    }
    
    private var activeStyle: FlaskFillingStyle {
        styleOverride ?? coordinator.flaskFillingStyle
    }
    
    public var body: some View {
        GeometryReader { geo in
            let fillWidth = max(0, min(geo.size.width, geo.size.width * CGFloat(progress)))
            
            ZStack(alignment: .leading) {
                switch activeStyle {
                case .chronosStardust:
                    chronosStardustLayer(fillWidth: fillWidth, size: geo.size)
                case .mercuryOcean:
                    mercuryOceanLayer(fillWidth: fillWidth, size: geo.size)
                case .quantumPlasma:
                    quantumPlasmaLayer(fillWidth: fillWidth, size: geo.size)
                case .acousticPrism:
                    acousticPrismLayer(fillWidth: fillWidth, size: geo.size)
                }
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 2.2).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
        }
    }
    
    // MARK: - 1. CHRONOS STARDUST («Хроно-Песок» - DEFAULT)
    @ViewBuilder
    private func chronosStardustLayer(fillWidth: CGFloat, size: CGSize) -> some View {
        // Dune velvet wash
        HorizontalLiquidWaveShape(
            progress: CGFloat(progress),
            phase: phase,
            amplitude: 3.5
        )
        .fill(
            LinearGradient(
                colors: [
                    PastelTheme.pastelOat.opacity(0.10),
                    PastelTheme.pastelOat.opacity(0.24),
                    Color(hex: "#FFF8EC").opacity(0.44)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        
        // Internal twinkling stardust crystals inside filled space
        if fillWidth > 20 {
            HStack(spacing: 0) {
                ZStack {
                    // Star granule 1
                    Image(systemName: "sparkle")
                        .font(.system(size: 8))
                        .foregroundColor(Color.white.opacity(0.85))
                        .offset(x: fillWidth * 0.25 - fillWidth / 2, y: -size.height * 0.18 + sin(phase) * 2)
                    
                    // Star granule 2
                    Image(systemName: "sparkle")
                        .font(.system(size: 6))
                        .foregroundColor(PastelTheme.pastelOat.opacity(0.75))
                        .offset(x: fillWidth * 0.60 - fillWidth / 2, y: size.height * 0.20 + cos(phase) * 2)
                    
                    // Star granule 3
                    Circle()
                        .fill(Color.white.opacity(0.90))
                        .frame(width: 2.5, height: 2.5)
                        .offset(x: fillWidth * 0.82 - fillWidth / 2, y: -size.height * 0.05 + sin(phase * 1.5) * 1.5)
                }
                .frame(width: fillWidth, height: size.height)
                
                Spacer(minLength: 0)
            }
            .clipped()
        }
        
        // Leading luminous dune crest with glowing edge
        if progress > 0.01 && progress < 0.995 {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color(hex: "#FFF8EC").opacity(0.6),
                            Color.white,
                            Color(hex: "#FFF8EC").opacity(0.6),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 2.2, height: size.height)
                .offset(x: fillWidth - 1.0)
                .blur(radius: 0.6)
            
            // Breakaway flying stardust embers ahead of the dune
            Circle()
                .fill(Color.white.opacity(0.95))
                .frame(width: 2, height: 2)
                .offset(x: fillWidth + 6 + sin(phase * 2) * 4, y: size.height * 0.35 + cos(phase) * 3)
            
            Circle()
                .fill(PastelTheme.pastelOat.opacity(0.85))
                .frame(width: 1.5, height: 1.5)
                .offset(x: fillWidth + 12 + cos(phase * 2) * 3, y: size.height * 0.65 + sin(phase) * 4)
        }
    }
    
    // MARK: - 2. MERCURY OCEAN («Меркури-Океан»)
    @ViewBuilder
    private func mercuryOceanLayer(fillWidth: CGFloat, size: CGSize) -> some View {
        // Double-harmonic fluid body
        HorizontalLiquidWaveShape(
            progress: CGFloat(progress),
            phase: phase * 0.8 + .pi / 4,
            amplitude: 3.5
        )
        .fill(
            LinearGradient(
                colors: [
                    PastelTheme.emeraldSuccess.opacity(0.08),
                    PastelTheme.emeraldSuccess.opacity(0.20)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        
        HorizontalLiquidWaveShape(
            progress: CGFloat(progress),
            phase: phase,
            amplitude: 4.8
        )
        .fill(
            LinearGradient(
                colors: [
                    PastelTheme.emeraldSuccess.opacity(0.12),
                    PastelTheme.emeraldSuccess.opacity(0.28),
                    PastelTheme.emeraldSuccess.opacity(0.42)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        
        // Rising champagne bubbles inside water
        if fillWidth > 24 {
            HStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.70))
                        .frame(width: 3.5, height: 3.5)
                        .offset(x: fillWidth * 0.30 - fillWidth / 2, y: -sin(phase + 0.5) * (size.height * 0.35))
                    
                    Circle()
                        .fill(PastelTheme.emeraldSuccess.opacity(0.85))
                        .frame(width: 2.5, height: 2.5)
                        .offset(x: fillWidth * 0.65 - fillWidth / 2, y: -cos(phase + 1.2) * (size.height * 0.30))
                    
                    Circle()
                        .fill(Color.white.opacity(0.80))
                        .frame(width: 2.0, height: 2.0)
                        .offset(x: fillWidth * 0.85 - fillWidth / 2, y: -sin(phase + 2.0) * (size.height * 0.32))
                }
                .frame(width: fillWidth, height: size.height)
                
                Spacer(minLength: 0)
            }
            .clipped()
        }
        
        // Specular caustic leading edge
        if progress > 0.01 && progress < 0.995 {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            PastelTheme.emeraldSuccess.opacity(0.4),
                            Color.white.opacity(0.85),
                            PastelTheme.emeraldSuccess.opacity(0.4),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 2.2, height: size.height)
                .offset(x: fillWidth - 1.0)
                .blur(radius: 0.8)
        }
    }
    
    // MARK: - 3. QUANTUM PLASMA («Квант-Плазма»)
    @ViewBuilder
    private func quantumPlasmaLayer(fillWidth: CGFloat, size: CGSize) -> some View {
        HorizontalLiquidWaveShape(
            progress: CGFloat(progress),
            phase: phase * 1.5,
            amplitude: 5.5
        )
        .fill(
            LinearGradient(
                colors: [
                    PastelTheme.warmAmber.opacity(0.12),
                    PastelTheme.warmAmber.opacity(0.32),
                    Color(hex: "#FDE68A").opacity(0.50)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        
        // Intense plasma front
        if progress > 0.01 && progress < 0.995 {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            PastelTheme.warmAmber.opacity(0.8),
                            Color.white,
                            PastelTheme.warmAmber.opacity(0.8),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 2.5, height: size.height)
                .offset(x: fillWidth - 1.0)
                .blur(radius: 0.7)
            
            // Floating magnetic plasma droplet
            Circle()
                .fill(Color(hex: "#FDE68A"))
                .frame(width: 4, height: 4)
                .offset(x: fillWidth + 7 + sin(phase * 2) * 5, y: size.height * 0.45)
                .shadow(color: PastelTheme.warmAmber, radius: 4)
        }
    }
    
    // MARK: - 4. ACOUSTIC PRISM («Звук-Призма»)
    @ViewBuilder
    private func acousticPrismLayer(fillWidth: CGFloat, size: CGSize) -> some View {
        // Acoustic prism glass base
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        PastelTheme.pastelSlate.opacity(0.08),
                        PastelTheme.pastelSlate.opacity(0.20),
                        Color(hex: "#34D399").opacity(0.38)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: fillWidth, height: size.height)
        
        // Vertical spectral equalizer strings
        if fillWidth > 20 {
            HStack(spacing: 5) {
                ForEach(0..<Int(fillWidth / 7.0), id: \.self) { i in
                    let norm = CGFloat(i) * 0.35
                    let barH = (sin(norm + phase * 2.5) * 0.4 + 0.6) * (size.height * 0.65)
                    RoundedRectangle(cornerRadius: 1)
                        .fill(i % 3 == 0 ? Color(hex: "#34D399").opacity(0.8) : PastelTheme.pastelSlate.opacity(0.45))
                        .frame(width: 2, height: max(4, barH))
                }
                Spacer(minLength: 0)
            }
            .frame(width: fillWidth, height: size.height)
            .clipped()
        }
        
        // High-frequency leading audio crest
        if progress > 0.01 && progress < 0.995 {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color(hex: "#34D399"),
                            Color.white,
                            Color(hex: "#34D399"),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 2.0, height: size.height)
                .offset(x: fillWidth - 1.0)
                .shadow(color: Color(hex: "#34D399"), radius: 4)
        }
    }
}
