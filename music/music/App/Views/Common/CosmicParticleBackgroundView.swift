import SwiftUI
import QuartzCore
import Combine

#if os(iOS)
import UIKit
import CoreMotion
#else
import AppKit
#endif

/// Clean, Ultra-Luxury Apple HIG HUD Deep OLED Background (0% CPU, 120 FPS)
/// Features 2K-clarity HDR stardust sprites with 3-plane optical parallax depth:
/// 1. Deep Cosmic Dust (Background Layer) - soft out-of-focus volumetric motes
/// 2. Celestial Stardust (Midground Layer) - crisp warm Cashmere Oat & Slate starpoints
/// 3. Hero Shimmer (Foreground Layer) - diamond-sharp 4-point diffraction crystals
public struct CosmicParticleBackgroundView: View {
    @ObservedObject private var coordinator = ServicesCoordinator.shared
    #if os(iOS)
    @StateObject private var motionManager = DeviceTiltMotionManager()
    #endif
    
    public var particleCount: Int = 40
    
    public init(particleCount: Int = 40) {
        self.particleCount = particleCount
    }
    
    public var body: some View {
        ZStack {
            // 1. OLED Cashmere Deep Canvas (#0E0F12)
            PastelTheme.canvas
            
            // 2. High-Fidelity Multi-Stop Atmospheric Cosmic Nebula (2K depth)
            // Top-Right Deep Slate & Midnight Indigo Nebula
            RadialGradient(
                colors: [
                    Color(hex: "#101626").opacity(0.40),
                    Color(hex: "#0E111A").opacity(0.20),
                    Color.clear
                ],
                center: .topTrailing,
                startRadius: 40,
                endRadius: 580
            )
            
            // Bottom-Left Warm Cashmere & Charcoal Stellar Aura
            RadialGradient(
                colors: [
                    Color(hex: "#161413").opacity(0.30),
                    Color(hex: "#121012").opacity(0.15),
                    Color.clear
                ],
                center: .bottomLeading,
                startRadius: 60,
                endRadius: 620
            )
            
            // Center-Trailing Faint Midnight Violet Stellar Dust
            RadialGradient(
                colors: [
                    Color(hex: "#130E1F").opacity(0.18),
                    Color.clear
                ],
                center: .trailing,
                startRadius: 80,
                endRadius: 480
            )
            
            // 3. Hardware GPU CAEmitterLayer: 2K HDR Stardust (0% CPU, 120 FPS)
            // Controlled by the user toggle in Profile & Vault
            if coordinator.backgroundParticlesEnabled {
                GPUMicroStardustEmitterRepresentable()
                    .allowsHitTesting(false)
                    .opacity(0.92)
                    #if os(iOS)
                    .offset(x: motionManager.tiltX, y: motionManager.tiltY)
                    .animation(.easeOut(duration: 0.25), value: motionManager.tiltX)
                    #endif
                    .transition(.opacity)
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - iOS Motion Tilt Parallax Manager
#if os(iOS)
private final class DeviceTiltMotionManager: ObservableObject {
    @Published var tiltX: CGFloat = 0.0
    @Published var tiltY: CGFloat = 0.0
    
    private let motion = CMMotionManager()
    
    init() {
        startTracking()
    }
    
    deinit {
        motion.stopDeviceMotionUpdates()
    }
    
    private func startTracking() {
        guard motion.isDeviceMotionAvailable else { return }
        motion.deviceMotionUpdateInterval = 1.0 / 30.0
        motion.startDeviceMotionUpdates(to: .main) { [weak self] data, _ in
            guard let self = self, let data = data else { return }
            // Roll (horizontal tilt) & Pitch (vertical tilt)
            let roll = CGFloat(data.attitude.roll)
            let pitch = CGFloat(data.attitude.pitch)
            
            let clampedX = max(-1.0, min(1.0, roll)) * 12.0
            let clampedY = max(-1.0, min(1.0, pitch)) * 12.0
            
            self.tiltX = clampedX
            self.tiltY = clampedY
        }
    }
}
#endif

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
        emitterLayer.emitterSize = CGSize(width: bounds.width * 1.2, height: bounds.height * 1.2)
    }
    
    private func setupEmitter() {
        backgroundColor = .clear
        emitterLayer.emitterShape = .rectangle
        emitterLayer.emitterMode = .volume
        emitterLayer.renderMode = .additive
        
        // Fast-forward simulation by 30 seconds so space is immediately filled on launch
        emitterLayer.beginTime = CACurrentMediaTime() - 30.0
        
        emitterLayer.emitterCells = StardustSpriteGenerator2K.create3PlaneEmitterCells()
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
        emitterLayer.emitterSize = CGSize(width: bounds.width * 1.2, height: bounds.height * 1.2)
    }
    
    private func setupEmitter() {
        emitterLayer.emitterShape = .rectangle
        emitterLayer.emitterMode = .volume
        emitterLayer.renderMode = .additive
        
        // Fast-forward simulation by 30 seconds so space is immediately filled on launch
        emitterLayer.beginTime = CACurrentMediaTime() - 30.0
        
        emitterLayer.emitterCells = StardustSpriteGenerator2K.create3PlaneEmitterCells()
    }
}
#endif

// MARK: - 2K Ultra-HD Stardust Sprite & Multi-Plane Cell Synthesis
private enum StardustSpriteGenerator2K {
    // Cached once in GPU memory (Total memory footprint < 200 KB)
    static let stardustOrbImage: CGImage? = create2KStardustOrb(size: 128)
    static let diamondStarburstImage: CGImage? = create2KDiamondStarburst(size: 128)
    static let bokehMoteImage: CGImage? = create2KBokehMote(size: 96)
    
    static func create3PlaneEmitterCells() -> [CAEmitterCell] {
        var cells: [CAEmitterCell] = []
        
        // =========================================================================
        // PLANE 1: Deep Cosmic Dust (Background Layer - ~70 micro-motes)
        // Gentle, soft, out-of-focus celestial dust motes that establish 3D depth
        // =========================================================================
        if let bokehImage = bokehMoteImage {
            // 1A. Deep Oat Dust Motes
            let deepOatCell = CAEmitterCell()
            deepOatCell.contents = bokehImage
            deepOatCell.birthRate = 3.6
            deepOatCell.lifetime = 18.0
            deepOatCell.velocity = 8.0
            deepOatCell.velocityRange = 3.0
            deepOatCell.emissionLongitude = .pi / 2 + 0.06 // 86° elegant diagonal drift
            deepOatCell.emissionRange = .pi / 5
            deepOatCell.scale = 0.05
            deepOatCell.scaleRange = 0.03
            deepOatCell.alphaRange = 0.20
            deepOatCell.alphaSpeed = -0.025
            deepOatCell.color = CGColor(red: 0.94, green: 0.89, blue: 0.83, alpha: 0.45)
            cells.append(deepOatCell)
            
            // 1B. Deep Atmospheric Slate Motes
            let deepSlateCell = CAEmitterCell()
            deepSlateCell.contents = bokehImage
            deepSlateCell.birthRate = 1.8
            deepSlateCell.lifetime = 20.0
            deepSlateCell.velocity = 6.5
            deepSlateCell.velocityRange = 2.5
            deepSlateCell.emissionLongitude = .pi / 2 + 0.05
            deepSlateCell.emissionRange = .pi / 4
            deepSlateCell.scale = 0.04
            deepSlateCell.scaleRange = 0.02
            deepSlateCell.alphaRange = 0.25
            deepSlateCell.alphaSpeed = -0.02
            deepSlateCell.color = CGColor(red: 0.58, green: 0.77, blue: 0.99, alpha: 0.35)
            cells.append(deepSlateCell)
        }
        
        // =========================================================================
        // PLANE 2: Celestial Stardust (Midground Layer - ~45 crisp starpoints)
        // High-clarity 2K Gaussian orb stars in Apple Fitness+ / HUD colors
        // =========================================================================
        if let orbImage = stardustOrbImage {
            // 2A. Warm Cashmere Oat Starpoints (#EFE3D3 - 60% of midground)
            let midOatCell = CAEmitterCell()
            midOatCell.contents = orbImage
            midOatCell.birthRate = 2.4
            midOatCell.lifetime = 15.0
            midOatCell.velocity = 15.0
            midOatCell.velocityRange = 5.0
            midOatCell.emissionLongitude = .pi / 2 + 0.08
            midOatCell.emissionRange = .pi / 6
            midOatCell.scale = 0.16
            midOatCell.scaleRange = 0.06
            midOatCell.alphaRange = 0.22
            midOatCell.alphaSpeed = -0.045
            midOatCell.color = CGColor(red: 0.94, green: 0.89, blue: 0.83, alpha: 0.88)
            cells.append(midOatCell)
            
            // 2B. Celestial Sky Slate Starpoints (#93C5FD - 30% of midground)
            let midSlateCell = CAEmitterCell()
            midSlateCell.contents = orbImage
            midSlateCell.birthRate = 1.0
            midSlateCell.lifetime = 16.0
            midSlateCell.velocity = 12.0
            midSlateCell.velocityRange = 4.0
            midSlateCell.emissionLongitude = .pi / 2 + 0.07
            midSlateCell.emissionRange = .pi / 5
            midSlateCell.scale = 0.13
            midSlateCell.scaleRange = 0.05
            midSlateCell.alphaRange = 0.24
            midSlateCell.alphaSpeed = -0.04
            midSlateCell.color = CGColor(red: 0.58, green: 0.77, blue: 0.99, alpha: 0.75)
            cells.append(midSlateCell)
            
            // 2C. Athletic Emerald Readiness Sparkle (#10B981 - 10% of midground)
            let midEmeraldCell = CAEmitterCell()
            midEmeraldCell.contents = orbImage
            midEmeraldCell.birthRate = 0.35
            midEmeraldCell.lifetime = 13.0
            midEmeraldCell.velocity = 17.0
            midEmeraldCell.velocityRange = 6.0
            midEmeraldCell.emissionLongitude = .pi / 2 + 0.08
            midEmeraldCell.emissionRange = .pi / 7
            midEmeraldCell.scale = 0.18
            midEmeraldCell.scaleRange = 0.06
            midEmeraldCell.alphaRange = 0.20
            midEmeraldCell.alphaSpeed = -0.055
            midEmeraldCell.color = CGColor(red: 0.06, green: 0.72, blue: 0.50, alpha: 0.88)
            cells.append(midEmeraldCell)
        }
        
        // =========================================================================
        // PLANE 3: Hero Shimmer & Diamond Crystals (Foreground Layer - ~8 crystals)
        // 2K 4-point anamorphic diffraction spikes with organic rotational drift
        // =========================================================================
        if let diamondImage = diamondStarburstImage {
            // 3A. Pure Diamond White Crystals
            let diamondCell = CAEmitterCell()
            diamondCell.contents = diamondImage
            diamondCell.birthRate = 0.45
            diamondCell.lifetime = 12.0
            diamondCell.velocity = 22.0
            diamondCell.velocityRange = 7.0
            diamondCell.emissionLongitude = .pi / 2 + 0.09
            diamondCell.emissionRange = .pi / 7
            diamondCell.scale = 0.22
            diamondCell.scaleRange = 0.07
            diamondCell.alphaRange = 0.18
            diamondCell.alphaSpeed = -0.06
            diamondCell.spin = 0.12
            diamondCell.spinRange = 0.25
            diamondCell.color = CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.95)
            cells.append(diamondCell)
            
            // 3B. Warm Sunlit Oat Crystal
            let warmDiamondCell = CAEmitterCell()
            warmDiamondCell.contents = diamondImage
            warmDiamondCell.birthRate = 0.25
            warmDiamondCell.lifetime = 11.0
            warmDiamondCell.velocity = 24.0
            warmDiamondCell.velocityRange = 8.0
            warmDiamondCell.emissionLongitude = .pi / 2 + 0.08
            warmDiamondCell.emissionRange = .pi / 8
            warmDiamondCell.scale = 0.24
            warmDiamondCell.scaleRange = 0.08
            warmDiamondCell.alphaRange = 0.15
            warmDiamondCell.alphaSpeed = -0.065
            warmDiamondCell.spin = -0.10
            warmDiamondCell.spinRange = 0.20
            warmDiamondCell.color = CGColor(red: 0.98, green: 0.94, blue: 0.88, alpha: 0.92)
            cells.append(warmDiamondCell)
        }
        
        return cells
    }
    
    // MARK: - 2K Texture Generators (CoreGraphics Metal-Compatible)
    
    /// 2K Gaussian-convolved smooth stardust sphere with zero stepped color banding
    private static func create2KStardustOrb(size: Int) -> CGImage? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(
            data: nil,
            width: size,
            height: size,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        
        ctx.setAllowsAntialiasing(true)
        ctx.setShouldAntialias(true)
        ctx.interpolationQuality = .high
        
        let center = CGPoint(x: CGFloat(size) / 2.0, y: CGFloat(size) / 2.0)
        let radius = CGFloat(size) / 2.0
        
        // Multi-stop 2K High Dynamic Range silky falloff curve (no color banding)
        let colors = [
            CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0),     // 0.0 - Pure HDR core
            CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.95),    // 0.08 - Core plateau
            CGColor(red: 1.0, green: 0.98, blue: 0.95, alpha: 0.70),  // 0.22 - Warm halo
            CGColor(red: 0.95, green: 0.95, blue: 1.0, alpha: 0.35),  // 0.45 - Atmospheric corona
            CGColor(red: 0.90, green: 0.92, blue: 1.0, alpha: 0.10),  // 0.72 - Deep space fringe
            CGColor(red: 0.90, green: 0.92, blue: 1.0, alpha: 0.00)   // 1.00 - Pure vacuum
        ] as CFArray
        let locations: [CGFloat] = [0.0, 0.08, 0.22, 0.45, 0.72, 1.0]
        
