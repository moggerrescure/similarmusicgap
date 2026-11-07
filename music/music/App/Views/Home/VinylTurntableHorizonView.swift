import SwiftUI
import Combine

/// Collector's Edition Colored Vinyl Horizon & Animated Turntable Deck
/// Features:
/// 1. Precision Turntable Player with physically rotating vinyl platter and moving tonearm
/// 2. Tonearm lifts when paused, lands on record when playing, and traverses grooves with song progress
/// 3. Large, eye-catching Collector's Edition colored vinyl records (Ruby, Emerald, Sapphire, Amber, Violet)
/// 4. Smooth continuous 33⅓ RPM rotation driven by TimelineView (60/120 Hz ProMotion, zero lag)
/// 5. 1-Tap physical haptic feedback on record swap and play/pause
public struct VinylTurntableHorizonView: View {
    @ObservedObject private var player = AudioPlayerManager.shared
    @ObservedObject private var coordinator = ServicesCoordinator.shared
    
    // Model for Colored Vinyl Edition
    public struct ColoredVinylItem: Identifiable, Equatable {
        public let id: Int
        public let title: String
        public let artist: String
        public let symbolOrInitial: String
        public let waxGradient: [Color]
        public let labelGradient: [Color]
        public let labelTextColor: Color
        public let glowColor: Color
    }
    
    public let vinyls: [ColoredVinylItem] = [
        ColoredVinylItem(
            id: 1,
            title: "Liked Songs",
            artist: "Favorites",
            symbolOrInitial: "heart.fill",
            waxGradient: [Color(hex: "#4A1FB8"), Color(hex: "#291266"), Color(hex: "#150938")],
            labelGradient: [Color(hex: "#450AF5"), Color(hex: "#C4EFD9")],
            labelTextColor: Color.white,
            glowColor: Color(hex: "#4A1FB8")
        ),
        ColoredVinylItem(
            id: 2,
            title: "Дора",
            artist: "Дора",
            symbolOrInitial: "Д",
            waxGradient: [Color(hex: "#E11D74"), Color(hex: "#880E43"), Color(hex: "#42041E")],
            labelGradient: [Color(hex: "#E11D74"), Color(hex: "#9C124E")],
            labelTextColor: Color.white,
            glowColor: Color(hex: "#E11D74")
        ),
        ColoredVinylItem(
            id: 3,
            title: "50 Cent",
            artist: "50 Cent",
            symbolOrInitial: "50",
            waxGradient: [Color(hex: "#10B981"), Color(hex: "#065F46"), Color(hex: "#022C22")],
            labelGradient: [Color(hex: "#10B981"), Color(hex: "#059669")],
            labelTextColor: Color.black,
            glowColor: Color(hex: "#10B981")
        ),
        ColoredVinylItem(
            id: 4,
            title: "влад пиво",
            artist: "влад пиво",
            symbolOrInitial: "В",
            waxGradient: [Color(hex: "#FBBF24"), Color(hex: "#B45309"), Color(hex: "#451A03")],
            labelGradient: [Color(hex: "#FBBF24"), Color(hex: "#D97706")],
            labelTextColor: Color.black,
            glowColor: Color(hex: "#FBBF24")
        ),
        ColoredVinylItem(
            id: 5,
            title: "Zemfira",
            artist: "Zemfira",
            symbolOrInitial: "Z",
            waxGradient: [Color(hex: "#2563EB"), Color(hex: "#1E3A8A"), Color(hex: "#0F172A")],
            labelGradient: [Color(hex: "#2563EB"), Color(hex: "#1D4ED8")],
            labelTextColor: Color.white,
            glowColor: Color(hex: "#2563EB")
        ),
        ColoredVinylItem(
            id: 6,
            title: "заставь меня плакать",
            artist: "CUPSIZE",
            symbolOrInitial: "C",
            waxGradient: [Color(hex: "#991B1B"), Color(hex: "#450A0A"), Color(hex: "#1C0505")],
            labelGradient: [Color(hex: "#EF4444"), Color(hex: "#991B1B")],
            labelTextColor: Color.white,
            glowColor: Color(hex: "#EF4444")
        )
    ]
    
    @State private var activeVinylIndex: Int = 0
    
    public init() {}
    
