import SwiftUI
import Combine

/// Luxury Top-Down Smart Mixtape Radio Screen (Apple HIG HUD Standard)
/// Unfolds from the top of the phone screen when tapping any Cassette Tape Deck in the feed.
/// Features:
/// 1. Top Navigation Bar with "← Назад" pill, centered "MIXTAPE RADIO" title, and "✕" button
/// 2. Physical Analog Cassette Deck Chassis with corner screws, vintage label, clear acrylic window,
///    magnetic head felt pad, and dual mechanical cog spools that physically spin when playing
/// 3. Curated Vibe Radio Stream tracklist matching the mood & BPM
/// 4. 1-Tap Playback and "Add to Queue" with tactile haptics & HUD toast
public struct CassetteRadioDetailView: View {
    public let tape: SpotifyHomeFeedView.CassetteItem
    public let onDismiss: () -> Void
    
    @ObservedObject private var player = AudioPlayerManager.shared
    @State private var toastMessage: String? = nil
    @State private var showToast: Bool = false
    @State private var spoolAngle: Double = 0
    
    public init(tape: SpotifyHomeFeedView.CassetteItem, onDismiss: @escaping () -> Void) {
        self.tape = tape
        self.onDismiss = onDismiss
    }
    
    // Curated Radio Stream Tracks based on Cassette Theme
    private var curatedTracks: [UniversalTrack] {
        switch tape.id {
        case 201: // Night Drive Pulse
            return [
                UniversalTrack(title: "Resonance", artists: ["HOME"], album: "Odyssey", durationMs: 212000, spotifyId: "tape_201_1"),
                UniversalTrack(title: "Nightcall", artists: ["Kavinsky", "Lovefoxxx"], album: "OutRun", durationMs: 259000, spotifyId: "tape_201_2"),
                UniversalTrack(title: "Turbo Killer", artists: ["Carpenter Brut"], album: "Trilogy", durationMs: 208000, spotifyId: "tape_201_3"),
                UniversalTrack(title: "Tech Noir", artists: ["GUNSHIP"], album: "GUNSHIP", durationMs: 297000, spotifyId: "tape_201_4"),
                UniversalTrack(title: "After Dark", artists: ["Mr.Kitty"], album: "Time", durationMs: 257000, spotifyId: "tape_201_5"),
                UniversalTrack(title: "Dust", artists: ["M|O|O|N"], album: "Moon EP", durationMs: 302000, spotifyId: "tape_201_6"),
                UniversalTrack(title: "Vortex", artists: ["Perturbator"], album: "The Uncanny Valley", durationMs: 270000, spotifyId: "tape_201_7"),
                UniversalTrack(title: "Pacific Coast Highway", artists: ["Kavinsky"], album: "OutRun", durationMs: 230000, spotifyId: "tape_201_8")
            ]
        case 202: // Silk Lo-Fi Flow
            return [
                UniversalTrack(title: "Affection", artists: ["Jinsang"], album: "Solitude", durationMs: 134000, spotifyId: "tape_202_1"),
                UniversalTrack(title: "Again", artists: ["Wun Two"], album: "Rio", durationMs: 118000, spotifyId: "tape_202_2"),
                UniversalTrack(title: "Can We Kiss Forever?", artists: ["Kina", "Adriana Proenza"], album: "Things I Wanted to Tell You", durationMs: 187000, spotifyId: "tape_202_3"),
                UniversalTrack(title: "Feather", artists: ["Nujabes", "Cise Starr"], album: "Modal Soul", durationMs: 175000, spotifyId: "tape_202_4"),
                UniversalTrack(title: "Coffee", artists: ["Kavv"], album: "Morning Roast", durationMs: 141000, spotifyId: "tape_202_5"),
                UniversalTrack(title: "Get You The Moon", artists: ["Kina", "Snøw"], album: "Things I Wanted to Tell You", durationMs: 179000, spotifyId: "tape_202_6"),
                UniversalTrack(title: "Contretemps", artists: ["Saib"], album: "Buena Vista", durationMs: 192000, spotifyId: "tape_202_7")
            ]
        case 203: // Tokyo Drift Phonk
            return [
                UniversalTrack(title: "Metamorphosis", artists: ["INTERWORLD"], album: "Metamorphosis", durationMs: 142000, spotifyId: "tape_203_1"),
                UniversalTrack(title: "Murder In My Mind", artists: ["Kordhell"], album: "Beat Tape", durationMs: 145000, spotifyId: "tape_203_2"),
                UniversalTrack(title: "RAVE", artists: ["Dxrk ダーク"], album: "RAVE", durationMs: 169000, spotifyId: "tape_203_3"),
                UniversalTrack(title: "MIDNIGHT", artists: ["PLAYAMANE", "Nateki"], album: "MIDNIGHT", durationMs: 124000, spotifyId: "tape_203_4"),
                UniversalTrack(title: "Close Eyes", artists: ["DVRST"], album: "Close Eyes", durationMs: 132000, spotifyId: "tape_203_5"),
                UniversalTrack(title: "Warning", artists: ["MC ORSEN"], album: "Warning", durationMs: 138000, spotifyId: "tape_203_6"),
                UniversalTrack(title: "Montagem Mysterious Game", artists: ["LXNGVX"], album: "Mysterious", durationMs: 122000, spotifyId: "tape_203_7")
            ]
        default: // Club Mix Surge
            return [
                UniversalTrack(title: "Where You Are", artists: ["John Summit", "Hayla"], album: "Where You Are", durationMs: 235000, spotifyId: "tape_204_1"),
                UniversalTrack(title: "Delilah (pull me out of this)", artists: ["Fred again.."], album: "Actual Life 3", durationMs: 250000, spotifyId: "tape_204_2"),
                UniversalTrack(title: "(It Goes Like) Nanana", artists: ["Peggy Gou"], album: "I Hear You", durationMs: 231000, spotifyId: "tape_204_3"),
                UniversalTrack(title: "Losing It", artists: ["FISHER"], album: "Losing It", durationMs: 248000, spotifyId: "tape_204_4"),
                UniversalTrack(title: "Glue", artists: ["Bicep"], album: "Bicep", durationMs: 269000, spotifyId: "tape_204_5"),
                UniversalTrack(title: "Rumble", artists: ["Skrillex", "Fred again..", "Flowdan"], album: "Quest For Fire", durationMs: 146000, spotifyId: "tape_204_6")
            ]
        }
    }
    