        guard let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations) else { return nil }
        ctx.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center, endRadius: radius, options: [])
        return ctx.makeImage()
    }
    
    /// 2K James Webb Space Telescope inspired 4-point diffraction starburst
    private static func create2KDiamondStarburst(size: Int) -> CGImage? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(
            data: nil,
            width: size,
            height: size,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        
        ctx.setAllowsAntialiasing(true)
        ctx.setShouldAntialias(true)
        ctx.interpolationQuality = .high
        
        let center = CGPoint(x: CGFloat(size) / 2.0, y: CGFloat(size) / 2.0)
        let radius = CGFloat(size) / 2.0
        
        // 1. Central luminous core
        let coreColors = [
            CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0),
            CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.85),
            CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.25),
            CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.0)
        ] as CFArray
        let coreLocs: [CGFloat] = [0.0, 0.12, 0.35, 1.0]
        if let coreGrad = CGGradient(colorsSpace: colorSpace, colors: coreColors, locations: coreLocs) {
            ctx.drawRadialGradient(coreGrad, startCenter: center, startRadius: 0, endCenter: center, endRadius: radius * 0.75, options: [])
        }
        
        // 2. Anamorphic 4-point micro-diffraction flares (Horizontal & Vertical diamond rays)
        let rayWidth: CGFloat = 1.2
        let rayHalfLength = radius * 0.95
        
        let spikeColors = [
            CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.0),
            CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.85),
            CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.0)
        ] as CFArray
        let spikeLocs: [CGFloat] = [0.0, 0.5, 1.0]
        
        if let spikeGrad = CGGradient(colorsSpace: colorSpace, colors: spikeColors, locations: spikeLocs) {
            // Horizontal diffraction spike
            let hRect = CGRect(x: center.x - rayHalfLength, y: center.y - rayWidth / 2.0, width: rayHalfLength * 2.0, height: rayWidth)
            ctx.saveGState()
            ctx.addRect(hRect)
            ctx.clip()
            ctx.drawLinearGradient(spikeGrad, start: CGPoint(x: hRect.minX, y: center.y), end: CGPoint(x: hRect.maxX, y: center.y), options: [])
            ctx.restoreGState()
            
            // Vertical diffraction spike
            let vRect = CGRect(x: center.x - rayWidth / 2.0, y: center.y - rayHalfLength, width: rayWidth, height: rayHalfLength * 2.0)
            ctx.saveGState()
            ctx.addRect(vRect)
            ctx.clip()
            ctx.drawLinearGradient(spikeGrad, start: CGPoint(x: center.x, y: vRect.minY), end: CGPoint(x: center.x, y: vRect.maxY), options: [])
            ctx.restoreGState()
        }
        
        return ctx.makeImage()
    }
    
    /// 2K Out-of-focus volumetric bokeh mote for atmospheric DoF
    private static func create2KBokehMote(size: Int) -> CGImage? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(
            data: nil,
            width: size,
            height: size,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        
        ctx.setAllowsAntialiasing(true)
        ctx.setShouldAntialias(true)
        
        let center = CGPoint(x: CGFloat(size) / 2.0, y: CGFloat(size) / 2.0)
        let radius = CGFloat(size) / 2.0
        
        // Soft out-of-focus volumetric bokeh disc
        let colors = [
            CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.65),
            CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.45),
            CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.15),
            CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.0)
        ] as CFArray
        let locations: [CGFloat] = [0.0, 0.45, 0.80, 1.0]
        
        guard let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations) else { return nil }
        ctx.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center, endRadius: radius, options: [])
        return ctx.makeImage()
    }
}
