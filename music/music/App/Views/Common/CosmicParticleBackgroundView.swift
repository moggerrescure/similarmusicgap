import SwiftUI
import QuartzCore

#if os(iOS)
import UIKit
#else
import AppKit
#endif

// MARK: - 4-Pointed Astroid Star Shape (Variant C, Point 2 from moggerrescure.github.io/information)
/// Mathematical 4-pointed concave astroid star diamond, replicating the exact
/// radial-gradient mask from client's website:
/// mask: radial-gradient(circle at corners) leaving a sharp concave central star.
public struct AstroidStarShape: Shape {
    public init() {}
    
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let midX = rect.midX
        let midY = rect.midY
        let minX = rect.minX
        let maxX = rect.maxX
        let minY = rect.minY
        let maxY = rect.maxY
        
        // Start at top tip (midX, minY)
        path.move(to: CGPoint(x: midX, y: minY))
        
        // Concave curve to right tip (maxX, midY)
        path.addQuadCurve(to: CGPoint(x: maxX, y: midY), control: CGPoint(x: midX, y: midY))
        
        // Concave curve to bottom tip (midX, maxY)
        path.addQuadCurve(to: CGPoint(x: midX, y: maxY), control: CGPoint(x: midX, y: midY))
        
        // Concave curve to left tip (minX, midY)
        path.addQuadCurve(to: CGPoint(x: minX, y: midY), control: CGPoint(x: midX, y: midY))
        
        // Concave curve back to top tip (midX, minY)
        path.addQuadCurve(to: CGPoint(x: midX, y: minY), control: CGPoint(x: midX, y: midY))
        
        path.closeSubpath()
        return path
    }
}

// MARK: - Single Animated Astroid Star Component
public struct AstroidStarItemView: View {
    public let color: Color
    public let size: CGFloat
    public let rotationAngle: Double
    public let baseOpacity: Double
    public let delay: Double
    
    @State private var isBreathing: Bool = false
    
    public init(
        color: Color,
        size: CGFloat,
        rotationAngle: Double,
        baseOpacity: Double,
        delay: Double = 0.0
    ) {
        self.color = color
        self.size = size
        self.rotationAngle = rotationAngle
        self.baseOpacity = baseOpacity
        self.delay = delay
    }
    
    public var body: some View {
        AstroidStarShape()
            .fill(color)
            .frame(width: size, height: size)
            .shadow(color: color.opacity(0.40), radius: size * 0.28)
            .rotationEffect(.degrees(rotationAngle))
            .scaleEffect(isBreathing ? 1.06 : 0.94)
            .opacity(isBreathing ? baseOpacity * 1.25 : baseOpacity * 0.75)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 4.2)
                    .repeatForever(autoreverses: true)
                    .delay(delay)
                ) {
                    isBreathing = true
                }
            }
    }
}

// MARK: - Geometric Astroid Stars Background Layer
public struct GeometricAstroidStarsLayer: View {
    public init() {}
    
