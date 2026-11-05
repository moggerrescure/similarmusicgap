import SwiftUI

/// Animated 4-bar audio equalizer visualizer for active track state
public struct WaveformBarsView: View {
    @State private var animating: Bool = false
    public var barColor: Color = PastelTheme.pastelOat
    
    public init(barColor: Color = PastelTheme.pastelOat) {
        self.barColor = barColor
    }
    
    public var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<4) { i in
                RoundedRectangle(cornerRadius: 1)
                    .fill(barColor)
                    .frame(width: 2.5, height: animating ? CGFloat([14, 20, 9, 16][i]) : 4)
                    .animation(
                        Animation.easeInOut(duration: 0.42)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.1),
                        value: animating
                    )
            }
        }
        .frame(height: 20)
        .onAppear {
            animating = true
        }
    }
}

