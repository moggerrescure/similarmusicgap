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
        let topWaveX = targetX + CGFloat(sin(Double(phase))) * amplitude
        path.addLine(to: CGPoint(x: topWaveX, y: 0))
        
        // Fluid vertical meniscus curve from y = 0 down to y = height
        let steps = 24
        let stepHeight = height / CGFloat(steps)
        for i in 1...steps {
            let y = CGFloat(i) * stepHeight
            let normalizedY = Double(y / height)
            let phaseD = Double(phase)
            
            let wave1 = CGFloat(sin(normalizedY * Double.pi * 2.5 + phaseD)) * amplitude
            let wave2 = CGFloat(cos(normalizedY * Double.pi * 5.0 + phaseD * 1.3)) * (amplitude * 0.4)
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

private let kSeededFlaskParticles: [FlaskInternalParticle] = [
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
            let fillWidth = max(0.0, min(geo.size.width, geo.size.width * CGFloat(progress)))
            
            ZStack(alignment: .leading) {
                switch activeStyle {
                case .chronosStardust:
                    ChronosStardustContainer(
                        fillWidth: fillWidth,
                        size: geo.size,
                        progress: progress,
                        phase: phase
                    )
                case .mercuryOcean:
                    MercuryOceanContainer(
                        fillWidth: fillWidth,
                        size: geo.size,
                        progress: progress,
                        phase: phase
                    )
                case .quantumPlasma:
                    QuantumPlasmaContainer(
                        fillWidth: fillWidth,
                        size: geo.size,
                        progress: progress,
                        phase: phase
                    )
                case .acousticPrism:
                    AcousticPrismContainer(
                        fillWidth: fillWidth,
                        size: geo.size,
                        progress: progress,
                        phase: phase
                    )
                }
                
                // Crystal Flask Glass Specular Sheen & Iridescent Glint
                FlaskGlassSpecularSheen(
                    phase: phase,
                    size: geo.size
                )
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 2.6).repeatForever(autoreverses: false)) {
                phase = CGFloat(Double.pi * 2.0)
            }
        }
    }
}

// MARK: - 1. CHRONOS STARDUST SUBVIEWS («Хроно-Песок» - DEFAULT)

private struct ChronosStardustContainer: View {
    let fillWidth: CGFloat
    let size: CGSize
    let progress: Double
    let phase: CGFloat
    
    var body: some View {
        ZStack(alignment: .leading) {
            ChronosDuneWash(progress: progress, phase: phase)
            
            if fillWidth > 18 {
                ChronosParticlesDrift(fillWidth: fillWidth, size: size, phase: phase)
            }
            
            if progress > 0.01 && progress < 0.995 {
                ChronosCrestGlint(fillWidth: fillWidth, size: size, phase: phase)
            }
        }
    }
}

private struct ChronosDuneWash: View {
    let progress: Double
    let phase: CGFloat
    
    private var startUnitPoint: UnitPoint {
        let offsetX = CGFloat(sin(Double(phase) * 0.5) * 0.15)
        return UnitPoint(x: offsetX, y: 0)
    }
    
    private var endUnitPoint: UnitPoint {
        let offsetX = CGFloat(cos(Double(phase) * 0.5) * 0.15)
        return UnitPoint(x: 1.0 + offsetX, y: 1.0)
    }
    
    private var gradientColors: [Color] {
        let pD = Double(phase)
        let stop2Opacity = 0.26 + sin(pD * 0.8) * 0.05
        let stop3Opacity = 0.28 + cos(pD * 0.8) * 0.06
        let stop4Opacity = 0.50 + sin(pD * 1.2) * 0.08
        return [
            PastelTheme.pastelOat.opacity(0.12),
            PastelTheme.pastelOat.opacity(stop2Opacity),
            Color(hex: "#FDE68A").opacity(stop3Opacity),
            Color(hex: "#FFF8EC").opacity(stop4Opacity)
        ]
    }
    
    var body: some View {
        HorizontalLiquidWaveShape(
            progress: CGFloat(progress),
            phase: phase,
            amplitude: 3.8
        )
        .fill(
            LinearGradient(
                colors: gradientColors,
                startPoint: startUnitPoint,
                endPoint: endUnitPoint
            )
        )
    }
}

private struct ChronosParticlesDrift: View {
    let fillWidth: CGFloat
    let size: CGSize
    let phase: CGFloat
    