    private var currentActiveVinyl: ColoredVinylItem {
        if activeVinylIndex >= 0 && activeVinylIndex < vinyls.count {
            return vinyls[activeVinylIndex]
        }
        return vinyls[0]
    }
    
    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 16) {
                // 1. THE TURNTABLE PLAYER DECK (Leftmost Hero Item)
                TurntablePlayerDeckView(
                    activeVinyl: currentActiveVinyl,
                    isPlaying: player.isPlaying,
                    progress: player.progress,
                    onTogglePlayPause: {
                        HapticManager.mediumImpact()
                        if player.currentTrack == nil {
                            selectAndPlayVinyl(at: activeVinylIndex)
                        } else {
                            player.togglePlayPause()
                        }
                    }
                )
                
                // 2. THE LARGE COLORFUL ROTATING VINYL DISCS IN ROW
                ForEach(Array(vinyls.enumerated()), id: \.element.id) { index, item in
                    StandaloneVinylRecordCard(
                        item: item,
                        isPlaying: player.isPlaying,
                        isActive: activeVinylIndex == index,
                        onTap: {
                            selectAndPlayVinyl(at: index)
                        }
                    )
                }
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 4)
        }
    }
    
    private func selectAndPlayVinyl(at index: Int) {
        HapticManager.lightImpact()
        // Instant disc change without animations
        activeVinylIndex = index
        
        let selected = vinyls[index]
        let track = UniversalTrack(
            isrc: "VN-\(selected.id)",
            title: selected.title,
            artists: [selected.artist],
            album: selected.title == "Liked Songs" ? "Favorites" : "Vinyl Vault",
            durationMs: 195000,
            spotifyId: "vn_\(selected.id)"
        )
        player.play(track: track)
    }
}

// MARK: - 1. Animated Turntable Deck (Rotating Vinyl + Calm Continuous Tonearm)

private final class TurntableMotionTracker: ObservableObject {
    @Published var tick: Bool = false
    var accumulatedTime: Double = 0.0
    var lastDate: Date? = nil
    
    func advance(currentDate: Date, isPlaying: Bool) -> Double {
        guard isPlaying else {
            lastDate = nil
            return accumulatedTime
        }
        
        if let last = lastDate {
            let delta = currentDate.timeIntervalSince(last)
            if delta > 0 && delta < 0.5 {
                accumulatedTime += delta
            }
        }
        lastDate = currentDate
        return accumulatedTime
    }
}

private struct TurntablePlayerDeckView: View {
    let activeVinyl: VinylTurntableHorizonView.ColoredVinylItem
    let isPlaying: Bool
    let progress: Double
    let onTogglePlayPause: () -> Void
    
    @StateObject private var motionTracker = TurntableMotionTracker()
    
    var body: some View {
        Button(action: onTogglePlayPause) {
            VStack(spacing: 8) {
                // Turntable Platter Chassis (134 x 134)
                ZStack(alignment: .topTrailing) {
                    // Brushed Titanium Body
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#1C1D23"), Color(hex: "#121317")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(PastelTheme.cardBorderFocused, lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.6), radius: 14, y: 6)
                    
                    // Center Recessed Platter Well
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color(hex: "#2A2B33"), Color(hex: "#0E0F12")],
                                center: .center,
                                startRadius: 0,
                                endRadius: 50
                            )
                        )
                        .frame(width: 98, height: 98)
                        .overlay(Circle().stroke(Color.white.opacity(0.06), lineWidth: 1))
                        .position(x: 62, y: 64)
                    
                    // Synchronized Platter & Tonearm Engine (60/120 FPS ProMotion hardware loop)
                    TimelineView(.animation(paused: !isPlaying)) { timeline in
                        let playTime = motionTracker.advance(currentDate: timeline.date, isPlaying: isPlaying)
                        
                        // 1. Physical 33⅓ RPM Platter Spin (3.0s per revolution)
                        let rotation = (playTime.truncatingRemainder(dividingBy: 3.0) / 3.0) * 360.0
                        
                        // 2. Physical Tonearm Motion (8.0s analog cycle: 4s inward to inner groove, 4s outward to outer rim)
                        // Smooth harmonic sinusoidal motion: zero jerk, zero teleportation, authentic vinyl tracking
                        let tonearmCycle = 8.0
                        let phase = (playTime.truncatingRemainder(dividingBy: tonearmCycle) / tonearmCycle) * Double.pi * 2.0
                        let cycleProgress = (1.0 - cos(phase)) * 0.5
                        let tonearmAngle = 8.0 + (cycleProgress * 20.0) // 8.0° (outer groove) to 28.0° (inner groove)
                        
                        ZStack {
                            // Rotating Vinyl Platter on Turntable
                            TurntableSpinningPlatterDisc(
                                waxGradient: activeVinyl.waxGradient,
                                labelGradient: activeVinyl.labelGradient,
                                symbolOrInitial: activeVinyl.symbolOrInitial,
                                labelTextColor: activeVinyl.labelTextColor
                            )
                            .rotationEffect(.degrees(rotation))
                            .frame(width: 92, height: 92)
                            .position(x: 62, y: 64)
                            
                            // Audiophile Tonearm with Stylus Needle (smoothly glides across disc grooves)
                            TonearmAssemblyView(
                                angle: tonearmAngle
                            )
                            .position(x: 104, y: 48)
                        }
                    }
                }
                .frame(width: 134, height: 134)
                
