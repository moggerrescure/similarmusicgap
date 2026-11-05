import SwiftUI

/// High-performance Canvas-based Deep Cosmos Particle Background
/// Inspired by GitHub Universe stardust and Apple HIG HUD ambient space aesthetic.
public struct CosmicParticleBackgroundView: View {
    // Fixed deterministic particles
    private struct Particle {
        var x: Double          // 0.0 ... 1.0 (relative screen width)
        var y: Double          // 0.0 ... 1.0 (relative screen height)
        var radius: Double     // particle size in points (1.0 ... 2.8)
        var speedY: Double     // downward vertical drift speed
        var driftAmp: Double   // horizontal sway amplitude
        var driftFreq: Double  // horizontal sway frequency
        var phase: Double      // initial phase offset
        var baseOpacity: Double
        var color: Color
    }
    
    // Seeded starfield particles
    private let particles: [Particle]
    
    public init(particleCount: Int = 65) {
        var generated: [Particle] = []
        var seed: UInt64 = 4294967291
        
        func lcgRandom() -> Double {
            seed = (seed &* 6364136223846793005) &+ 1442695040888963407
            return Double(seed % 10000) / 10000.0
        }
        
        let colors: [Color] = [
            PastelTheme.pastelOat,                      // Soft stardust Oat (#EFE3D3)
            Color(hex: "#60A5FA"),                      // Muted Slate Blue stardust
            PastelTheme.emeraldSuccess.opacity(0.8),    // Faint emerald sparkle
            Color(hex: "#FDE68A"),                      // Soft solar sparkle
            Color.white                                 // Diamond point
        ]
        
        for _ in 0..<particleCount {
            let col = colors[Int(lcgRandom() * Double(colors.count))]
            let p = Particle(
                x: lcgRandom(),
                y: lcgRandom(),
                radius: 0.9 + lcgRandom() * 1.8,
                speedY: 0.012 + lcgRandom() * 0.025,
                driftAmp: 0.008 + lcgRandom() * 0.015,
                driftFreq: 0.4 + lcgRandom() * 0.8,
                phase: lcgRandom() * .pi * 2,
                baseOpacity: 0.18 + lcgRandom() * 0.45,
                color: col
            )
            generated.append(p)
        }
        self.particles = generated
    }
    
    public var body: some View {
        TimelineView(.animation) { timeline in
            let elapsed = timeline.date.timeIntervalSinceReferenceDate
            
            Canvas { context, size in
                guard size.width > 0 && size.height > 0 else { return }
                
                // Draw each particle with smooth vertical wrap & horizontal gentle sway
                for p in particles {
                    // Vertical continuous flow (falling cosmic dust)
                    let currentY = (p.y + elapsed * p.speedY).truncatingRemainder(dividingBy: 1.0)
                    let screenY = currentY * size.height
                    
                    // Horizontal organic floating
                    let sway = sin(elapsed * p.driftFreq + p.phase) * p.driftAmp
                    let currentX = (p.x + sway).truncatingRemainder(dividingBy: 1.0)
                    let screenX = (currentX < 0 ? currentX + 1.0 : currentX) * size.width
                    
                    // Subtle twinkling brightness pulsation
                    let twinkle = 0.75 + 0.25 * sin(elapsed * 1.8 + p.phase * 3)
                    let opacity = p.baseOpacity * twinkle
                    
                    let rect = CGRect(
                        x: screenX - p.radius,
                        y: screenY - p.radius,
                        width: p.radius * 2,
                        height: p.radius * 2
                    )
                    
                    // Soft outer glow for larger particles
                    if p.radius > 1.8 {
                        let glowRect = CGRect(
                            x: screenX - p.radius * 2.2,
                            y: screenY - p.radius * 2.2,
                            width: p.radius * 4.4,
                            height: p.radius * 4.4
                        )
                        context.fill(
                            Path(ellipseIn: glowRect),
                            with: .color(p.color.opacity(opacity * 0.25))
                        )
                    }
                    
                    context.fill(
                        Path(ellipseIn: rect),
                        with: .color(p.color.opacity(opacity))
                    )
                }
                
                // Occasional cinematic shooting star streak
                let streakInterval = 12.0
                let streakProgress = (elapsed.truncatingRemainder(dividingBy: streakInterval)) / 1.0
                if streakProgress < 1.0 {
                    let streakX = size.width * (0.15 + streakProgress * 0.7)
                    let streakY = size.height * (0.08 + streakProgress * 0.35)
                    let streakAlpha = sin(streakProgress * .pi) * 0.45
                    
                    var streakPath = Path()
                    streakPath.move(to: CGPoint(x: streakX - 40, y: streakY - 20))
                    streakPath.addLine(to: CGPoint(x: streakX, y: streakY))
                    
                    context.stroke(
                        streakPath,
                        with: .linearGradient(
                            Gradient(colors: [Color.clear, PastelTheme.pastelOat.opacity(streakAlpha)]),
                            startPoint: CGPoint(x: streakX - 40, y: streakY - 20),
                            endPoint: CGPoint(x: streakX, y: streakY)
                        ),
                        style: StrokeStyle(lineWidth: 1.2, lineCap: .round)
                    )
                }
            }
        }
        .background(PastelTheme.canvas)
        .ignoresSafeArea()
    }
}
