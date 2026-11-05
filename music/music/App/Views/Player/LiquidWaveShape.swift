import SwiftUI

/// Animatable sinusoidal liquid wave shape for 3D fluid water-fill effect
public struct LiquidWaveShape: Shape {
    public var progress: CGFloat // 0.0 to 1.0
    public var phase: CGFloat    // continuous angle in radians
    public var amplitude: CGFloat = 6.0 // height of wave crests
    
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
        
        // Target vertical level of water surface
        let fillLevel = height * (1.0 - max(0.0, min(1.0, progress)))
        
        path.move(to: CGPoint(x: 0, y: height))
        path.addLine(to: CGPoint(x: 0, y: fillLevel))
        
        // Generate sine wave curve across the horizontal axis
        let waveLength = max(width / 2.0, 80.0)
        for x in stride(from: 0, through: width + 5, by: 4) {
            let relativeX = x / waveLength
            let sine = sin(relativeX * 2 * .pi + phase)
            let y = fillLevel + sine * amplitude * (1.0 - abs(0.5 - progress) * 0.5)
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.addLine(to: CGPoint(x: width, y: height))
        path.closeSubpath()
        return path
    }
}

/// Dynamic 3D fluid water-fill progress view
public struct LiquidWaveProgressView: View {
    public var progress: Double // 0.0 to 1.0
    public var color: Color = PastelTheme.pastelOat
    public var secondaryColor: Color = PastelTheme.emeraldSuccess.opacity(0.6)
    
    @State private var phase: CGFloat = 0.0
    
    public init(progress: Double, color: Color = PastelTheme.pastelOat, secondaryColor: Color = PastelTheme.emeraldSuccess.opacity(0.6)) {
        self.progress = progress
        self.color = color
        self.secondaryColor = secondaryColor
    }
    
    public var body: some View {
        ZStack {
            // Background water layer (secondary)
            LiquidWaveShape(
                progress: CGFloat(progress),
                phase: phase * 0.7,
                amplitude: 4.0
            )
            .fill(secondaryColor.opacity(0.35))
            
            // Foreground water layer (primary)
            LiquidWaveShape(
                progress: CGFloat(progress),
                phase: phase,
                amplitude: 5.0
            )
            .fill(
                LinearGradient(
                    colors: [color.opacity(0.85), color.opacity(0.4)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .onAppear {
            withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
        }
    }
}