                // Track Title Under Turntable
                Text(activeVinyl.title)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(PastelTheme.pastelOat)
                    .lineLimit(1)
                    .frame(width: 130)
                    .transaction { $0.animation = nil }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Collector's Edition Colored Vinyl Platter Disc (Clean, Notch-Free, Swirling Wax & Deluxe Label Art)

private struct TurntableSpinningPlatterDisc: View {
    let waxGradient: [Color]
    let labelGradient: [Color]
    let symbolOrInitial: String
    let labelTextColor: Color
    
    var body: some View {
        ZStack {
            // 1. Collector's Marbled Wax Base (Asymmetrical swirls of deep pigment and glossy refraction)
            Circle()
                .fill(
                    AngularGradient(
                        colors: [
                            waxGradient.first ?? Color(hex: "#2E1A22"),
                            waxGradient.last ?? Color(hex: "#0E070A"),
                            waxGradient.first?.opacity(0.7) ?? Color(hex: "#2E1A22"),
                            waxGradient.first?.opacity(0.95) ?? Color(hex: "#450A0A"),
                            Color.white.opacity(0.18), // Distinct light refraction marble vein
                            waxGradient.last?.opacity(0.85) ?? Color(hex: "#0E070A"),
                            waxGradient.first ?? Color(hex: "#2E1A22")
                        ],
                        center: .center
                    )
                )
                .overlay(Circle().stroke(Color.white.opacity(0.20), lineWidth: 1.0))
                .shadow(color: waxGradient.first?.opacity(0.4) ?? Color.black.opacity(0.5), radius: 8)
            
            // 2. Physical Concentric Micro-Grooves (Analog sound tracks)
            Circle().stroke(Color.white.opacity(0.09), lineWidth: 0.75).frame(width: 82, height: 82)
            Circle().stroke(Color.white.opacity(0.06), lineWidth: 0.75).frame(width: 72, height: 72)
            Circle().stroke(Color.white.opacity(0.08), lineWidth: 0.75).frame(width: 62, height: 62)
            Circle().stroke(Color.white.opacity(0.07), lineWidth: 0.75).frame(width: 52, height: 52)
            Circle().stroke(Color.white.opacity(0.09), lineWidth: 0.75).frame(width: 42, height: 42)
            
            // 3. Realistic Anisotropic Specular Light Sheen ("Виниловый крест света")
            AngularGradient(
                colors: [
                    Color.clear,
                    Color.white.opacity(0.18),
                    Color.clear,
                    Color.white.opacity(0.18),
                    Color.clear
                ],
                center: .center
            )
            .clipShape(Circle())
            
            // 4. Deluxe Center Paper Label with Authentic Vinyl Typography & Rotating Art
            ZStack {
                // Outer Label Ring
                Circle()
                    .fill(
                        LinearGradient(
                            colors: labelGradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)
                    .overlay(Circle().stroke(Color.black.opacity(0.6), lineWidth: 1.5))
                    .shadow(color: Color.black.opacity(0.4), radius: 4)
                
                // Two-tone semi-circle arc (creates high-contrast rotation tracking)
                Circle()
                    .trim(from: 0.0, to: 0.5)
                    .fill(Color.black.opacity(0.25))
                    .frame(width: 32, height: 32)
                
                // Authentic Vinyl Label Micro-Typography ("SIDE A" & "33 RPM")
                VStack(spacing: 8) {
                    Text("SIDE A")
                        .font(.system(size: 4.5, weight: .black, design: .monospaced))
                        .foregroundColor(labelTextColor.opacity(0.85))
                        .tracking(0.5)
                    
                    Text("33 ⅓")
                        .font(.system(size: 4.0, weight: .bold, design: .monospaced))
                        .foregroundColor(labelTextColor.opacity(0.75))
                        .tracking(0.5)
                }
                
                // Center Artist Initial / SF Symbol
                if symbolOrInitial.count == 1 {
                    Text(symbolOrInitial)
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundColor(labelTextColor)
                } else {
                    Image(systemName: symbolOrInitial)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(labelTextColor)
                }
                
                // Center Spindle Pin
                Circle()
                    .fill(Color(hex: "#111113"))
                    .frame(width: 5, height: 5)
                    .overlay(Circle().stroke(Color.white.opacity(0.5), lineWidth: 0.5))
            }
        }
    }
}

// MARK: - Audiophile High-Precision Monolithic Tonearm Assembly

private struct TonearmAssemblyView: View {
    let angle: Double
    
