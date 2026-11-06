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
        case .quantumPlasma: return PastelTheme.amberWarning
        case .acousticPrism: return PastelTheme.slateBlue
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

/// Internal animated stardust/bubble particle model for dynamic volumetric drift
private struct FlaskInternalParticle: Identifiable {
    let id: Int
    let relX: CGFloat      // 0.0 ... 1.0 (relative phase in drift)
    let relY: CGFloat      // 0.15 ... 0.85 (vertical lane)
    let speed: CGFloat     // horizontal drift speed multiplier
    let size: CGFloat      // particle point size
    let isDiamond: Bool    // 4-point diamond star vs luminous circular mote
    let baseOpacity: Double
}

/// Dynamic Left-to-Right Flask Fill View supporting all 4 visual styles with live moving particles & iridescent shimmer
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
    
    // Seeded internal stardust particles that continuously drift and twinkle inside the flask
    private static let seededParticles: [FlaskInternalParticle] = [
        FlaskInternalParticle(id: 0, relX: 0.10, relY: 0.28, speed: 0.35, size: 7.0, isDiamond: true, baseOpacity: 0.95),
        FlaskInternalParticle(id: 1, relX: 0.25, relY: 0.72, speed: 0.50, size: 3.5, isDiamond: false, baseOpacity: 0.85),
        FlaskInternalParticle(id: 2, relX: 0.40, relY: 0.35, speed: 0.42, size: 8.0, isDiamond: true, baseOpacity: 0.98),
        FlaskInternalParticle(id: 3, relX: 0.55, relY: 0.78, speed: 0.62, size: 3.0, isDiamond: false, baseOpacity: 0.75),
        FlaskInternalParticle(id: 4, relX: 0.68, relY: 0.22, speed: 0.46, size: 6.5, isDiamond: true, baseOpacity: 0.90),
        FlaskInternalParticle(id: 5, relX: 0.82, relY: 0.62, speed: 0.54, size: 3.8, isDiamond: false, baseOpacity: 0.85),
        FlaskInternalParticle(id: 6, relX: 0.32, relY: 0.52, speed: 0.30, size: 2.8, isDiamond: false, baseOpacity: 0.70),
        FlaskInternalParticle(id: 7, relX: 0.62, relY: 0.44, speed: 0.48, size: 7.5, isDiamond: true, baseOpacity: 0.92),
        FlaskInternalParticle(id: 8, relX: 0.90, relY: 0.30, speed: 0.68, size: 2.5, isDiamond: false, baseOpacity: 0.80),
        FlaskInternalParticle(id: 9, relX: 0.18, relY: 0.82, speed: 0.38, size: 3.2, isDiamond: false, baseOpacity: 0.78)
    ]
    
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
    
    private func sineOscillation(_ multiplier: CGFloat = 1.0, amplitude: Double = 0.05) -> Double {
        Double(sin(phase * multiplier)) * amplitude
    }
    
    private func cosineOscillation(_ multiplier: CGFloat = 1.0, amplitude: Double = 0.06) -> Double {
        Double(cos(phase * multiplier)) * amplitude
    }
    
    public var body: some View {
        GeometryReader { geo in
            let fillWidth = max(0, min(geo.size.width, geo.size.width * CGFloat(progress)))
            
            ZStack(alignment: .leading) {
                // 1. Specific Filling Style Layer
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
                
                // 2. Crystal Flask Tube Specular Reflection (Красивый стеклянный перелив колбы)
                glassTubeSpecularSheen(fillWidth: fillWidth, size: geo.size)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 2.6).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
        }
    }
    
    // MARK: - Crystal Flask Glass Specular Sheen (Зеркальный перелив трубки)
    @ViewBuilder
    private func glassTubeSpecularSheen(fillWidth: CGFloat, size: CGSize) -> some View {
        // Upper glass tube cylindrical highlight
        VStack(spacing: 0) {
            LinearGradient(
                colors: [
                    Color.white.opacity(0.16),
                    Color.white.opacity(0.04),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: size.height * 0.42)
            
            Spacer(minLength: 0)
            
            // Bottom rim glass reflection
            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(height: 1.5)
        }
        .allowsHitTesting(false)
        
        // Moving diagonal iridescent light glint across the flask
        let sweepOffset = (sin(phase * 0.6) * 0.5 + 0.5) * size.width
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.clear,
                        Color.white.opacity(0.0),
                        Color.white.opacity(0.12),
                        Color(hex: "#FFF8EC").opacity(0.20),
                        Color.white.opacity(0.12),
                        Color.white.opacity(0.0),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 48, height: size.height * 1.2)
            .rotationEffect(.degrees(20))
            .offset(x: sweepOffset - 24, y: -size.height * 0.1)
            .allowsHitTesting(false)
            .clipped()
    }
    
    // MARK: - 1. CHRONOS STARDUST («Хроно-Песок» - DEFAULT)
    @ViewBuilder
    private func chronosStardustLayer(fillWidth: CGFloat, size: CGSize) -> some View {
        // A. Multi-stop Shimmering Dune Velvet Wash
        HorizontalLiquidWaveShape(
            progress: CGFloat(progress),
            phase: phase,
            amplitude: 3.8
        )
        .fill(
            LinearGradient(
                colors: [
                    PastelTheme.pastelOat.opacity(0.12),
                    PastelTheme.pastelOat.opacity(0.26 + sineOscillation(0.8, amplitude: 0.05)),
                    Color(hex: "#FDE68A").opacity(0.28 + cosineOscillation(0.8, amplitude: 0.06)),
                    Color(hex: "#FFF8EC").opacity(0.50 + sineOscillation(1.2, amplitude: 0.08))
                ],
                startPoint: UnitPoint(x: CGFloat(sin(phase * 0.5) * 0.15), y: 0),
                endPoint: UnitPoint(x: 1.0 + CGFloat(cos(phase * 0.5) * 0.15), y: 1)
            )
        )
        
        // B. Dynamic Moving Stardust Particles inside the filled volume
        if fillWidth > 18 {
            ZStack(alignment: .leading) {
                ForEach(Self.seededParticles) { p in
                    // Horizontal continuous cyclic drift within the filled water/sand volume
                    let driftProgress = CGFloat((Double(p.relX) + (Double(phase) / (Double.pi * 2.0)) * Double(p.speed)).truncatingRemainder(dividingBy: 1.0))
                    let normalizedX = driftProgress >= 0 ? driftProgress : driftProgress + 1.0
                    let particleX = fillWidth * normalizedX
                    
                    // Vertical organic current oscillation
                    let verticalSway = sin(phase * 1.6 + CGFloat(p.id)) * (size.height * 0.14)
                    let particleY = size.height * p.relY + verticalSway
                    
                    // Twinkling shimmer brightness
                    let twinkle = 0.60 + 0.40 * Double(sin(phase * 2.5 + CGFloat(p.id) * 1.2))
                    let opacity = p.baseOpacity * twinkle
                    
                    Group {
                        if p.isDiamond {
                            // 4-point diamond star crystal drifting
                            Image(systemName: "sparkle")
                                .font(.system(size: p.size))
                                .foregroundColor(Color(hex: "#FFF8EC").opacity(opacity))
                                .rotationEffect(.degrees(Double(phase * 40.0) + Double(p.id * 30)))
                        } else {
                            // Glowing circular celestial mote with soft halo
                            ZStack {
                                Circle()
                                    .fill(PastelTheme.pastelOat.opacity(opacity * 0.35))
                                    .frame(width: p.size * 2.0, height: p.size * 2.0)
                                Circle()
                                    .fill(Color.white.opacity(opacity))
                                    .frame(width: p.size, height: p.size)
                            }
                        }
                    }
                    .position(x: particleX, y: particleY)
                }
            }
            .frame(width: fillWidth, height: size.height)
            .clipped()
        }
        
        // C. Shimmering Leading Dune Crest with Iridescent Specular Glint
        if progress > 0.01 && progress < 0.995 {
            // Radiant edge line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color(hex: "#FFF8EC").opacity(0.6),
                            Color.white,
                            Color(hex: "#FDE68A").opacity(0.8),
                            Color(hex: "#FFF8EC").opacity(0.6),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 2.5, height: size.height)
                .offset(x: fillWidth - 1.2)
                .blur(radius: 0.5)
            
            // Breakaway flying stardust embers that dance into the open space ahead
            Circle()
                .fill(Color.white.opacity(0.95))
                .frame(width: 2.5, height: 2.5)
                .offset(x: fillWidth + 6 + sin(phase * 2.0) * 5, y: size.height * 0.30 + cos(phase * 1.5) * 4)
                .shadow(color: Color(hex: "#FFF8EC"), radius: 3)
            
            Circle()
                .fill(Color(hex: "#FDE68A").opacity(0.90))
                .frame(width: 2.0, height: 2.0)
                .offset(x: fillWidth + 14 + cos(phase * 2.2) * 4, y: size.height * 0.70 + sin(phase * 1.8) * 5)
                .shadow(color: PastelTheme.warmAmber, radius: 2)
        }
    }
    
    // MARK: - 2. MERCURY OCEAN («Меркури-Океан»)
    @ViewBuilder
    private func mercuryOceanLayer(fillWidth: CGFloat, size: CGSize) -> some View {
        // A. Double-harmonic fluid body with emerald iridescence
        HorizontalLiquidWaveShape(
            progress: CGFloat(progress),
            phase: phase * 0.8 + .pi / 4,
            amplitude: 3.5
        )
        .fill(
            LinearGradient(
                colors: [
                    PastelTheme.emeraldSuccess.opacity(0.08),
                    PastelTheme.emeraldSuccess.opacity(0.22)
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
                    PastelTheme.emeraldSuccess.opacity(0.28 + sineOscillation(1.0, amplitude: 0.05)),
                    Color(hex: "#34D399").opacity(0.45)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        
        // B. Continuously Rising & Drifting Champagne Micro-Bubbles
        if fillWidth > 20 {
            ZStack(alignment: .leading) {
                ForEach(Self.seededParticles.prefix(8)) { b in
                    // Bubbles drift horizontally with current while rising vertically
                    let driftProgress = CGFloat((Double(b.relX) + (Double(phase) / (Double.pi * 2.0)) * 0.3).truncatingRemainder(dividingBy: 1.0))
                    let bubbleX = fillWidth * (driftProgress >= 0 ? driftProgress : driftProgress + 1.0)
                    
                    // Vertical continuous rising cycle
                    let riseCycle = (CGFloat(b.relY) - (phase * 0.15 * b.speed)).truncatingRemainder(dividingBy: 1.0)
                    let bubbleY = size.height * (riseCycle >= 0 ? riseCycle : riseCycle + 1.0)
                    
                    // Wobble
                    let wobbleX = sin(phase * 2.0 + CGFloat(b.id)) * 2.5
                    
                    Circle()
                        .fill(b.id % 2 == 0 ? Color.white.opacity(0.85) : PastelTheme.emeraldSuccess.opacity(0.90))
                        .frame(width: b.size * 0.6, height: b.size * 0.6)
                        .position(x: bubbleX + wobbleX, y: bubbleY)
                }
            }
            .frame(width: fillWidth, height: size.height)
            .clipped()
        }
        
        // C. Specular caustic leading edge
        if progress > 0.01 && progress < 0.995 {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            PastelTheme.emeraldSuccess.opacity(0.5),
                            Color.white,
                            PastelTheme.emeraldSuccess.opacity(0.5),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 2.2, height: size.height)
                .offset(x: fillWidth - 1.0)
                .blur(radius: 0.6)
                .shadow(color: PastelTheme.emeraldSuccess, radius: 6)
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
                    PastelTheme.amberWarning.opacity(0.12),
                    PastelTheme.amberWarning.opacity(0.32 + sineOscillation(1.5, amplitude: 0.08)),
                    Color(hex: "#FDE68A").opacity(0.55 + cosineOscillation(1.5, amplitude: 0.08))
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        
        // Drifting plasma energy sparks inside
        if fillWidth > 20 {
            ZStack(alignment: .leading) {
                ForEach(Self.seededParticles.prefix(6)) { s in
                    let driftProgress = CGFloat((Double(s.relX) + (Double(phase) / (Double.pi * 2.0)) * 0.45).truncatingRemainder(dividingBy: 1.0))
                    let sparkX = fillWidth * (driftProgress >= 0 ? driftProgress : driftProgress + 1.0)
                    let sparkY = size.height * s.relY + sin(phase * 2.5 + CGFloat(s.id)) * (size.height * 0.15)
                    
                    Circle()
                        .fill(Color(hex: "#FDE68A"))
                        .frame(width: s.size * 0.7, height: s.size * 0.7)
                        .position(x: sparkX, y: sparkY)
                        .shadow(color: PastelTheme.amberWarning, radius: 4)
                }
            }
            .frame(width: fillWidth, height: size.height)
            .clipped()
        }
        
        // Intense plasma leading front & floating magnetic droplet
        if progress > 0.01 && progress < 0.995 {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            PastelTheme.amberWarning.opacity(0.85),
                            Color.white,
                            PastelTheme.amberWarning.opacity(0.85),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 2.5, height: size.height)
                .offset(x: fillWidth - 1.0)
                .blur(radius: 0.7)
                .shadow(color: PastelTheme.amberWarning, radius: 8)
            
            // Floating magnetic plasma droplet
            Circle()
                .fill(Color(hex: "#FDE68A"))
                .frame(width: 4.5, height: 4.5)
                .offset(x: fillWidth + 7 + sin(phase * 2) * 5, y: size.height * 0.45)
                .shadow(color: PastelTheme.amberWarning, radius: 5)
        }
    }
    
    // MARK: - 4. ACOUSTIC PRISM («Звук-Призма»)
    @ViewBuilder
    private func acousticPrismLayer(fillWidth: CGFloat, size: CGSize) -> some View {
        // Acoustic prism glass base with iridescent sheen
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        PastelTheme.slateBlue.opacity(0.10),
                        PastelTheme.slateBlue.opacity(0.22 + sineOscillation(1.0, amplitude: 0.05)),
                        Color(hex: "#34D399").opacity(0.40)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: fillWidth, height: size.height)
        
        // Vertical spectral equalizer strings dancing with music rhythm
        if fillWidth > 20 {
            HStack(spacing: 5) {
                ForEach(0..<Int(fillWidth / 7.0), id: \.self) { i in
                    let norm = CGFloat(i) * 0.35
                    let barH = (sin(norm + phase * 2.5) * 0.4 + 0.6) * (size.height * 0.65)
                    RoundedRectangle(cornerRadius: 1)
                        .fill(i % 3 == 0 ? Color(hex: "#34D399").opacity(0.85) : PastelTheme.slateBlue.opacity(0.50))
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
                .shadow(color: Color(hex: "#34D399"), radius: 5)
        }
    }
}
