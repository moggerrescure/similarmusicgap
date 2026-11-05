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
/// and ultra-fine, quiet micro-stardust particles rendered directly on GPU via CoreAnimation.
public struct CosmicParticleBackgroundView: View {
    @ObservedObject private var coordinator = ServicesCoordinator.shared
    public var particleCount: Int = 30
    
    public init(particleCount: Int = 30) {
        self.particleCount = particleCount
    }
    
    public var body: some View {
        ZStack {
            // 1. OLED Cashmere Deep Canvas (#0E0F12)
            PastelTheme.canvas
            
            // 2. Faint, Quiet Luxury Vignette (No loud colors, strictly elegant Apple dark space)
            RadialGradient(
                colors: [Color(hex: "#14151C").opacity(0.30), Color.clear],
                center: .topTrailing,
                startRadius: 50,
                endRadius: 520
            )
            
            RadialGradient(
                colors: [Color(hex: "#101217").opacity(0.20), Color.clear],
                center: .bottomLeading,
                startRadius: 80,
                endRadius: 600
            )
            
            // 3. Hardware GPU CAEmitterLayer: Ultra-fine, subtle stardust (0% CPU, 120 FPS)
            // Controlled by the user toggle in Profile & Vault
            if coordinator.backgroundParticlesEnabled {
                GPUMicroStardustEmitterRepresentable()
                    .opacity(0.35)
                    .transition(.opacity)
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Native CoreAnimation GPU Micro-Stardust Emitter
#if os(iOS)
private struct GPUMicroStardustEmitterRepresentable: UIViewRepresentable {
    func makeUIView(context: Context) -> MicroEmitterContainerView {
        MicroEmitterContainerView()
    }
    func updateUIView(_ uiView: MicroEmitterContainerView, context: Context) {}
}

private final class MicroEmitterContainerView: UIView {
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
        emitterLayer.emitterPosition = CGPoint(x: bounds.midX, y: -10)
        emitterLayer.emitterSize = CGSize(width: bounds.width * 1.2, height: 10)
    }
    
    private func setupEmitter() {
        backgroundColor = .clear
        emitterLayer.emitterShape = .line
        emitterLayer.renderMode = .additive
        
        let dotImage = createMicroDotImage()
        
        // Soft, quiet Oat micro-points (#EFE3D3)
        let oatCell = CAEmitterCell()
        oatCell.contents = dotImage
        oatCell.birthRate = 4
        oatCell.lifetime = 18
        oatCell.velocity = 12
        oatCell.velocityRange = 6
        oatCell.emissionLongitude = .pi // Falling gently down
        oatCell.emissionRange = .pi / 12
        oatCell.scale = 0.12
        oatCell.scaleRange = 0.08
        oatCell.alphaSpeed = -0.04
        oatCell.color = UIColor(red: 0.94, green: 0.89, blue: 0.83, alpha: 0.60).cgColor
        
        // Faint Slate micro-dust
        let slateCell = CAEmitterCell()
        slateCell.contents = dotImage
        slateCell.birthRate = 2.5
        slateCell.lifetime = 22
        slateCell.velocity = 10
        slateCell.velocityRange = 4
        slateCell.emissionLongitude = .pi
        slateCell.emissionRange = .pi / 8
        slateCell.scale = 0.09
        slateCell.scaleRange = 0.06
        slateCell.alphaSpeed = -0.03
        slateCell.color = UIColor(red: 0.60, green: 0.70, blue: 0.85, alpha: 0.40).cgColor
        
        emitterLayer.emitterCells = [oatCell, slateCell]
        layer.addSublayer(emitterLayer)
    }
    
    private func createMicroDotImage() -> CGImage? {
        let size = CGSize(width: 8, height: 8)
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        guard let ctx = UIGraphicsGetCurrentContext() else { return nil }
        
        let colors = [UIColor.white.cgColor, UIColor.white.withAlphaComponent(0.0).cgColor]
        let locations: [CGFloat] = [0.0, 1.0]
        guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: locations) else { return nil }
        
        ctx.drawRadialGradient(gradient, startCenter: CGPoint(x: 4, y: 4), startRadius: 0, endCenter: CGPoint(x: 4, y: 4), endRadius: 4, options: [])
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img?.cgImage
    }
}
#else
// MARK: - macOS NSView CoreAnimation Micro-Stardust Emitter
private struct GPUMicroStardustEmitterRepresentable: NSViewRepresentable {
    func makeNSView(context: Context) -> MicroEmitterContainerView {
        MicroEmitterContainerView()
    }
    func updateNSView(_ nsView: MicroEmitterContainerView, context: Context) {}
}

private final class MicroEmitterContainerView: NSView {
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
        emitterLayer.emitterPosition = CGPoint(x: bounds.midX, y: bounds.height + 10)
        emitterLayer.emitterSize = CGSize(width: bounds.width * 1.2, height: 10)
    }
    
    private func setupEmitter() {
        emitterLayer.emitterShape = .line
        emitterLayer.renderMode = .additive
        
        let dotImage = createMicroDotImage()
        
        // Soft, quiet Oat micro-points (#EFE3D3)
        let oatCell = CAEmitterCell()
        oatCell.contents = dotImage
        oatCell.birthRate = 4
        oatCell.lifetime = 18
        oatCell.velocity = 12
        oatCell.velocityRange = 6
        oatCell.emissionLongitude = -.pi / 2
        oatCell.emissionRange = .pi / 12
        oatCell.scale = 0.12
        oatCell.scaleRange = 0.08
        oatCell.alphaSpeed = -0.04
        oatCell.color = CGColor(red: 0.94, green: 0.89, blue: 0.83, alpha: 0.60)
        
        // Faint Slate micro-dust
        let slateCell = CAEmitterCell()
        slateCell.contents = dotImage
        slateCell.birthRate = 2.5
        slateCell.lifetime = 22
        slateCell.velocity = 10
        slateCell.velocityRange = 4
        slateCell.emissionLongitude = -.pi / 2
        slateCell.emissionRange = .pi / 8
        slateCell.scale = 0.09
        slateCell.scaleRange = 0.06
        slateCell.alphaSpeed = -0.03
        slateCell.color = CGColor(red: 0.60, green: 0.70, blue: 0.85, alpha: 0.40)
        
        emitterLayer.emitterCells = [oatCell, slateCell]
        layer?.addSublayer(emitterLayer)
    }
    
    private func createMicroDotImage() -> CGImage? {
        let size = CGSize(width: 8, height: 8)
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
        
        ctx.drawRadialGradient(gradient, startCenter: CGPoint(x: 4, y: 4), startRadius: 0, endCenter: CGPoint(x: 4, y: 4), endRadius: 4, options: [])
        return ctx.makeImage()
    }
}
#endif