    private var isTapePlaying: Bool {
        guard let current = player.currentTrack else { return false }
        return player.isPlaying && curatedTracks.contains(where: { $0.id == current.id })
    }
    
    public var body: some View {
        ZStack {
            // OLED Cashmere Charcoal Base
            PastelTheme.canvas.ignoresSafeArea()
            
            // Dynamic Ambient Gradient Wash Top
            AmbientWashBackgroundView(tab: .home)
            
            VStack(spacing: 0) {
                // Top-Down Navigation Bar
                topNavigationBar
                
                // Scrollable Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        // 1. Expanded Physical Cassette Hero Deck
                        cassetteHeroDeck
                            .padding(.top, 10)
                        
                        // 2. Play Mixtape & Shuffle Actions
                        actionButtonsView
                            .padding(.horizontal, 20)
                        
                        // 3. Curated Radio Stream Header
                        HStack {
                            Text("CURATED RADIO STREAM")
                                .font(.system(size: 11, weight: .heavy))
                                .tracking(0.8)
                                .foregroundColor(Color(hex: "#9CA3AF"))
                            
                            Spacer()
                            
                            Text("\(curatedTracks.count) TRACKS")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(PastelTheme.warmAmber)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 6)
                        
                        // 4. Radio Tracklist
                        tracklistSection
                            .padding(.horizontal, 16)
                            .padding(.bottom, 130) // Clearance for floating bottom mini-player
                    }
                }
            }
            
