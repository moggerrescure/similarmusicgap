import SwiftUI

/// Luxury 5-Axis Acoustic Radar Polygon View (Apple HIG HUD)
public struct TasteRadarView: View {
    public let profile: AcousticProfile
    
    private let axes = ["Energy", "Valence", "Dance", "Acoustic", "Focus"]
    
    public init(profile: AcousticProfile) {
        self.profile = profile
    }
    
    public var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = min(geo.size.width, geo.size.height) / 2 * 0.72
            
            ZStack {
                // Background concentric webs (25%, 50%, 75%, 100%)
                ForEach([0.25, 0.5, 0.75, 1.0], id: \.self) { step in
                    RadarPolygonShape(values: [step, step, step, step, step])
                        .stroke(PastelTheme.cardBorder, lineWidth: 1)
                        .frame(width: radius * 2 * CGFloat(step), height: radius * 2 * CGFloat(step))
                }
                
                // Axis Spokes
                ForEach(0..<5) { i in
                    let angle = angleForIndex(i)
                    Path { path in
                        path.move(to: center)
                        let endPoint = pointAt(angle: angle, radius: radius, center: center)
                        path.addLine(to: endPoint)
                    }
                    .stroke(PastelTheme.cardBorder, lineWidth: 0.5)
                }
                
                // Data Polygon Fill
                RadarPolygonShape(values: [
                    profile.energy,
                    profile.valence,
                    profile.danceability,
                    profile.acousticness,
                    profile.focusFlow
                ])
                .fill(
                    RadialGradient(
                        colors: [PastelTheme.pastelOat.opacity(0.35), PastelTheme.emeraldSuccess.opacity(0.15)],
                        center: .center,
                        startRadius: 0,
                        endRadius: radius
                    )
                )
                .frame(width: radius * 2, height: radius * 2)
                
                // Data Polygon Outline
                RadarPolygonShape(values: [
                    profile.energy,
                    profile.valence,
                    profile.danceability,
                    profile.acousticness,
                    profile.focusFlow
                ])
                .stroke(PastelTheme.pastelOat, lineWidth: 2)
                .frame(width: radius * 2, height: radius * 2)
                
                // Axis Labels
                ForEach(0..<5) { i in
                    let angle = angleForIndex(i)
                    let labelPoint = pointAt(angle: angle, radius: radius + 22, center: center)
                    
                    Text(axes[i].uppercased())
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(0.8)
                        .foregroundColor(PastelTheme.textSecondary)
                        .position(labelPoint)
                }
            }
        }
        .frame(height: 240)
    }
    
    private func angleForIndex(_ index: Int) -> Double {
        Double(index) * (2.0 * .pi / 5.0) - (.pi / 2.0)
    }
    
    private func pointAt(angle: Double, radius: CGFloat, center: CGPoint) -> CGPoint {
        CGPoint(
            x: center.x + radius * CGFloat(cos(angle)),
            y: center.y + radius * CGFloat(sin(angle))
        )
    }
}

// MARK: - Generic Polygon Path Shape
private struct RadarPolygonShape: Shape {
    let values: [Double] // 5 values normalized 0.0 to 1.0
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard values.count == 5 else { return path }
        
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let maxRadius = min(rect.width, rect.height) / 2
        
        var points: [CGPoint] = []
        for (i, val) in values.enumerated() {
            let angle = Double(i) * (2.0 * .pi / 5.0) - (.pi / 2.0)
            let r = maxRadius * CGFloat(max(0.05, min(1.0, val)))
            let pt = CGPoint(
                x: center.x + r * CGFloat(cos(angle)),
                y: center.y + r * CGFloat(sin(angle))
            )
            points.append(pt)
        }
        
        path.move(to: points[0])
        for pt in points.dropFirst() {
            path.addLine(to: pt)
        }
        path.closeSubpath()
        return path
    }
}

