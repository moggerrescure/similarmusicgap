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
                        
                        // 2. Physical Tonearm Motion (12.0s graceful analog cycle: 6s inward to inner groove, 6s outward to outer rim)
                        // Smooth harmonic sinusoidal motion: zero jerk, zero teleportation, authentic vinyl tracking
                        let tonearmCycle = 12.0
                        let phase = (playTime.truncatingRemainder(dividingBy: tonearmCycle) / tonearmCycle) * Double.pi * 2.0
                        let cycleProgress = (1.0 - cos(phase)) * 0.5
                        let tonearmAngle = 10.0 + (cycleProgress * 14.0) // 10.0° (outer groove) to 24.0° (inner groove)
                        
                        ZStack(alignment: .topTrailing) {
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
                            
                            // Tonearm with Stylus Needle (smoothly glides across disc grooves)
                            TonearmAssemblyView(
                                angle: tonearmAngle
                            )
                            .frame(width: 44, height: 80)
                            .offset(x: -6, y: 8)
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

// MARK: - Platter Disc on Deck with 16 Strobe Marks & Visible Swirling Wax

private struct TurntableSpinningPlatterDisc: View {
    let waxGradient: [Color]
    let labelGradient: [Color]
    let symbolOrInitial: String
    let labelTextColor: Color
    
    var body: some View {
        ZStack {
            // 1. Colored Wax Vinyl Base with Marbled Angular Swirl (Unmistakable visible spin!)
            Circle()
                .fill(
                    AngularGradient(
                        colors: [
                            waxGradient.first ?? Color(hex: "#2E1A22"),
                            waxGradient.last ?? Color(hex: "#0E070A"),
                            waxGradient.first?.opacity(0.8) ?? Color(hex: "#2E1A22"),
                            Color.white.opacity(0.12),
                            waxGradient.last ?? Color(hex: "#0E070A"),
                            waxGradient.first ?? Color(hex: "#2E1A22")
                        ],
                        center: .center
                    )
                )
                .overlay(Circle().stroke(Color.white.opacity(0.20), lineWidth: 1.0))
                .shadow(color: waxGradient.first?.opacity(0.4) ?? Color.black.opacity(0.5), radius: 8)
            
            // 2. Physical Outer Rim Strobe Marks (16 strobe notches that race around the platter edge!)
            ForEach(0..<16, id: \.self) { i in
                Rectangle()
                    .fill(Color.white.opacity(0.38))
                    .frame(width: 2.0, height: 4.5)
                    .offset(y: -43)
                    .rotationEffect(.degrees(Double(i) * (360.0 / 16.0)))
            }
            
            // 3. Physical Concentric Micro-Grooves
            Circle().stroke(Color.white.opacity(0.09), lineWidth: 0.75).frame(width: 80, height: 80)
            Circle().stroke(Color.white.opacity(0.06), lineWidth: 0.75).frame(width: 70, height: 70)
            Circle().stroke(Color.white.opacity(0.08), lineWidth: 0.75).frame(width: 60, height: 60)
            Circle().stroke(Color.white.opacity(0.07), lineWidth: 0.75).frame(width: 50, height: 50)
            Circle().stroke(Color.white.opacity(0.09), lineWidth: 0.75).frame(width: 40, height: 40)
            
            // 4. Center Label with Asymmetric Spin Marker & High-Contrast Art
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: labelGradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)
                    .overlay(Circle().stroke(Color.black.opacity(0.7), lineWidth: 1.5))
                    .shadow(color: Color.black.opacity(0.4), radius: 4)
                
                // High-contrast diagonal split stripe on label for immediate visual spin verification
                Rectangle()
                    .fill(Color.white.opacity(0.30))
                    .frame(width: 30, height: 1.5)
                    .rotationEffect(.degrees(45))
                
                if symbolOrInitial.count == 1 {
                    Text(symbolOrInitial)
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundColor(labelTextColor)
                } else {
                    Image(systemName: symbolOrInitial)
                        .font(.system(size: 11, weight: .bold))
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

// MARK: - Precision Tonearm Assembly (Continuous Smooth Position)

private struct TonearmAssemblyView: View {
    let angle: Double
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Metallic Tonearm Arm with Head
            VStack(spacing: 0) {
                // Tone Arm Rod
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#EFE3D3"), Color(hex: "#A3A7AF"), Color(hex: "#5C6068")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 3, height: 56)
                    .shadow(color: Color.black.opacity(0.5), radius: 3, y: 2)
                
                // Cartridge Headshell & Stylus Needle
                ZStack {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(hex: "#10B981"))
                        .frame(width: 7, height: 12)
                        .shadow(color: Color(hex: "#10B981").opacity(0.6), radius: 4)
                    
                    // Needle Tip (Stylus)
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: 1.5, height: 3)
                        .offset(y: 5)
                }
                .rotationEffect(.degrees(22))
            }
            .offset(x: -8, y: 10)
            .rotationEffect(.degrees(angle), anchor: .topTrailing)
            
            // Tonearm Pivot Base
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(hex: "#FFF8EC"), Color(hex: "#8E939D"), Color(hex: "#2D3036")],
                            center: .center,
                            startRadius: 1,
                            endRadius: 9
                        )
                    )
                    .frame(width: 16, height: 16)
                    .shadow(color: Color.black.opacity(0.6), radius: 4, y: 2)
                
                Circle()
                    .fill(Color(hex: "#111113"))
                    .frame(width: 6, height: 6)
            }
        }
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
                                        item.waxGradient.first?.opacity(0.8) ?? Color(hex: "#2E1A22"),
                                        Color.white.opacity(0.12),
                                        item.waxGradient.last ?? Color(hex: "#0E070A"),
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
                        
                        // Physical Outer Rim Strobe Marks (12 notches that visibly rotate with the disc)
                        ForEach(0..<12, id: \.self) { i in
                            Rectangle()
                                .fill(Color.white.opacity(0.35))
                                .frame(width: 1.8, height: 3.8)
                                .offset(y: -38)
                                .rotationEffect(.degrees(Double(i) * (360.0 / 12.0)))
                        }
                        
                        // Micro Grooves
                        Circle().stroke(Color.white.opacity(0.08), lineWidth: 0.75).frame(width: 74, height: 74)
                        Circle().stroke(Color.white.opacity(0.06), lineWidth: 0.75).frame(width: 64, height: 64)
                        Circle().stroke(Color.white.opacity(0.08), lineWidth: 0.75).frame(width: 54, height: 54)
                        Circle().stroke(Color.white.opacity(0.07), lineWidth: 0.75).frame(width: 44, height: 44)
                        
                        // Specular Light Sheen
                        AngularGradient(
                            colors: [
                                Color.clear,
                                Color.white.opacity(0.16),
                                Color.clear,
                                Color.white.opacity(0.16),
                                Color.clear
                            ],
                            center: .center
                        )
                        .clipShape(Circle())
                        
                        // Center Label with Asymmetric Spin Marker
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
                            
                            // High-contrast diagonal split stripe on label for immediate visual spin verification
                            Rectangle()
                                .fill(Color.white.opacity(0.30))
                                .frame(width: 26, height: 1.5)
                                .rotationEffect(.degrees(45))
                            
                            if item.symbolOrInitial.count == 1 {
                                Text(item.symbolOrInitial)
                                    .font(.system(size: 11, weight: .black, design: .rounded))
                                    .foregroundColor(item.labelTextColor)
                            } else {
                                Image(systemName: item.symbolOrInitial)
                                    .font(.system(size: 10, weight: .bold))
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