            // HUD Toast
            if showToast, let msg = toastMessage {
                VStack {
                    Spacer()
                    queueToastView(message: msg)
                        .padding(.bottom, 96)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: showToast)
            }
        }
    }
    
    // MARK: - Top-Down Navigation Bar
    private var topNavigationBar: some View {
        HStack {
            // "← Назад" Frosted Pill Button
            Button {
                HapticManager.lightImpact()
                onDismiss()
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .bold))
                    Text("Назад")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(PastelTheme.pastelOat)
                .padding(.horizontal, 14)
                .frame(height: 32)
                .background(Color.white.opacity(0.08))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(PastelTheme.cardBorder, lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            // Center Pill
            Text("MIXTAPE RADIO")
                .font(.system(size: 11, weight: .heavy))
                .tracking(1.0)
                .foregroundColor(Color(hex: "#9CA3AF"))
            
            Spacer()
            
            // Close "✕" Button
            Button {
                HapticManager.lightImpact()
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(hex: "#9CA3AF"))
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(PastelTheme.cardBorder, lineWidth: 1)
                    )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .background(Color(hex: "#0E0F12").opacity(0.96))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.white.opacity(0.06)),
            alignment: .bottom
        )
    }
    
    // MARK: - Physical Analog Cassette Hero Deck
    private var cassetteHeroDeck: some View {
        VStack(spacing: 14) {
            // Physical Chassis Box
            ZStack {
                // Outer Matte Graphite Chassis
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(hex: "#14161C"))
                    .frame(width: 270, height: 165)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.18), lineWidth: 1.5)
                    )
                    .shadow(color: Color.black.opacity(0.85), radius: 24, y: 12)
                
                // 4 Tactile Corner Screws
                cornerScrews
                
                VStack(spacing: 8) {
                    // Vintage Color Label Strip
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: tape.labelGradient,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 244, height: 62)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("\(tape.sideText) // ANALOG BIAS")
                                    .font(.system(size: 8, weight: .heavy, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.85))
                                Spacer()
                                Text(tape.tapeLength)
                                    .font(.system(size: 8, weight: .heavy, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.85))
                            }
                            
                            Text(tape.title)
                                .font(.system(size: 15, weight: .black))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            
                            HStack {
                                Text(tape.tapeType)
                                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.75))
                                Spacer()
                                Text("DOLBY B NR")
                                    .font(.system(size: 7.5, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .frame(width: 244, height: 62)
                    }
                    
                    // Clear Acrylic Tape Window with Dual Rotating Spools
                    ZStack {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.black.opacity(0.7))
                            .frame(width: 244, height: 46)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
                            )
                        
                        // Magnetic Tape Ribbon inside
                        Rectangle()
                            .fill(Color(hex: "#3B2A1E"))
                            .frame(width: 200, height: 8)
                            .offset(y: 8)
                        
                        HStack(spacing: 40) {
                            // Left Mechanical Spool
                            mechanicalSpoolView(diameter: 30)
                            
                            // Center Tape Scale Ruler
                            HStack(spacing: 4) {
                                Text("0")
                                Text("25")
                                Text("50")
                                Text("75")
                                Text("100")
                            }
                            .font(.system(size: 6.5, weight: .bold, design: .monospaced))
                            .foregroundColor(Color(hex: "#6B7280"))
                            
                            // Right Mechanical Spool
                            mechanicalSpoolView(diameter: 22)
                        }
                    }
                    
                    // Bottom Wedge with Capstan Holes & Magnetic Head
                    ZStack {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(Color(hex: "#0E0F14"))
                            .frame(width: 244, height: 18)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                            )
                        
                        HStack(spacing: 36) {
                            Circle()
                                .fill(Color.black)
                                .frame(width: 6, height: 6)
                            
                            // Center Bronze Head Felt
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color(hex: "#92400E"))
                                .frame(width: 16, height: 6)
                            
                            Circle()
                                .fill(Color.black)
                                .frame(width: 6, height: 6)
                        }
                    }
                }
            }
            .frame(width: 270, height: 165)
            
            // Vibe Metadata & Algorithmic Description
            VStack(spacing: 5) {
                // Smart Vibe Radio Pill
                Text("SMART VIBE RADIO • 99% MATCH")
                    .font(.system(size: 8.5, weight: .heavy))
                    .tracking(0.8)
                    .foregroundColor(PastelTheme.warmAmber)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(PastelTheme.warmAmber.opacity(0.15))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(PastelTheme.warmAmber.opacity(0.4), lineWidth: 1)
                    )
                
                Text(tape.title)
                    .font(.system(size: 20, weight: .black))
                    .foregroundColor(.white)
                
                Text("\(tape.subtitle) • Handcrafted analog stream matching your drive state")
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundColor(Color(hex: "#9CA3AF"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
        }
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(PastelTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(PastelTheme.cardBorder, lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }
    
    // MARK: - Mechanical Spool View
    private func mechanicalSpoolView(diameter: CGFloat) -> some View {
        TimelineView(.animation(paused: !isTapePlaying)) { timeline in
            let angle = isTapePlaying ? (timeline.date.timeIntervalSinceReferenceDate * 140.0).truncatingRemainder(dividingBy: 360.0) : 0
            
            ZStack {
                Circle()
                    .fill(Color(hex: "#22242C"))
                    .frame(width: diameter, height: diameter)
                    .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1))
                
                // 6 Mechanical Gear Teeth
                ForEach(0..<6) { i in
                    Rectangle()
                        .fill(Color.white.opacity(0.7))
                        .frame(width: 2, height: diameter * 0.42)
                        .rotationEffect(.degrees(Double(i) * 30))
                }
                
                // Center Spindle Hole
                Circle()
                    .fill(Color.black)
                    .frame(width: diameter * 0.36, height: diameter * 0.36)
                    .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 0.8))
            }
            .frame(width: diameter, height: diameter)
            .rotationEffect(.degrees(angle))
        }
    }
    
    // MARK: - 4 Corner Screws
    private var cornerScrews: some View {
        ZStack {
            screwCircle.offset(x: -122, y: -70)
            screwCircle.offset(x: 122, y: -70)
            screwCircle.offset(x: -122, y: 70)
            screwCircle.offset(x: 122, y: 70)
        }
    }
    
    private var screwCircle: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "#2A2D37"))
                .frame(width: 8, height: 8)
                .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 0.5))
            Rectangle()
                .fill(Color(hex: "#14161C"))
                .frame(width: 5, height: 1)
        }
    }
    
    // MARK: - Action Buttons
    private var actionButtonsView: some View {
        HStack(spacing: 12) {
            // Play Mixtape Primary Button
            Button {
                HapticManager.successNotification()
                playAllTracks()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: isTapePlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 13, weight: .bold))
                    Text(isTapePlaying ? "Pause Mixtape" : "Play Mixtape")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundColor(PastelTheme.textOnOat)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(PastelTheme.pastelOat)
                .clipShape(Capsule())
                .shadow(color: PastelTheme.pastelOat.opacity(0.22), radius: 8, y: 3)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Shuffle Vibe Button
            Button {
                HapticManager.lightImpact()
                shufflePlayTracks()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "shuffle")
                        .font(.system(size: 13, weight: .bold))
                    Text("Shuffle Vibe")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .frame(height: 44)
                .background(PastelTheme.card)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(PastelTheme.cardBorder, lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - Tracklist Section
    private var tracklistSection: some View {
        VStack(spacing: 6) {
            ForEach(Array(curatedTracks.enumerated()), id: \.element.id) { index, track in
                let isCurrent = player.currentTrack?.id == track.id
                let isPlayingThis = isCurrent && player.isPlaying
                
                trackRow(
                    index: index + 1,
                    track: track,
                    isCurrent: isCurrent,
                    isPlaying: isPlayingThis
                )
            }
        }
    }
    
    private func trackRow(
        index: Int,
        track: UniversalTrack,
        isCurrent: Bool,
        isPlaying: Bool
    ) -> some View {
        HStack(spacing: 12) {
            // Track Number / Animated EQ
            ZStack {
                if isPlaying {
                    WaveformBarsView(color: PastelTheme.athleticEmerald, isAnimating: true)
                        .frame(width: 18, height: 14)
                } else {
                    Text(String(format: "%02d", index))
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(isCurrent ? PastelTheme.athleticEmerald : Color(hex: "#6B7280"))
                }
            }
            .frame(width: 24)
            
            // Track Title & Artists
            VStack(alignment: .leading, spacing: 2) {
                Text(track.title)
                    .font(.system(size: 14, weight: isCurrent ? .bold : .semibold))
                    .foregroundColor(isCurrent ? PastelTheme.athleticEmerald : .white)
                    .lineLimit(1)
                
                Text(track.artists.joined(separator: ", "))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(hex: "#9CA3AF"))
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Duration
            Text(formatDuration(ms: track.durationMs))
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(Color(hex: "#6B7280"))
            
            // "Add to Queue" Quick Button
            Button {
                player.addToQueue(track: track)
                showQueueToastFeedback(trackTitle: track.title)
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(PastelTheme.pastelOat)
                    .frame(width: 28, height: 28)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Circle())
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(isCurrent ? Color(hex: "#1C1D25") : PastelTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(isCurrent ? PastelTheme.athleticEmerald.opacity(0.55) : PastelTheme.cardBorder, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            HapticManager.selectionChanged()
            player.play(track: track, in: curatedTracks)
        }
    }
    
    // MARK: - Actions
    private func playAllTracks() {
        if isTapePlaying {
            player.pause()
        } else {
            if let first = curatedTracks.first {
                player.play(track: first, in: curatedTracks)
            }
        }
    }
    
    private func shufflePlayTracks() {
        guard let randomTrack = curatedTracks.randomElement() else { return }
        player.play(track: randomTrack, in: curatedTracks.shuffled())
    }
    
    private func showQueueToastFeedback(trackTitle: String) {
        HapticManager.lightImpact()
        toastMessage = "Added to queue: \(trackTitle)"
        withAnimation { showToast = true }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation { showToast = false }
        }
    }
    
    private func queueToastView(message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(PastelTheme.athleticEmerald)
                .font(.system(size: 14))
            
            Text(message)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(hex: "#1E2026").opacity(0.95))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(PastelTheme.athleticEmerald.opacity(0.4), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.6), radius: 12, y: 6)
    }
    
    private func formatDuration(ms: Int) -> String {
        let totalSeconds = ms / 1000
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