    var body: some View {
        ZStack(alignment: .leading) {
            ForEach(kSeededFlaskParticles) { p in
                ChronosSingleParticle(
                    p: p,
                    fillWidth: fillWidth,
                    size: size,
                    phase: phase
                )
            }
        }
        .frame(width: fillWidth, height: size.height)
        .clipped()
    }
}

private struct ChronosSingleParticle: View {
    let p: FlaskInternalParticle
    let fillWidth: CGFloat
    let size: CGSize
    let phase: CGFloat
    
    private var particleX: CGFloat {
        let pD = Double(phase)
        let drift = (Double(p.relX) + (pD / (Double.pi * 2.0)) * Double(p.speed)).truncatingRemainder(dividingBy: 1.0)
        let normalized = drift >= 0 ? drift : drift + 1.0
        return fillWidth * CGFloat(normalized)
    }
    
    private var particleY: CGFloat {
        let pD = Double(phase)
        let verticalSway = CGFloat(sin(pD * 1.6 + Double(p.id))) * (size.height * 0.14)
        return size.height * p.relY + verticalSway
    }
    
    private var particleOpacity: Double {
        let pD = Double(phase)
        let twinkle = 0.60 + 0.40 * sin(pD * 2.5 + Double(p.id) * 1.2)
        return p.baseOpacity * twinkle
    }
    
    private var particleRotation: Double {
        Double(phase * 40.0) + Double(p.id * 30)
    }
    
    var body: some View {
        Group {
            if p.isDiamond {
                Image(systemName: "sparkle")
                    .font(.system(size: p.size))
                    .foregroundColor(Color(hex: "#FFF8EC").opacity(particleOpacity))
                    .rotationEffect(.degrees(particleRotation))
            } else {
                ZStack {
                    Circle()
                        .fill(PastelTheme.pastelOat.opacity(particleOpacity * 0.35))
                        .frame(width: p.size * 2.0, height: p.size * 2.0)
                    Circle()
                        .fill(Color.white.opacity(particleOpacity))
                        .frame(width: p.size, height: p.size)
                }
            }
        }
        .position(x: particleX, y: particleY)
    }
}

private struct ChronosCrestGlint: View {
    let fillWidth: CGFloat
    let size: CGSize
    let phase: CGFloat
    
    private var ember1Offset: (x: CGFloat, y: CGFloat) {
        let pD = Double(phase)
        let ox = fillWidth + 6.0 + CGFloat(sin(pD * 2.0) * 5.0)
        let oy = size.height * 0.30 + CGFloat(cos(pD * 1.5) * 4.0)
        return (ox, oy)
    }
    
    private var ember2Offset: (x: CGFloat, y: CGFloat) {
        let pD = Double(phase)
        let ox = fillWidth + 14.0 + CGFloat(cos(pD * 2.2) * 4.0)
        let oy = size.height * 0.70 + CGFloat(sin(pD * 1.8) * 5.0)
        return (ox, oy)
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Flying stardust ember 1 (organic particle without vertical cutoff line)
            Circle()
                .fill(Color.white.opacity(0.95))
                .frame(width: 2.5, height: 2.5)
                .offset(x: ember1Offset.x, y: ember1Offset.y)
                .shadow(color: Color(hex: "#FFF8EC"), radius: 3)
            
            // Flying stardust ember 2
            Circle()
                .fill(Color(hex: "#FDE68A").opacity(0.90))
                .frame(width: 2.0, height: 2.0)
                .offset(x: ember2Offset.x, y: ember2Offset.y)
                .shadow(color: PastelTheme.warmAmber, radius: 2)
        }
    }
}

// MARK: - 2. MERCURY OCEAN SUBVIEWS («Меркури-Океан»)

private struct MercuryOceanContainer: View {
    let fillWidth: CGFloat
    let size: CGSize
    let progress: Double
    let phase: CGFloat
    
    var body: some View {
        ZStack(alignment: .leading) {
            MercuryWavesWash(progress: progress, phase: phase)
            
            if fillWidth > 20 {
                MercuryBubblesDrift(fillWidth: fillWidth, size: size, phase: phase)
            }
            
            if progress > 0.01 && progress < 0.995 {
                MercuryCrestCaustic(fillWidth: fillWidth, size: size)
            }
        }
    }
}

private struct MercuryWavesWash: View {
    let progress: Double
    let phase: CGFloat
    
