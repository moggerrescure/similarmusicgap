import SwiftUI
import QuartzCore

#if os(iOS)
import UIKit
#else
import AppKit
#endif

/// Clean, Ultra-Luxury Apple HIG HUD Deep OLED Background (0% CPU, 120 FPS)
/// Free of heavy shapes, giant stars, and visual noise.
/// Features a pure OLED Cashmere Charcoal canvas (#0E0F12) with subtle atmospheric depth
/// and crisp, luminous GitHub Universe stardust particles drifting gracefully on GPU.
public struct CosmicParticleBackgroundView: View {
    @ObservedObject private var coordinator = ServicesCoordinator.shared
    public var particleCount: Int = 40
    
    public init(particleCount: Int = 40) {
        self.particleCount = particleCount
    }
    
    public var body: some View {
        ZStack {
            // 1. OLED Cashmere Deep Canvas (#0E0F12)
            PastelTheme.canvas
            
            // 2. Faint, Quiet Luxury Vignette (No loud colors, strictly elegant Apple dark space)
            RadialGradient(
                colors: [Color(hex: "#14151C").opacity(0.35), Color.clear],
                center: .topTrailing,
                startRadius: 50,
                endRadius: 520
            )
            
            RadialGradient(
                colors: [Color(hex: "#101217").opacity(0.25), Color.clear],
                center: .bottomLeading,
                startRadius: 80,
                endRadius: 600
            )
            
            // 3. Hardware GPU CAEmitterLayer: Luminous, crisp stardust (0% CPU, 120 FPS)
            // Controlled by the user toggle in Profile & Vault
            if coordinator.backgroundParticlesEnabled {
                GPUMicroStardustEmitterRepresentable()
                    .allowsHitTesting(false)
                    .opacity(0.85)
                    .transition(.opacity)
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Native CoreAnimation GPU Stardust Emitter (iOS)
#if os(iOS)
private struct GPUMicroStardustEmitterRepresentable: UIViewRepresentable {
    func makeUIView(context: Context) -> MicroEmitterContainerView {
        MicroEmitterContainerView()
    }
    
    func updateUIView(_ uiView: MicroEmitterContainerView, context: Context) {
        uiView.updateEmitterBounds()
    }
}

private final class MicroEmitterContainerView: UIView {
    override class var layerClass: AnyClass {
        CAEmitterLayer.self
    }
    
    var emitterLayer: CAEmitterLayer {
        layer as! CAEmitterLayer
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        setupEmitter()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        isUserInteractionEnabled = false
        setupEmitter()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateEmitterBounds()
    }
    
    func updateEmitterBounds() {
        guard bounds.width > 0 && bounds.height > 0 else { return }
        emitterLayer.frame = bounds
        emitterLayer.emitterPosition = CGPoint(x: bounds.midX, y: bounds.midY)
        emitterLayer.emitterSize = CGSize(width: bounds.width * 1.15, height: bounds.height * 1.15)
    }
    
    private func setupEmitter() {
        backgroundColor = .clear
        emitterLayer.emitterShape = .rectangle
        emitterLayer.emitterMode = .volume
        emitterLayer.renderMode = .additive
        
        // Fast-forward simulation by 30 seconds so particles already fill the screen on launch
        emitterLayer.beginTime = CACurrentMediaTime() - 30.0
        
        guard let dotImage = StardustSpriteGenerator.createStardustDotImage() else { return }
        emitterLayer.emitterCells = StardustSpriteGenerator.createEmitterCells(with: dotImage)
    }
}
#else
// MARK: - Native CoreAnimation GPU Stardust Emitter (macOS)
private struct GPUMicroStardustEmitterRepresentable: NSViewRepresentable {
    func makeNSView(context: Context) -> MicroEmitterContainerView {
        MicroEmitterContainerView()
    }
    
    func updateNSView(_ nsView: MicroEmitterContainerView, context: Context) {
        nsView.updateEmitterBounds()
    }
}

private final class MicroEmitterContainerView: NSView {
    override var isFlipped: Bool { true }
    
    override func makeBackingLayer() -> CALayer {
        CAEmitterLayer()
    }
    
    var emitterLayer: CAEmitterLayer {
        layer as! CAEmitterLayer
    }
    
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
        updateEmitterBounds()
    }
    
    func updateEmitterBounds() {
        guard bounds.width > 0 && bounds.height > 0 else { return }
        emitterLayer.frame = bounds
        emitterLayer.emitterPosition = CGPoint(x: bounds.midX, y: bounds.midY)
        emitterLayer.emitterSize = CGSize(width: bounds.width * 1.15, height: bounds.height * 1.15)
    }
    
    private func setupEmitter() {
        emitterLayer.emitterShape = .rectangle
        emitterLayer.emitterMode = .volume
        emitterLayer.renderMode = .additive
        
        // Fast-forward simulation by 30 seconds so particles already fill the screen on launch
        emitterLayer.beginTime = CACurrentMediaTime() - 30.0
        
        guard let dotImage = StardustSpriteGenerator.createStardustDotImage() else { return }
        emitterLayer.emitterCells = StardustSpriteGenerator.createEmitterCells(with: dotImage)
    }
}
#endif

// MARK: - Shared GPU Stardust Sprite & Cell Configuration
private enum StardustSpriteGenerator {
    static func createEmitterCells(with dotImage: CGImage) -> [CAEmitterCell] {
        // 1. Soft Cashmere Oat Stardust (#EFE3D3 - 65% of field)
        let oatCell = CAEmitterCell()
        oatCell.contents = dotImage
        oatCell.birthRate = 2.6
        oatCell.lifetime = 14.0
        oatCell.velocity = 15.0
        oatCell.velocityRange = 6.0
        oatCell.emissionLongitude = .pi / 2 // Downward in flipped coordinate system
        oatCell.emissionRange = .pi / 6      // Soft gentle horizontal drift angle
        oatCell.scale = 0.22
        oatCell.scaleRange = 0.08
        oatCell.alphaRange = 0.20
        oatCell.alphaSpeed = -0.05
        oatCell.color = CGColor(red: 0.94, green: 0.89, blue: 0.83, alpha: 0.88)
        
        // 2. Faint Slate Atmospheric Stardust (#93C5FD - 25% of field)
        let slateCell = CAEmitterCell()
        slateCell.contents = dotImage
        slateCell.birthRate = 1.0
        slateCell.lifetime = 16.0
        slateCell.velocity = 11.0
        slateCell.velocityRange = 4.0
        slateCell.emissionLongitude = .pi / 2
        slateCell.emissionRange = .pi / 5
        slateCell.scale = 0.16
        slateCell.scaleRange = 0.06
        slateCell.alphaRange = 0.25
        slateCell.alphaSpeed = -0.04
        slateCell.color = CGColor(red: 0.58, green: 0.77, blue: 0.99, alpha: 0.72)
        
        // 3. Rare Emerald Sparkle (#10B981 - 10% of field)
        let emeraldCell = CAEmitterCell()
        emeraldCell.contents = dotImage
        emeraldCell.birthRate = 0.4
        emeraldCell.lifetime = 12.0
        emeraldCell.velocity = 18.0
        emeraldCell.velocityRange = 7.0
        emeraldCell.emissionLongitude = .pi / 2
        emeraldCell.emissionRange = .pi / 7
        emeraldCell.scale = 0.26
        emeraldCell.scaleRange = 0.09
        emeraldCell.alphaRange = 0.20
        emeraldCell.alphaSpeed = -0.06
        emeraldCell.color = CGColor(red: 0.06, green: 0.72, blue: 0.50, alpha: 0.85)
        
        return [oatCell, slateCell, emeraldCell]
    }
    
    static func createStardustDotImage() -> CGImage? {
        let size = CGSize(width: 32, height: 32)
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
        
        let center = CGPoint(x: 16, y: 16)
        let colors = [
            CGColor(red: 1, green: 1, blue: 1, alpha: 1.0),
            CGColor(red: 1, green: 1, blue: 1, alpha: 0.85),
            CGColor(red: 1, green: 1, blue: 1, alpha: 0.30),
            CGColor(red: 1, green: 1, blue: 1, alpha: 0.0)
        ] as CFArray
        let locations: [CGFloat] = [0.0, 0.18, 0.50, 1.0]
        
        guard let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations) else { return nil }
        ctx.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center, endRadius: 16, options: [])
        return ctx.makeImage()
    }
}