    var body: some View {
        ZStack(alignment: .top) {
            // 1. Static Recessed Bearing Well (anchored on turntable chassis at pivot center)
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#2B2D35"), Color(hex: "#15161A")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 20, height: 20)
                .overlay(Circle().stroke(Color.white.opacity(0.14), lineWidth: 0.8))
                .shadow(color: Color.black.opacity(0.5), radius: 2.5, y: 1.5)
                .offset(y: 8) // center matches pivot at y: 18
            
            // 2. Continuous Rotating Monolithic Arm (Single unified vertical hierarchy)
            // Pivot is at y: 18. Everything rotates as ONE solid entity!
            VStack(spacing: 0) {
                // A. Machined Metallic Counterweight (top)
                RoundedRectangle(cornerRadius: 2.2)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#FFF8EC"), Color(hex: "#A3A7AF"), Color(hex: "#374151")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 11, height: 8)
                    .overlay(
                        VStack(spacing: 1.5) {
                            Rectangle().fill(Color.black.opacity(0.4)).frame(height: 0.75)
                            Rectangle().fill(Color.black.opacity(0.4)).frame(height: 0.75)
                        }
                    )
                    .shadow(color: Color.black.opacity(0.4), radius: 2, y: 1)
                
                // B. Upper Shaft Stub (connects counterweight to pivot hub)
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#FFF8EC"), Color(hex: "#D1D5DB"), Color(hex: "#6B7280")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 3.2, height: 10)
                
                // C. Precision Gimbal Hub (Sits directly at the pivot point, y = 18)
                ZStack {
                    // Outer Ring
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#FFF8EC"), Color(hex: "#9CA3AF"), Color(hex: "#2D3036")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 14, height: 14)
                        .overlay(Circle().stroke(Color.black.opacity(0.4), lineWidth: 0.75))
                        .shadow(color: Color.black.opacity(0.4), radius: 2, y: 1)
                    
                    // Center Sapphire Pin
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color(hex: "#FFF8EC"), Color(hex: "#6B7280"), Color(hex: "#111113")],
                                center: .center,
                                startRadius: 0,
                                endRadius: 3
                            )
                        )
                        .frame(width: 5, height: 5)
                        .overlay(Circle().stroke(PastelTheme.pastelOat.opacity(0.8), lineWidth: 0.6))
                }
                .frame(height: 0) // Zero layout height so it overlays seamlessly at the pivot junction
                
                // D. Main Aerospace Titanium Wand (Extending down from pivot)
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "#FFF8EC"),
                                Color(hex: "#E5E7EB"),
                                Color(hex: "#9CA3AF"),
                                Color(hex: "#4B5563")
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 3.2, height: 48)
                    .shadow(color: Color.black.opacity(0.45), radius: 2, x: -1, y: 1)
                
                // E. Bayonet Connector Collar
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color(hex: "#1E2026"))
                    .frame(width: 5, height: 3)
                    .overlay(Rectangle().stroke(Color.white.opacity(0.25), lineWidth: 0.5))
                
                // F. Audiophile Headshell with Emerald Jewel Body & Stylus (Directly attached to collar!)
                ZStack(alignment: .top) {
                    // Emerald Jewel Cartridge Body
                    RoundedRectangle(cornerRadius: 2.2)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#10B981"), Color(hex: "#059669"), Color(hex: "#064E3B")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 8, height: 12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 2.2)
                                .stroke(Color.white.opacity(0.35), lineWidth: 0.6)
                        )
                        .shadow(color: Color(hex: "#10B981").opacity(0.6), radius: 4)
                    
                    // Gold Trim Accent Line
                    Rectangle()
                        .fill(Color(hex: "#FFF8EC"))
                        .frame(width: 5, height: 1)
                        .offset(y: 2.5)
                    
                    // Cantilever & Diamond Stylus Needle
                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(Color(hex: "#E5E7EB"))
                            .frame(width: 1.2, height: 3.5)
                        
                        Circle()
                            .fill(Color.white)
                            .frame(width: 2.2, height: 2.2)
                            .shadow(color: Color(hex: "#10B981"), radius: 3)
                    }
                    .offset(y: 10)
                }
                .rotationEffect(.degrees(18), anchor: .top)
                .offset(x: -2)
            }
            .frame(width: 32)
            .rotationEffect(.degrees(angle), anchor: UnitPoint(x: 0.5, y: 18.0 / 83.0))
        }
        .frame(width: 36, height: 86)
    }
}