    private var wave2Colors: [Color] {
        let pD = Double(phase)
        let middleOpacity = 0.28 + sin(pD) * 0.05
        return [
            PastelTheme.emeraldSuccess.opacity(0.12),
            PastelTheme.emeraldSuccess.opacity(middleOpacity),
            Color(hex: "#34D399").opacity(0.45)
        ]
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            HorizontalLiquidWaveShape(
                progress: CGFloat(progress),
                phase: phase * 0.8 + CGFloat(Double.pi / 4.0),
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
                    colors: wave2Colors,
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        }
    }
}

private struct MercuryBubblesDrift: View {
    let fillWidth: CGFloat
    let size: CGSize
    let phase: CGFloat
    
    var body: some View {
        ZStack(alignment: .leading) {
            ForEach(Array(kSeededFlaskParticles.prefix(8))) { b in
                MercurySingleBubble(
                    b: b,
                    fillWidth: fillWidth,
                    size: size,
                    phase: phase
                )
            }
        }
        .frame(width: fillWidth, height: size.height)
        .clipped()
    }
}

private struct MercurySingleBubble: View {
    let b: FlaskInternalParticle
    let fillWidth: CGFloat
    let size: CGSize
    let phase: CGFloat
    
    private var bubblePosition: CGPoint {
        let pD = Double(phase)
        let drift = (Double(b.relX) + (pD / (Double.pi * 2.0)) * 0.3).truncatingRemainder(dividingBy: 1.0)
        let normX = drift >= 0 ? drift : drift + 1.0
        let wobble = CGFloat(sin(pD * 2.0 + Double(b.id))) * 2.5
        let bubbleX = fillWidth * CGFloat(normX) + wobble
        
        let rise = (Double(b.relY) - (pD * 0.15 * Double(b.speed))).truncatingRemainder(dividingBy: 1.0)
        let normY = rise >= 0 ? rise : rise + 1.0
        let bubbleY = size.height * CGFloat(normY)
        return CGPoint(x: bubbleX, y: bubbleY)
    }
    
    private var bubbleFill: Color {
        b.id % 2 == 0 ? Color.white.opacity(0.85) : PastelTheme.emeraldSuccess.opacity(0.90)
    }
    
    var body: some View {
        Circle()
            .fill(bubbleFill)
            .frame(width: b.size * 0.6, height: b.size * 0.6)
            .position(bubblePosition)
    }
}

private struct MercuryCrestCaustic: View {
    let fillWidth: CGFloat
    let size: CGSize
    
    var body: some View {
        EmptyView()
    }
}

// MARK: - 3. QUANTUM PLASMA SUBVIEWS («Квант-Плазма»)

private struct QuantumPlasmaContainer: View {
    let fillWidth: CGFloat
    let size: CGSize
    let progress: Double
    let phase: CGFloat
    
    var body: some View {
        ZStack(alignment: .leading) {
            QuantumPlasmaSurge(progress: progress, phase: phase)
            
            if fillWidth > 20 {
                QuantumSparksDrift(fillWidth: fillWidth, size: size, phase: phase)
            }
            
            if progress > 0.01 && progress < 0.995 {
                QuantumCrestDroplet(fillWidth: fillWidth, size: size, phase: phase)
            }
        }
    }
}

private struct QuantumPlasmaSurge: View {
    let progress: Double
    let phase: CGFloat
    
    private var gradientColors: [Color] {
        let pD = Double(phase)
        let stop2Opacity = 0.32 + sin(pD * 1.5) * 0.08
        let stop3Opacity = 0.55 + cos(pD * 1.5) * 0.08
        return [
            PastelTheme.amberWarning.opacity(0.12),
            PastelTheme.amberWarning.opacity(stop2Opacity),
            Color(hex: "#FDE68A").opacity(stop3Opacity)
        ]
    }
    
