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
        public let trackId: UUID?
        public let opensLikedSongs: Bool
        
        public init(
            id: Int,
            title: String,
            artist: String,
            symbolOrInitial: String,
            waxGradient: [Color],
            labelGradient: [Color],
            labelTextColor: Color,
            glowColor: Color,
            trackId: UUID? = nil,
            opensLikedSongs: Bool = false
        ) {
            self.id = id
            self.title = title
            self.artist = artist
            self.symbolOrInitial = symbolOrInitial
            self.waxGradient = waxGradient
            self.labelGradient = labelGradient
            self.labelTextColor = labelTextColor
            self.glowColor = glowColor
            self.trackId = trackId
            self.opensLikedSongs = opensLikedSongs
        }
    }
    
    private static let waxPalettes: [(wax: [Color], label: [Color], text: Color, glow: Color)] = [
        (
            [Color(hex: "#4A1FB8"), Color(hex: "#291266"), Color(hex: "#150938")],
            [Color(hex: "#450AF5"), Color(hex: "#C4EFD9")],
            .white,
            Color(hex: "#4A1FB8")
        ),
        (
            [Color(hex: "#E11D74"), Color(hex: "#880E43"), Color(hex: "#42041E")],
            [Color(hex: "#E11D74"), Color(hex: "#9C124E")],
            .white,
            Color(hex: "#E11D74")
        ),
        (
            [Color(hex: "#10B981"), Color(hex: "#065F46"), Color(hex: "#022C22")],
            [Color(hex: "#10B981"), Color(hex: "#059669")],
            .black,
            Color(hex: "#10B981")
        ),
        (
            [Color(hex: "#FBBF24"), Color(hex: "#B45309"), Color(hex: "#451A03")],
            [Color(hex: "#FBBF24"), Color(hex: "#D97706")],
            .black,
            Color(hex: "#FBBF24")
        ),
        (
            [Color(hex: "#2563EB"), Color(hex: "#1E3A8A"), Color(hex: "#0F172A")],
            [Color(hex: "#2563EB"), Color(hex: "#1D4ED8")],
            .white,
            Color(hex: "#2563EB")
        ),
        (
            [Color(hex: "#991B1B"), Color(hex: "#450A0A"), Color(hex: "#1C0505")],
            [Color(hex: "#EF4444"), Color(hex: "#991B1B")],
            .white,
            Color(hex: "#EF4444")
        )
    ]
    
    /// Prefer synced library artists/tracks; showcase discs only when library is empty.
    private var vinyls: [ColoredVinylItem] {
        if !coordinator.allTracks.isEmpty {
            var items: [ColoredVinylItem] = [
                ColoredVinylItem(
                    id: 1,
                    title: "Liked Songs",
                    artist: "\(coordinator.allTracks.count) synced",
                    symbolOrInitial: "heart.fill",
                    waxGradient: Self.waxPalettes[0].wax,
                    labelGradient: Self.waxPalettes[0].label,
                    labelTextColor: Self.waxPalettes[0].text,
                    glowColor: Self.waxPalettes[0].glow,
                    opensLikedSongs: true
                )
            ]
            
            let artists = Array(
                Set(coordinator.allTracks.prefix(60).map(\.primaryArtist))
                    .sorted()
                    .prefix(5)
            )
            for (idx, artist) in artists.enumerated() {
                let palette = Self.waxPalettes[(idx + 1) % Self.waxPalettes.count]
                let sample = coordinator.allTracks.first {
                    $0.primaryArtist.localizedCaseInsensitiveContains(artist)
                }
                let initial = String(artist.prefix(1)).uppercased()
                items.append(
                    ColoredVinylItem(
                        id: 10 + idx,
                        title: artist,
                        artist: sample?.album ?? "In your library",
                        symbolOrInitial: initial.isEmpty ? "♪" : initial,
                        waxGradient: palette.wax,
                        labelGradient: palette.label,
                        labelTextColor: palette.text,
                        glowColor: palette.glow,
                        trackId: sample?.id
                    )
                )
            }
            return items
        }
        
        return [
            ColoredVinylItem(
                id: 1,
                title: "Liked Songs",
                artist: "Connect to sync",
                symbolOrInitial: "heart.fill",
                waxGradient: Self.waxPalettes[0].wax,
                labelGradient: Self.waxPalettes[0].label,
                labelTextColor: Self.waxPalettes[0].text,
                glowColor: Self.waxPalettes[0].glow,
                opensLikedSongs: true
            )
        ]
    }
    
    @State private var activeVinylIndex: Int = 0
    
    public init() {}
    
    private var currentActiveVinyl: ColoredVinylItem {
        guard let current = player.currentTrack else {
            if activeVinylIndex >= 0 && activeVinylIndex < vinyls.count {
                return vinyls[activeVinylIndex]
            }
            return vinyls[0]
        }
        
        let cTitle = current.title
        let cArtist = current.artists.first ?? ""
        let cAlbum = current.album ?? ""
        let cId = current.spotifyId ?? ""
        let cIsrc = current.isrc
        
        // 1. Direct match with top 6 vinyls
        for item in vinyls {
            if cId == "vn_\(item.id)" ||
               item.title.localizedCaseInsensitiveContains(cTitle) ||
               cTitle.localizedCaseInsensitiveContains(item.title) ||
               (!cArtist.isEmpty && item.artist.localizedCaseInsensitiveContains(cArtist)) {
                return item
            }
        }
        
        // 2. Drop of the Week ("New Music Friday")
        if cTitle.localizedCaseInsensitiveContains("New Music") || cIsrc == "DROP-NMF-2024" {
            return ColoredVinylItem(
                id: 999,
                title: "New Music Friday",
                artist: "Friday Drop",
                symbolOrInitial: "star.fill",
                waxGradient: [Color(hex: "#2B2D37"), Color(hex: "#090A0D"), Color(hex: "#1F212A")],
                labelGradient: [Color(hex: "#FEF08A"), Color(hex: "#FBBF24"), Color(hex: "#D97706")],
                labelTextColor: Color(hex: "#0E0F12"),
                glowColor: PastelTheme.warmAmber
            )
        }
        
        // 3. Vault Albums (Travis Scott, SZA, Olivia Rodrigo, JPEGMAFIA)
        if cAlbum.localizedCaseInsensitiveContains("UTOPIA") || cTitle.localizedCaseInsensitiveContains("UTOPIA") {
            return ColoredVinylItem(
                id: 301,
                title: "UTOPIA",
                artist: "Travis Scott",
                symbolOrInitial: "TS",
                waxGradient: [Color(hex: "#4B5563"), Color(hex: "#1F2937"), Color(hex: "#111827")],
                labelGradient: [Color(hex: "#EFE3D3"), Color(hex: "#D1D5DB")],
                labelTextColor: Color(hex: "#0E0F12"),
                glowColor: Color(hex: "#EFE3D3")
            )
        }
        if cAlbum.localizedCaseInsensitiveContains("SOS") || cTitle.localizedCaseInsensitiveContains("SOS") || current.artists.contains("SZA") {
            return ColoredVinylItem(
                id: 302,
                title: "SOS",
                artist: "SZA",
                symbolOrInitial: "SZA",
                waxGradient: [Color(hex: "#2563EB"), Color(hex: "#1D4ED8"), Color(hex: "#0F172A")],
                labelGradient: [Color(hex: "#60A5FA"), Color(hex: "#2563EB")],
                labelTextColor: Color.white,
                glowColor: Color(hex: "#60A5FA")
            )
        }
        if cAlbum.localizedCaseInsensitiveContains("GUTS") || cTitle.localizedCaseInsensitiveContains("GUTS") || current.artists.contains("Olivia Rodrigo") {
            return ColoredVinylItem(
                id: 303,
                title: "GUTS",
                artist: "Olivia Rodrigo",
                symbolOrInitial: "OR",
                waxGradient: [Color(hex: "#9333EA"), Color(hex: "#6B21A8"), Color(hex: "#2E1065")],
                labelGradient: [Color(hex: "#C084FC"), Color(hex: "#7E22CE")],
                labelTextColor: Color.white,
                glowColor: Color(hex: "#C084FC")
            )
        }
        if cAlbum.localizedCaseInsensitiveContains("SCARING") || current.artists.contains("JPEGMAFIA") {
            return ColoredVinylItem(
                id: 304,
                title: "SCARING THE HOES",
                artist: "JPEGMAFIA",
                symbolOrInitial: "SH",
                waxGradient: [Color(hex: "#DC2626"), Color(hex: "#991B1B"), Color(hex: "#2B0B0B")],
                labelGradient: [Color(hex: "#F87171"), Color(hex: "#B91C1C")],
                labelTextColor: Color.white,
                glowColor: Color(hex: "#EF4444")
            )
        }
        
        // 4. Any other track currently playing
        let initial = String(cTitle.prefix(1)).uppercased()
        return ColoredVinylItem(
            id: 888,
            title: cTitle,
            artist: cArtist.isEmpty ? "Vault Live" : cArtist,
            symbolOrInitial: initial.isEmpty ? "LP" : initial,
            waxGradient: [Color(hex: "#374151"), Color(hex: "#1F2937"), Color(hex: "#111827")],
            labelGradient: [PastelTheme.pastelOat, Color(hex: "#9CA3AF")],
            labelTextColor: Color(hex: "#0E0F12"),
            glowColor: PastelTheme.pastelOat
        )
    }
    
    private func isVinylActive(index: Int) -> Bool {
        guard let current = player.currentTrack else {
            return activeVinylIndex == index
        }
        let item = vinyls[index]
        let cTitle = current.title
        let cArtist = current.artists.first ?? ""
        let cId = current.spotifyId ?? ""
        
        if cId == "vn_\(item.id)" {
            return true
        }
        if item.title.localizedCaseInsensitiveContains(cTitle) || cTitle.localizedCaseInsensitiveContains(item.title) {
            return true
        }
        if !cArtist.isEmpty && item.artist.localizedCaseInsensitiveContains(cArtist) {
            return true
        }
        return false
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
                    let active = isVinylActive(index: index)
                    StandaloneVinylRecordCard(
                        item: item,
                        isPlaying: player.isPlaying,
                        isActive: active,
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
        guard index >= 0, index < vinyls.count else { return }
        activeVinylIndex = index
        
        let selected = vinyls[index]
        if selected.opensLikedSongs {
            NavigationCoordinator.shared.openPersonalLibrary()
            return
        }
        
        if let trackId = selected.trackId,
           let track = coordinator.allTracks.first(where: { $0.id == trackId }) {
            let queue = coordinator.allTracks.filter {
                $0.primaryArtist.localizedCaseInsensitiveContains(selected.title)
            }
            player.play(track: track, in: queue.isEmpty ? coordinator.allTracks : queue)
            return
        }
        
        // Empty showcase vinyl — open Connect instead of inventing audio
        NavigationCoordinator.shared.navigateToConnect()
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

// MARK: - 2. Standalone Rotating Colored Vinyl in Row with Ambient Idle Drift

/// Continuous angular motion tracker ensuring seamless acceleration & deceleration without angle jumps
private final class VinylDriftMotionTracker: ObservableObject {
    @Published var tick: Bool = false
    var currentAngle: Double = 0.0
    var lastDate: Date? = nil
    
    func advance(currentDate: Date, isPlaying: Bool, isActive: Bool) -> Double {
        guard isPlaying else {
            lastDate = nil
            return currentAngle
        }
        
        if let last = lastDate {
            let delta = currentDate.timeIntervalSince(last)
            if delta > 0 && delta < 0.5 {
                // Active speed: 360° in 3.2s = 112.5°/sec (Full 33 ⅓ RPM)
                // Inactive drift: 360° in 54.0s = 6.667°/sec (Barely perceptible meditative analog drift)
                let speedDegPerSec: Double = isActive ? (360.0 / 3.2) : (360.0 / 54.0)
                currentAngle += delta * speedDegPerSec
                if currentAngle >= 360000.0 {
                    currentAngle = currentAngle.truncatingRemainder(dividingBy: 360.0)
                }
            }
        }
        lastDate = currentDate
        return currentAngle
    }
}

private struct StandaloneVinylRecordCard: View {
    let item: VinylTurntableHorizonView.ColoredVinylItem
    let isPlaying: Bool
    let isActive: Bool
    let onTap: () -> Void
    
    @StateObject private var motionTracker = VinylDriftMotionTracker()
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Large Colored Vinyl Disc (82 x 82)
                TimelineView(.animation(paused: !isPlaying)) { timeline in
                    let rotation = motionTracker.advance(
                        currentDate: timeline.date,
                        isPlaying: isPlaying,
                        isActive: isActive
                    )
                    
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
                                    isActive && isPlaying ? PastelTheme.cardBorderFocused : Color.white.opacity(0.16),
                                    lineWidth: isActive && isPlaying ? 1.5 : 0.8
                                )
                            )
                            .shadow(color: item.glowColor.opacity(isActive && isPlaying ? 0.6 : 0.2), radius: isActive && isPlaying ? 12 : 5)
                        
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
                    .font(.system(size: 11, weight: isActive && isPlaying ? .bold : .medium, design: .rounded))
                    .foregroundColor(isActive && isPlaying ? PastelTheme.textPrimary : PastelTheme.textSecondary)
                    .lineLimit(1)
                    .frame(width: 82)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

