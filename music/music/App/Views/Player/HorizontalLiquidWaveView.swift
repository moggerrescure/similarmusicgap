import SwiftUI

/// Horizontal liquid water-fill shape that fills from Left to Right
/// with organic fluid meniscus wave undulation at the leading edge.
public struct HorizontalLiquidWaveShape: Shape {
    public var progress: CGFloat // 0.0 to 1.0
    public var phase: CGFloat    // continuous angle in radians
    public var amplitude: CGFloat = 5.0 // wave crest depth
    
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
        
        // Horizontal level reached by water
        let clampedProgress = max(0.0, min(1.0, progress))
        let targetX = width * clampedProgress
        
        // If near zero, don't show negative edge
        if clampedProgress <= 0.001 {
            return path
        }
        
        // Start at top-left corner
        path.move(to: CGPoint(x: 0, y: 0))
        
        // If fully filled (>= 0.999), just fill the whole rectangle
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
            
            // Double-frequency harmonic wave for realistic fluid surge
            let wave1 = sin(normalizedY * .pi * 2.5 + phase) * amplitude
            let wave2 = cos(normalizedY * .pi * 5.0 + phase * 1.3) * (amplitude * 0.4)
            let currentX = targetX + wave1 + wave2
            
            path.addLine(to: CGPoint(x: currentX, y: y))
        }
        
        // Bottom edge back to bottom-left corner
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        return path
    }
}

/// Dynamic 3D Horizontal Water Fill Progress Bar with Seconds Display
public struct HorizontalLiquidWaveProgressView: View {
    public var progress: Double // 0.0 to 1.0
    public var currentTime: Double = 0.0
    public var duration: Double = 0.0
    public var showSecondsHUD: Bool = true
    
    public var primaryColor: Color = PastelTheme.pastelOat
    public var secondaryColor: Color = PastelTheme.emeraldSuccess
    
    @State private var phase: CGFloat = 0.0
    
    public init(
        progress: Double,
        currentTime: Double = 0.0,
        duration: Double = 0.0,
        showSecondsHUD: Bool = true,
        primaryColor: Color = PastelTheme.pastelOat,
        secondaryColor: Color = PastelTheme.emeraldSuccess
    ) {
        self.progress = progress
        self.currentTime = currentTime
        self.duration = duration
        self.showSecondsHUD = showSecondsHUD
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
    }
    
    public var body: some View {
        ZStack(alignment: .leading) {
            // Layer 1: Background liquid wash (secondary harmonic)
            HorizontalLiquidWaveShape(
                progress: CGFloat(progress),
                phase: phase * 0.75 + .pi / 4,
                amplitude: 3.5
            )
            .fill(
                LinearGradient(
                    colors: [
                        secondaryColor.opacity(0.08),
                        secondaryColor.opacity(0.18)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            
            // Layer 2: Primary liquid wave with horizontal fluid surge
            HorizontalLiquidWaveShape(
                progress: CGFloat(progress),
                phase: phase,
                amplitude: 4.5
            )
            .fill(
                LinearGradient(
                    colors: [
                        primaryColor.opacity(0.06),
                        primaryColor.opacity(0.18),
                        primaryColor.opacity(0.28)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            
            // Layer 3: Specular leading-edge fluid crest highlight
            if progress > 0.01 && progress < 0.99 {
                GeometryReader { geo in
                    let xPos = geo.size.width * CGFloat(progress)
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.clear,
                                    primaryColor.opacity(0.4),
                                    Color.white.opacity(0.7),
                                    primaryColor.opacity(0.4),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 2.0, height: geo.size.height)
                        .offset(x: xPos - 1.0)
                        .blur(radius: 0.8)
                }
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 2.2).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
        }
    }
}