    var body: some View {
        HorizontalLiquidWaveShape(
            progress: CGFloat(progress),
            phase: phase * 1.5,
            amplitude: 5.5
        )
        .fill(
            LinearGradient(
                colors: gradientColors,
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }
}

private struct QuantumSparksDrift: View {
    let fillWidth: CGFloat
    let size: CGSize
    let phase: CGFloat
    
    var body: some View {
        ZStack(alignment: .leading) {
            ForEach(Array(kSeededFlaskParticles.prefix(6))) { s in
                QuantumSingleSpark(
                    s: s,
                    fillWidth: fillWidth,
                    size: size,
                    phase: phase
                )
            }
        }
        .frame(width: fillWidth, height: size.height)
        .clipped()
    }
}

private struct QuantumSingleSpark: View {
    let s: FlaskInternalParticle
    let fillWidth: CGFloat
    let size: CGSize
    let phase: CGFloat
    
    private var sparkPosition: CGPoint {
        let pD = Double(phase)
        let drift = (Double(s.relX) + (pD / (Double.pi * 2.0)) * 0.45).truncatingRemainder(dividingBy: 1.0)
        let normX = drift >= 0 ? drift : drift + 1.0
        let sparkX = fillWidth * CGFloat(normX)
        let sparkY = size.height * s.relY + CGFloat(sin(pD * 2.5 + Double(s.id))) * (size.height * 0.15)
        return CGPoint(x: sparkX, y: sparkY)
    }
    
    var body: some View {
        Circle()
            .fill(Color(hex: "#FDE68A"))
            .frame(width: s.size * 0.7, height: s.size * 0.7)
            .position(sparkPosition)
            .shadow(color: PastelTheme.amberWarning, radius: 4)
    }
}

private struct QuantumCrestDroplet: View {
    let fillWidth: CGFloat
    let size: CGSize
    let phase: CGFloat
    
    private var dropletOffsetX: CGFloat {
        let pD = Double(phase)
        return fillWidth + 7.0 + CGFloat(sin(pD * 2.0) * 5.0)
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            Circle()
                .fill(Color(hex: "#FDE68A"))
                .frame(width: 4.5, height: 4.5)
                .offset(x: dropletOffsetX, y: size.height * 0.45)
                .shadow(color: PastelTheme.amberWarning, radius: 5)
        }
    }
}

// MARK: - 4. ACOUSTIC PRISM SUBVIEWS («Звук-Призма»)

private struct AcousticPrismContainer: View {
    let fillWidth: CGFloat
    let size: CGSize
    let progress: Double
    let phase: CGFloat
    
    var body: some View {
        ZStack(alignment: .leading) {
            AcousticPrismBaseWash(fillWidth: fillWidth, size: size, phase: phase)
            
            if fillWidth > 20 {
                AcousticPrismEqualizer(fillWidth: fillWidth, size: size, phase: phase)
            }
            
            if progress > 0.01 && progress < 0.995 {
                AcousticPrismCrest(fillWidth: fillWidth, size: size)
            }
        }
    }
}

private struct AcousticPrismBaseWash: View {
    let fillWidth: CGFloat
    let size: CGSize
    let phase: CGFloat
    
    private var gradientColors: [Color] {
        let pD = Double(phase)
        let midOpacity = 0.22 + sin(pD) * 0.05
        return [
            PastelTheme.slateBlue.opacity(0.10),
            PastelTheme.slateBlue.opacity(midOpacity),
            Color(hex: "#34D399").opacity(0.40)
        ]
    }
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: fillWidth, height: size.height)
    }
}

private struct AcousticPrismEqualizer: View {
    let fillWidth: CGFloat
    let size: CGSize
    let phase: CGFloat
    
    private var barCount: Int {
        max(1, Int(fillWidth / 7.0))
    }
    
    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<barCount, id: \.self) { i in
                AcousticSingleBar(index: i, size: size, phase: phase)
            }
            Spacer(minLength: 0)
        }
        .frame(width: fillWidth, height: size.height)
        .clipped()
    }
}

private struct AcousticSingleBar: View {
    let index: Int
    let size: CGSize
    let phase: CGFloat
    
    private var barHeight: CGFloat {
        let pD = Double(phase)
        let norm = Double(index) * 0.35
        let raw = (sin(norm + pD * 2.5) * 0.4 + 0.6) * Double(size.height * 0.65)
        return max(4.0, CGFloat(raw))
    }
    
    private var barColor: Color {
        index % 3 == 0 ? Color(hex: "#34D399").opacity(0.85) : PastelTheme.slateBlue.opacity(0.50)
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(barColor)
            .frame(width: 2, height: barHeight)
    }
}

private struct AcousticPrismCrest: View {
    let fillWidth: CGFloat
    let size: CGSize
    
    var body: some View {
        EmptyView()
    }
}

// MARK: - Specular Glass Tube Sheen (Зеркальный перелив трубки)

private struct FlaskGlassSpecularSheen: View {
    let phase: CGFloat
    let size: CGSize
    
    private var sweepOffset: CGFloat {
        let pD = Double(phase)
        let wave = sin(pD * 0.6) * 0.5 + 0.5
        return CGFloat(wave) * size.width
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
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
    }
}