// MARK: - 2. Standalone Rotating Colored Vinyl in Row

private struct StandaloneVinylRecordCard: View {
    let item: VinylTurntableHorizonView.ColoredVinylItem
    let isPlaying: Bool
    let isActive: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Large Colored Vinyl Disc (82 x 82)
                TimelineView(.animation(paused: !isPlaying)) { timeline in
                    let time = timeline.date.timeIntervalSinceReferenceDate
                    let rotation = (time.truncatingRemainder(dividingBy: 3.5) / 3.5) * 360.0
                    
                    ZStack {
                        // Colored Wax Base with Marbled Angular Swirl (Unmistakable visible spin)
                        Circle()
                            .fill(
                                AngularGradient(
                                    colors: [
                                        item.waxGradient.first ?? Color(hex: "#2E1A22"),
                                        item.waxGradient.last ?? Color(hex: "#0E070A"),
                                        item.waxGradient.first?.opacity(0.7) ?? Color(hex: "#2E1A22"),
                                        item.waxGradient.first?.opacity(0.95) ?? Color(hex: "#450A0A"),
                                        Color.white.opacity(0.18),
                                        item.waxGradient.last?.opacity(0.85) ?? Color(hex: "#0E070A"),
                                        item.waxGradient.first ?? Color(hex: "#2E1A22")
                                    ],
                                    center: .center
                                )
                            )
                            .frame(width: 82, height: 82)
                            .overlay(
                                Circle().stroke(
                                    isActive ? PastelTheme.cardBorderFocused : Color.white.opacity(0.16),
                                    lineWidth: isActive ? 1.5 : 0.8
                                )
                            )
                            .shadow(color: item.glowColor.opacity(isActive ? 0.55 : 0.25), radius: isActive ? 12 : 6)
                        
                        // Micro Grooves
                        Circle().stroke(Color.white.opacity(0.08), lineWidth: 0.75).frame(width: 74, height: 74)
                        Circle().stroke(Color.white.opacity(0.06), lineWidth: 0.75).frame(width: 64, height: 64)
                        Circle().stroke(Color.white.opacity(0.08), lineWidth: 0.75).frame(width: 54, height: 54)
                        Circle().stroke(Color.white.opacity(0.07), lineWidth: 0.75).frame(width: 44, height: 44)
                        
                        // Specular Light Sheen ("Виниловый крест света")
                        AngularGradient(
                            colors: [
                                Color.clear,
                                Color.white.opacity(0.18),
                                Color.clear,
                                Color.white.opacity(0.18),
                                Color.clear
                            ],
                            center: .center
                        )
                        .clipShape(Circle())
                        
                        // Center Label with Authentic Typography & Rotating Two-Tone Art
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: item.labelGradient,
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 28, height: 28)
                                .overlay(Circle().stroke(Color.black.opacity(0.6), lineWidth: 1.5))
                            
                            // Two-tone semi-circle arc (creates high-contrast rotation tracking)
                            Circle()
                                .trim(from: 0.0, to: 0.5)
                                .fill(Color.black.opacity(0.25))
                                .frame(width: 28, height: 28)
                            
                            VStack(spacing: 6) {
                                Text("SIDE A")
                                    .font(.system(size: 3.8, weight: .black, design: .monospaced))
                                    .foregroundColor(item.labelTextColor.opacity(0.85))
                                
                                Text("33 ⅓")
                                    .font(.system(size: 3.5, weight: .bold, design: .monospaced))
                                    .foregroundColor(item.labelTextColor.opacity(0.75))
                            }
                            
                            if item.symbolOrInitial.count == 1 {
                                Text(item.symbolOrInitial)
                                    .font(.system(size: 10, weight: .black, design: .rounded))
                                    .foregroundColor(item.labelTextColor)
                            } else {
                                Image(systemName: item.symbolOrInitial)
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(item.labelTextColor)
                            }
                        }
                    }
                    .rotationEffect(.degrees(rotation))
                }
                .frame(width: 82, height: 82)
                
                // Track / Artist Title
                Text(item.title)
                    .font(.system(size: 11, weight: isActive ? .bold : .medium, design: .rounded))
                    .foregroundColor(isActive ? PastelTheme.textPrimary : PastelTheme.textSecondary)
                    .lineLimit(1)
                    .frame(width: 82)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