    public var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            
            ZStack {
                // 1. Warm Solar Amber Astroid (.star--o: #FF6A15, angle -32 deg)
                AstroidStarItemView(
                    color: Color(hex: "#FF6A15"),
                    size: 68,
                    rotationAngle: -32,
                    baseOpacity: 0.52,
                    delay: 0.0
                )
                .position(x: w * 0.86, y: h * 0.10)
                
                // 2. Pure Diamond White Astroid (.star--w: #FFFFFF, angle +24 deg)
                AstroidStarItemView(
                    color: Color.white,
                    size: 40,
                    rotationAngle: 24,
                    baseOpacity: 0.48,
                    delay: 1.2
                )
                .position(x: w * 0.06, y: h * 0.32)
                
                // 3. Ice Cyan / Crystal Blue Astroid (.star--b: #DFF1FF, angle -54 deg)
                AstroidStarItemView(
                    color: Color(hex: "#DFF1FF"),
                    size: 88,
                    rotationAngle: -54,
                    baseOpacity: 0.30,
                    delay: 2.1
                )
                .position(x: w * 0.94, y: h * 0.53)
                
                // 4. Subtle Ghost Slate Spark (.star--slate: #BBCFD3, angle +45 deg)
                AstroidStarItemView(
                    color: Color(hex: "#BBCFD3"),
                    size: 32,
                    rotationAngle: 45,
                    baseOpacity: 0.20,
                    delay: 0.6
                )
                .position(x: w * 0.10, y: h * 0.74)
                
                // 5. Electric Lime / Emerald Astroid (.star--lime: #C4F449, angle -18 deg)
                AstroidStarItemView(
                    color: Color(hex: "#C4F449"),
                    size: 54,
                    rotationAngle: -18,
                    baseOpacity: 0.50,
                    delay: 1.8
                )
                .position(x: w * 0.84, y: h * 0.88)
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Master Zero-Lag 120 FPS Background
/// Combines the OLED Cashmere Dark Canvas, Procedural Deep Nebula,
/// the 4-Point Astroid Stars from client's website, and GPU CoreAnimation micro-particles.
public struct CosmicParticleBackgroundView: View {
    public var particleCount: Int = 45
    public var showAstroidStars: Bool = true
    
    public init(particleCount: Int = 45, showAstroidStars: Bool = true) {
        self.particleCount = particleCount
        self.showAstroidStars = showAstroidStars
    }
    
    public var body: some View {
        ZStack {
            // 1. OLED Cashmere Deep Canvas (#0E0F12)
            PastelTheme.canvas
            
            // 2. Procedural Deep-Space Nebula Clouds (Inspired by Nebula.jsx from cool)
            RadialGradient(
                colors: [Color(hex: "#161324").opacity(0.45), Color.clear],
                center: .topTrailing,
                startRadius: 40,
                endRadius: 500
            )
            
            RadialGradient(
                colors: [Color(hex: "#0E1824").opacity(0.35), Color.clear],
                center: .bottomLeading,
                startRadius: 60,
                endRadius: 600
            )
            
            // 3. Geometric Astroid Stars (Variant C, Point 2 from moggerrescure.github.io/information)
            if showAstroidStars {
                GeometricAstroidStarsLayer()
            }
            
            // 4. Hardware GPU CAEmitterLayer Particle Stream (CoreAnimation Render Server)
            GPUParticleEmitterRepresentable()
                .opacity(0.65)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Native CoreAnimation GPU Particle Emitter
#if os(iOS)
private struct GPUParticleEmitterRepresentable: UIViewRepresentable {
    func makeUIView(context: Context) -> EmitterContainerView {
        EmitterContainerView()
    }
    func updateUIView(_ uiView: EmitterContainerView, context: Context) {}
}

private final class EmitterContainerView: UIView {
    private let emitterLayer = CAEmitterLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupEmitter()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupEmitter()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        emitterLayer.frame = bounds
        emitterLayer.emitterPosition = CGPoint(x: bounds.midX, y: -20)
        emitterLayer.emitterSize = CGSize(width: bounds.width * 1.2, height: 10)
    }
    
    private func setupEmitter() {
        backgroundColor = .clear
        emitterLayer.emitterShape = .line
        emitterLayer.renderMode = .additive
        
        let particleImage = createParticleImage()
        
        // Cell 1: Soft Oat Stardust
        let oatCell = CAEmitterCell()
        oatCell.contents = particleImage
        oatCell.birthRate = 5
        oatCell.lifetime = 16
        oatCell.velocity = 18
        oatCell.velocityRange = 8
        oatCell.emissionLongitude = .pi // Falling down
        oatCell.emissionRange = .pi / 10
        oatCell.scale = 0.22
        oatCell.scaleRange = 0.16
        oatCell.alphaSpeed = -0.05
        oatCell.color = UIColor(red: 0.94, green: 0.89, blue: 0.83, alpha: 0.75).cgColor
        
        // Cell 2: Muted Cyan / Slate Blue Dust
        let cyanCell = CAEmitterCell()
        cyanCell.contents = particleImage
        cyanCell.birthRate = 3
        cyanCell.lifetime = 20
        cyanCell.velocity = 14
        cyanCell.velocityRange = 6
        cyanCell.emissionLongitude = .pi
        cyanCell.emissionRange = .pi / 8
        cyanCell.scale = 0.18
        cyanCell.scaleRange = 0.12
        cyanCell.alphaSpeed = -0.04
        cyanCell.color = UIColor(red: 0.40, green: 0.65, blue: 0.95, alpha: 0.55).cgColor
        
        // Cell 3: Subtle Emerald Sparkle
        let emeraldCell = CAEmitterCell()
        emeraldCell.contents = particleImage
        emeraldCell.birthRate = 1.5
        emeraldCell.lifetime = 14
        emeraldCell.velocity = 22
        emeraldCell.velocityRange = 10
        emeraldCell.emissionLongitude = .pi
        emeraldCell.scale = 0.26
        emeraldCell.scaleRange = 0.18
        emeraldCell.alphaSpeed = -0.06
        emeraldCell.color = UIColor(red: 0.10, green: 0.75, blue: 0.50, alpha: 0.60).cgColor
        
        emitterLayer.emitterCells = [oatCell, cyanCell, emeraldCell]
        layer.addSublayer(emitterLayer)
    }
    
    private func createParticleImage() -> CGImage? {
        let size = CGSize(width: 16, height: 16)
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        guard let ctx = UIGraphicsGetCurrentContext() else { return nil }
        
        let colors = [UIColor.white.cgColor, UIColor.white.withAlphaComponent(0.0).cgColor]
        let locations: [CGFloat] = [0.0, 1.0]
        guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: locations) else { return nil }
        
        ctx.drawRadialGradient(gradient, startCenter: CGPoint(x: 8, y: 8), startRadius: 0, endCenter: CGPoint(x: 8, y: 8), endRadius: 8, options: [])
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img?.cgImage
    }
}
#else
// MARK: - macOS NSView CoreAnimation Emitter
private struct GPUParticleEmitterRepresentable: NSViewRepresentable {
    func makeNSView(context: Context) -> EmitterContainerView {
        EmitterContainerView()
    }
    func updateNSView(_ nsView: EmitterContainerView, context: Context) {}
}

private final class EmitterContainerView: NSView {
    private let emitterLayer = CAEmitterLayer()
    
    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        setupEmitter()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
        setupEmitter()
    }
    
    override func layout() {
        super.layout()
        emitterLayer.frame = bounds
        emitterLayer.emitterPosition = CGPoint(x: bounds.midX, y: bounds.height + 20)
        emitterLayer.emitterSize = CGSize(width: bounds.width * 1.2, height: 10)
    }
    
    private func setupEmitter() {
        emitterLayer.emitterShape = .line
        emitterLayer.renderMode = .additive
        
        let particleImage = createParticleImage()
        
        // Cell 1: Soft Oat Stardust (#EFE3D3)
        let oatCell = CAEmitterCell()
        oatCell.contents = particleImage
        oatCell.birthRate = 5
        oatCell.lifetime = 16
        oatCell.velocity = 18
        oatCell.velocityRange = 8
        oatCell.emissionLongitude = -.pi / 2
        oatCell.emissionRange = .pi / 10
        oatCell.scale = 0.22
        oatCell.scaleRange = 0.16
        oatCell.alphaSpeed = -0.05
        oatCell.color = CGColor(red: 0.94, green: 0.89, blue: 0.83, alpha: 0.75)
        
        // Cell 2: Muted Cyan / Slate Blue Dust
        let cyanCell = CAEmitterCell()
        cyanCell.contents = particleImage
        cyanCell.birthRate = 3
        cyanCell.lifetime = 20
        cyanCell.velocity = 14
        cyanCell.velocityRange = 6
        cyanCell.emissionLongitude = -.pi / 2
        cyanCell.emissionRange = .pi / 8
        cyanCell.scale = 0.18
        cyanCell.scaleRange = 0.12
        cyanCell.alphaSpeed = -0.04
        cyanCell.color = CGColor(red: 0.40, green: 0.65, blue: 0.95, alpha: 0.55)
        
        // Cell 3: Subtle Emerald Sparkle
        let emeraldCell = CAEmitterCell()
        emeraldCell.contents = particleImage
        emeraldCell.birthRate = 1.5
        emeraldCell.lifetime = 14
        emeraldCell.velocity = 22
        emeraldCell.velocityRange = 10
        emeraldCell.emissionLongitude = -.pi / 2
        emeraldCell.scale = 0.26
        emeraldCell.scaleRange = 0.18
        emeraldCell.alphaSpeed = -0.06
        emeraldCell.color = CGColor(red: 0.10, green: 0.75, blue: 0.50, alpha: 0.60)
        
        emitterLayer.emitterCells = [oatCell, cyanCell, emeraldCell]
        layer?.addSublayer(emitterLayer)
    }
    
    private func createParticleImage() -> CGImage? {
        let size = CGSize(width: 16, height: 16)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(
            data: nil,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        
        let colors = [CGColor(red: 1, green: 1, blue: 1, alpha: 1), CGColor(red: 1, green: 1, blue: 1, alpha: 0)] as CFArray
        let locations: [CGFloat] = [0.0, 1.0]
        guard let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations) else { return nil }
        
        ctx.drawRadialGradient(gradient, startCenter: CGPoint(x: 8, y: 8), startRadius: 0, endCenter: CGPoint(x: 8, y: 8), endRadius: 8, options: [])
        return ctx.makeImage()
    }
}
#endif
