import SwiftUI
import Combine

/// Ambient Session Theme Manager
/// Randomly selects distinct, rich, moody Spotify-grade atmospheric color washes for each tab on every app launch/session.
@MainActor
public final class AmbientSessionTheme: ObservableObject {
    public static let shared = AmbientSessionTheme()
    
    /// Curated palette of deep, moody atmospheric tones (Spotify/Apple HIG Dark Mode)
    public struct AtmosphericTone: Identifiable, Equatable {
        public let id: String
        public let name: String
        public let primaryHex: String
        public let secondaryHex: String
        public let accentOatTint: String
        
        public init(id: String, name: String, primaryHex: String, secondaryHex: String, accentOatTint: String = "#EFE3D3") {
            self.id = id
            self.name = name
            self.primaryHex = primaryHex
            self.secondaryHex = secondaryHex
            self.accentOatTint = accentOatTint
        }
        
        public var primaryColor: Color { Color(hex: primaryHex) }
        public var secondaryColor: Color { Color(hex: secondaryHex) }
    }
    
    public static let curatedTones: [AtmosphericTone] = [
        // 1. Deep Nordic Sapphire (Глубокий сапфировый синий)
        AtmosphericTone(
            id: "sapphire",
            name: "Nordic Sapphire",
            primaryHex: "#1D4ED8",
            secondaryHex: "#1E3A8A"
        ),
        // 2. Midnight Amethyst (Королевский тёмно-фиолетовый)
        AtmosphericTone(
            id: "amethyst",
            name: "Midnight Amethyst",
            primaryHex: "#6D28D9",
            secondaryHex: "#4C1D95"
        ),
        // 3. Mulberry Wine (Глубокий винный / сливовый)
        AtmosphericTone(
            id: "mulberry",
            name: "Mulberry Wine",
            primaryHex: "#831843",
            secondaryHex: "#701A75"
        ),
        // 4. Pine Forest Emerald (Тёмный хвойный изумруд)
        AtmosphericTone(
            id: "emerald",
            name: "Pine Forest Emerald",
            primaryHex: "#047857",
            secondaryHex: "#064E3B"
        ),
        // 5. Burnt Cognac Amber (Тёплый янтарный / жжёный коньяк)
        AtmosphericTone(
            id: "cognac",
            name: "Burnt Cognac",
            primaryHex: "#92400E",
            secondaryHex: "#78350F"
        ),
        // 6. Deep Arctic Teal (Глубокий арктический тил)
        AtmosphericTone(
            id: "teal",
            name: "Arctic Teal",
            primaryHex: "#0F766E",
            secondaryHex: "#115E59"
        ),
        // 7. Electric Indigo (Глубокий космический индиго)
        AtmosphericTone(
            id: "indigo",
            name: "Electric Indigo",
            primaryHex: "#4338CA",
            secondaryHex: "#312E81"
        ),
        // 8. Smoked Petrol Slate (Дымчатый сланец / тёмный графитовый петроль)
        AtmosphericTone(
            id: "slate",
            name: "Petrol Slate",
            primaryHex: "#334155",
            secondaryHex: "#1E293B"
        )
    ]
    
    // Dedicated distinct colors for each tab per session
    @Published public private(set) var homeTone: AtmosphericTone
    @Published public private(set) var searchTone: AtmosphericTone
    @Published public private(set) var libraryTone: AtmosphericTone
    @Published public private(set) var createTone: AtmosphericTone
    @Published public private(set) var activeTone: AtmosphericTone
    
    private init() {
        // Guarantee 4 distinct colors across tabs on every app launch!
        let pool = AmbientSessionTheme.curatedTones.shuffled()
        self.homeTone = pool[0]
        self.searchTone = pool[1]
        self.libraryTone = pool[2]
        self.createTone = pool[3]
        self.activeTone = pool[0]
    }
    
    /// Tone getter by tab
    public func tone(for tab: AppTab) -> AtmosphericTone {
        switch tab {
        case .home: return homeTone
        case .search: return searchTone
        case .library: return libraryTone
        case .create: return createTone
        }
    }
    
    /// Optional manual shuffle
    public func shuffleAllTones() {
        let pool = AmbientSessionTheme.curatedTones.shuffled()
        withAnimation(.easeInOut(duration: 0.6)) {
            self.homeTone = pool[0]
            self.searchTone = pool[1]
            self.libraryTone = pool[2]
            self.createTone = pool[3]
            self.activeTone = pool[0]
        }
    }
}

/// Atmospheric Gradient Wash Background View
/// Renders an organic Spotify-grade color wash from top to bottom into pitch black, specialized per tab.
public struct AmbientWashBackgroundView: View {
    @ObservedObject private var theme = AmbientSessionTheme.shared
    @ObservedObject private var coordinator = ServicesCoordinator.shared
    
    public var tab: AppTab? = nil
    public var customTone: AmbientSessionTheme.AtmosphericTone? = nil
    
    public init(tab: AppTab? = nil, customTone: AmbientSessionTheme.AtmosphericTone? = nil) {
        self.tab = tab
        self.customTone = customTone
    }
    
    private var currentTone: AmbientSessionTheme.AtmosphericTone {
        if let custom = customTone {
            return custom
        }
        if let tab = tab {
            return theme.tone(for: tab)
        }
        return theme.activeTone
    }
    
    public var body: some View {
        ZStack {
            // 1. OLED Cashmere Charcoal Base (#0E0F12)
            PastelTheme.canvas
                .ignoresSafeArea()
            
            // 2. Organic "Stroke / Brush Wash" (Мягкий асимметричный мазок цвета сверху)
            GeometryReader { geo in
                ZStack(alignment: .top) {
                    // Layer A: Asymmetrical Organic Radial Wash (creates the painterly "brush stroke" feel)
                    RadialGradient(
                        colors: [
                            currentTone.primaryColor.opacity(0.48),
                            currentTone.secondaryColor.opacity(0.24),
                            Color.clear
                        ],
                        center: UnitPoint(x: 0.32, y: 0.05),
                        startRadius: 10,
                        endRadius: geo.size.width * 0.95
                    )
                    .frame(height: geo.size.height * 0.65)
                    
                    // Layer B: Subtle Secondary Complementary Glow on top right
                    RadialGradient(
                        colors: [
                            currentTone.secondaryColor.opacity(0.35),
                            Color.clear
                        ],
                        center: UnitPoint(x: 0.85, y: 0.12),
                        startRadius: 20,
                        endRadius: geo.size.width * 0.75
                    )
                    .frame(height: geo.size.height * 0.55)
                    
                    // Layer C: Smooth Vertical Dissolve into pitch black (Top -> Bottom)
                    LinearGradient(
                        stops: [
                            Gradient.Stop(color: currentTone.primaryColor.opacity(0.25), location: 0.0),
                            Gradient.Stop(color: currentTone.primaryColor.opacity(0.12), location: 0.20),
                            Gradient.Stop(color: currentTone.secondaryColor.opacity(0.04), location: 0.38),
                            Gradient.Stop(color: Color.clear, location: 0.55)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: geo.size.height * 0.70)
                }
            }
            .ignoresSafeArea()
            
            if coordinator.backgroundParticlesEnabled {
                CosmicParticleBackgroundView(particleCount: 28, includeCanvasBase: false)
                    .allowsHitTesting(false)
                    .opacity(0.55)
                    .ignoresSafeArea()
            }
        }
    }
}
