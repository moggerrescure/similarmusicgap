import SwiftUI

/// Luxury Athletic / Health HUD Design Tokens (Strict Dark Mode)
public enum PastelTheme {
    // MARK: - Surfaces & Backgrounds
    /// OLED Cashmere Charcoal background
    public static let canvas = Color(hex: "#0E0F12")
    /// Deep Matte Graphite card surface
    public static let card = Color(hex: "#17181D")
    /// Recessed wells, chips, and icon backgrounds
    public static let cardSubtle = Color(hex: "#121317")
    
    // MARK: - Borders & Hairlines
    /// Warm, noble hairline border (18% opacity)
    public static let cardBorder = Color(hex: "#EFE3D3").opacity(0.18)
    /// Focused or active state border (42% opacity)
    public static let cardBorderFocused = Color(hex: "#EFE3D3").opacity(0.42)
    
    // MARK: - Primary Action (CTA)
    /// Warm Oat Beige fill for primary buttons
    public static let pastelOat = Color(hex: "#EFE3D3")
    /// High-contrast text on primary Oat button
    public static let textOnOat = Color(hex: "#0E0F12")
    
    // MARK: - Functional Accents
    /// 100% precision match, sync completed, PR
    public static let emeraldSuccess = Color(hex: "#10B981")
    /// Partial match, active transfer, streaks
    public static let amberWarning = Color(hex: "#FBBF24")
    /// Duration, metadata, streaming bitrate
    public static let slateBlue = Color(hex: "#60A5FA")
    /// AI Taste profile, acoustic embeddings
    public static let lavenderAI = Color(hex: "#A78BFA")
    
    // MARK: - Typography Colors
    public static let textPrimary = Color.white
    public static let textSecondary = Color(hex: "#9CA3AF")
    public static let textTertiary = Color(hex: "#6B7280")
}

// MARK: - Color Hex Initializer
public extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Tactile Haptic Manager
public enum HapticManager {
    public static func lightImpact() {
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
        #endif
    }
    
    public static func mediumImpact() {
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
        #endif
    }
    
    public static func successNotification() {
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
        #endif
    }
}

// MARK: - Spring Physics Button Style (Emil Kowalski Philosophy)
public struct TouchFeedbackButtonStyle: ButtonStyle {
    public init() {}
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    HapticManager.lightImpact()
                }
            }
    }
}

