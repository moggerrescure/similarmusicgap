import SwiftUI

/// Sample model for Cross-Platform Match Results in Bridge Radar
public struct BridgeMatchSample: Identifiable {
    public let id = UUID()
    public let title: String
    public let artist: String
    public let album: String
    public let year: String
    public let artworkGradient: [Color]
    public let isrc: String
    public let spotifyAvailable: Bool
    public let spotifyQuality: String
    public let appleAvailable: Bool
    public let appleQuality: String
    public let yandexAvailable: Bool
    public let yandexQuality: String
}

/// Model for Library Gap Detection (tracks missing on one of the user's services)
public struct LibraryGapItem: Identifiable {
    public let id = UUID()
    public let title: String
    public let artist: String
    public let sourceService: MusicProviderType
    public let missingInService: MusicProviderType
    public let isrc: String
}

/// Genre Card Model for Spotify Browse All Grid
public struct SpotifyGenreCard: Identifiable {
    public let id: Int
    public let title: String
    public let hexColor: String
    public let iconSymbol: String
    public let queryTag: String
}

/// Luxury Cross-Platform Bridge Radar & Song Matcher (Apple HIG HUD iOS 18+)
/// Replaces generic search with a dedicated Cross-Platform Query Engine, Link Resolver, and Gaps Radar.
public struct BridgeRadarSearchView: View {
    @ObservedObject private var player = AudioPlayerManager.shared
    @ObservedObject private var coordinator = ServicesCoordinator.shared
    
    @State private var searchText: String = "Travis Scott - FE!N"
    @State private var bridgedTrackIds: Set<UUID> = []
    @State private var isBridgingActive: Bool = false
    @State private var toastMessage: String? = nil
    @State private var showToast: Bool = false
    @State private var isSonarPulsing: Bool = false
    
    // Quick Demo Chips
    private let quickChips: [(String, String)] = [
        ("🔥 FE!N", "Travis Scott - FE!N"),
        ("🚗 Nightcall", "Kavinsky - Nightcall"),
        ("🔗 Spotify Link", "open.spotify.com/track/4cOdK2wGvuOta"),
        ("⚡️ Gaps", "missing_gaps")
    ]
    
    // Demo Gap Items
    private let gapItems: [LibraryGapItem] = [
        LibraryGapItem(
            title: "Magnolia",
            artist: "Playboi Carti",
            sourceService: .spotify,
            missingInService: .appleMusic,
            isrc: "USUM71703861"
        ),
        LibraryGapItem(
            title: "Младшая сестра",
            artist: "Дора",
            sourceService: .yandexMusic,
            missingInService: .spotify,
            isrc: "RU-A01-20-00142"
        ),
        LibraryGapItem(
            title: "Euphoria",
            artist: "Kendrick Lamar",
            sourceService: .appleMusic,
            missingInService: .yandexMusic,
            isrc: "USUM72403912"
        )
    ]
    
    // Browse Stations (Curated Stations)
    private let genreCategories: [SpotifyGenreCard] = [
        SpotifyGenreCard(id: 1, title: "Hip-Hop", hexColor: "#4B8299", iconSymbol: "headphones", queryTag: "rap"),
        SpotifyGenreCard(id: 2, title: "Electronic", hexColor: "#477D95", iconSymbol: "waveform.path.ecg", queryTag: "edm"),
        SpotifyGenreCard(id: 3, title: "Rock", hexColor: "#006450", iconSymbol: "guitars.fill", queryTag: "rock"),
        SpotifyGenreCard(id: 4, title: "Pop", hexColor: "#E11D74", iconSymbol: "music.quarternote.3", queryTag: "pop"),
        SpotifyGenreCard(id: 5, title: "Indie", hexColor: "#E91429", iconSymbol: "heart.text.square.fill", queryTag: "indie"),
        SpotifyGenreCard(id: 6, title: "Lo-Fi Chill", hexColor: "#B06239", iconSymbol: "cup.and.saucer.fill", queryTag: "lofi")
    ]
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Dynamic Ambient Gradient Wash (Search Tone)
                AmbientWashBackgroundView(tab: .search)
                
                VStack(spacing: 0) {
                    // 1. Top Header Bar
                    headerBar
                        .padding(.horizontal, 16)
                        .padding(.top, 14)
                        .padding(.bottom, 10)
                    
                    // 2. Sticky Bridge Search Bar & Quick Chips
                    searchAndFilterSection
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                    
                    // 3. Scrollable Radar Content
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16) {
                            // 0. Sonar Scanner Visualizer
                            sonarScannerSection
                            
                            // A. Live Tri-Platform Match Card
                            triPlatformMatchCard
                            
                            // B. Library Gaps Radar (Tracks missing on target service)
                            libraryGapsRadarSection
                            
                            // C. Curated Genre Discovery Stations
                            curatedStationsSection
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 140) // Clearance for floating mini-player
                    }
                }
                
                // HUD Toast Overlay
                if showToast, let msg = toastMessage {
                    hudToast(message: msg)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(200)
                }
            }
            #if os(iOS)
            .navigationBarHidden(true)
            #endif
        }
    }
    
    // MARK: - 1. Top Header Bar
    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(PastelTheme.athleticEmerald)
                        .frame(width: 6, height: 6)
                        .shadow(color: PastelTheme.athleticEmerald.opacity(0.8), radius: 3)
                    
                    Text("CROSS-PLATFORM MATCHER")
                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                        .tracking(1.2)
                        .foregroundColor(PastelTheme.pastelSlate)
                }
                
                Text("Bridge Radar")
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // 3-Service Linked Badge
            HStack(spacing: 4) {
                serviceMiniDot(color: Color(hex: "#1ED760"), name: "S")
                serviceMiniDot(color: Color(hex: "#FA243C"), name: "A")
                serviceMiniDot(color: Color(hex: "#FFCC00"), name: "Я")
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(PastelTheme.card)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(PastelTheme.cardBorder, lineWidth: 0.8))
        }
    }
    
    private func serviceMiniDot(color: Color, name: String) -> some View {
        Circle()
            .fill(color)
            .frame(width: 14, height: 14)
            .overlay(
                Text(name)
                    .font(.system(size: 7, weight: .black))
                    .foregroundColor(.black)
            )
    }
    
    // MARK: - 2. Sticky Bridge Search Bar & Quick Chips
    private var searchAndFilterSection: some View {
        VStack(spacing: 8) {
            // Search Input Field
            HStack(spacing: 10) {
                Image(systemName: "sparkle.magnifyingglass")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(PastelTheme.pastelOat)
                    .padding(.leading, 12)
                
                TextField("Track, artist, or URL...", text: $searchText)
                    .font(.system(size: 13.5, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .tint(PastelTheme.pastelOat)
                    .autocorrectionDisabled()
                
                if !searchText.isEmpty {
                    Button {
                        HapticManager.lightImpact()
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 15))
                            .foregroundColor(PastelTheme.textTertiary)
                            .padding(.trailing, 12)
                    }
                }
            }
            .frame(height: 46)
            .background(PastelTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(searchText.contains("http") ? PastelTheme.athleticEmerald : PastelTheme.cardBorder, lineWidth: 1)
            )
            
            // Quick Sample Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(quickChips, id: \.0) { chip in
                        Button {
                            HapticManager.selectionChanged()
                            searchText = chip.1
                        } label: {
                            Text(chip.0)
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundColor(searchText == chip.1 ? PastelTheme.textOnOat : PastelTheme.pastelOat)
                                .padding(.horizontal, 11)
                                .padding(.vertical, 6)
                                .background(searchText == chip.1 ? PastelTheme.pastelOat : PastelTheme.card)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(PastelTheme.cardBorder, lineWidth: 0.8)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }
    
    // MARK: - 0. Sonar Scanner Visualizer
    private var sonarScannerSection: some View {
        Button {
            HapticManager.selectionChanged()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                isSonarPulsing.toggle()
            }
            showToast(message: "⚡️ Радар синхронизирован: Spotify • Apple • Яндекс")
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color(hex: "#14151B"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(PastelTheme.cardBorder, lineWidth: 1)
                    )
                
                // Pulsing Concentric Rings
                ZStack {
                    Circle()
                        .stroke(PastelTheme.athleticEmerald.opacity(0.12), lineWidth: 1)
                        .frame(width: isSonarPulsing ? 180 : 130, height: isSonarPulsing ? 180 : 130)
                    Circle()
                        .stroke(PastelTheme.athleticEmerald.opacity(0.22), lineWidth: 1)
                        .frame(width: isSonarPulsing ? 130 : 95, height: isSonarPulsing ? 130 : 95)
                    Circle()
                        .stroke(PastelTheme.athleticEmerald.opacity(0.35), lineWidth: 1)
                        .frame(width: isSonarPulsing ? 80 : 65, height: isSonarPulsing ? 80 : 65)
                }
                .animation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true), value: isSonarPulsing)
                
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [Color(hex: "#1E222A"), Color(hex: "#121317")], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 48, height: 48)
                            .overlay(Circle().stroke(PastelTheme.athleticEmerald.opacity(0.8), lineWidth: 1.5))
                            .shadow(color: PastelTheme.athleticEmerald.opacity(0.35), radius: 10)
                        
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(PastelTheme.athleticEmerald)
                    }
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(PastelTheme.athleticEmerald)
                            .frame(width: 5, height: 5)
                            .shadow(color: PastelTheme.athleticEmerald, radius: 3)
                        
                        Text("3 CATALOGS CONNECTED • 99.8% READY")
                            .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                            .tracking(1.0)
                            .foregroundColor(PastelTheme.pastelOat)
                    }
                }
            }
            .frame(height: 120)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            isSonarPulsing = true
        }
    }
    
    // MARK: - A. Live Tri-Platform Match Card
    private var triPlatformMatchCard: some View {
        let sample = currentMatchSample
        
        return VStack(spacing: 12) {
            // Card Header: Artwork + Track Lockup
            HStack(spacing: 12) {
                // Monogram Artwork
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: sample.artworkGradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                        .shadow(color: sample.artworkGradient[0].opacity(0.4), radius: 6)
                    
                    Text(String(sample.title.prefix(2)))
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(sample.title)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text("\(sample.artist) • \(sample.album) (\(sample.year))")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(PastelTheme.textSecondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // ISRC Verified Badge
                VStack(alignment: .trailing, spacing: 2) {
                    Text("100% ISRC")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(PastelTheme.athleticEmerald)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(PastelTheme.athleticEmerald.opacity(0.12))
                        .clipShape(Capsule())
                    
                    Text(sample.isrc)
                        .font(.system(size: 7, weight: .medium, design: .monospaced))
                        .foregroundColor(PastelTheme.textTertiary)
                }
            }
            .padding(.bottom, 2)
            
            // 3-Way Platform Matrix Grid
            HStack(spacing: 8) {
                matrixCell(
                    symbol: "S",
                    color: Color(hex: "#1ED760"),
                    textColor: .black,
                    quality: sample.spotifyQuality,
                    badge: "MASTER",
                    badgeColor: PastelTheme.athleticEmerald
                )
                
                matrixCell(
                    symbol: "A",
                    color: Color(hex: "#FA243C"),
                    textColor: .white,
                    quality: sample.appleQuality,
                    badge: "RESOLVED",
                    badgeColor: PastelTheme.pastelSlate
                )
                
                matrixCell(
                    symbol: "Я",
                    color: Color(hex: "#FFCC00"),
                    textColor: .black,
                    quality: sample.yandexQuality,
                    badge: "ACOUSTIC",
                    badgeColor: PastelTheme.warmAmber
                )
            }
            
            // 1-Tap Bridge CTA Button
            Button {
                triggerSingleTrackBridge(sample)
            } label: {
                HStack(spacing: 8) {
                    if isBridgingActive {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: PastelTheme.textOnOat))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 13, weight: .black))
                    }
                    
                    Text(isBridgingActive ? "BRIDGING..." : "1-TAP BRIDGE TO APPLE MUSIC")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .tracking(0.5)
                }
                .foregroundColor(PastelTheme.textOnOat)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(PastelTheme.pastelOat)
                .clipShape(Capsule())
                .shadow(color: PastelTheme.pastelOat.opacity(0.2), radius: 6, y: 2)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(isBridgingActive)
        }
        .padding(14)
        .background(Color(hex: "#14151B"))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(PastelTheme.cardBorder, lineWidth: 1.2)
        )
    }
    
    private func matrixCell(
        symbol: String,
        color: Color,
        textColor: Color = .black,
        quality: String,
        badge: String,
        badgeColor: Color
    ) -> some View {
        VStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 20, height: 20)
                .overlay(
                    Text(symbol)
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(textColor)
                )
            
            Text(badge)
                .font(.system(size: 7.5, weight: .bold, design: .monospaced))
                .foregroundColor(badgeColor)
            
            Text(quality)
                .font(.system(size: 8, weight: .medium, design: .monospaced))
                .foregroundColor(PastelTheme.textSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(Color(hex: "#101115"))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(PastelTheme.cardBorder.opacity(0.4), lineWidth: 0.8)
        )
    }
    
    // MARK: - B. Library Gaps Radar Section
    private var libraryGapsRadarSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(PastelTheme.warmAmber)
                    
                    Text("GAPS RADAR")
                        .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Text("\(gapItems.count) GAPS DETECTED")
                    .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                    .foregroundColor(PastelTheme.warmAmber)
            }
            
            VStack(spacing: 8) {
                ForEach(gapItems) { gap in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(gap.artist) — \(gap.title)")
                                .font(.system(size: 12.5, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            HStack(spacing: 4) {
                                Text(gap.sourceService.displayName)
                                    .foregroundColor(PastelTheme.athleticEmerald)
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 7))
                                    .foregroundColor(PastelTheme.textTertiary)
                                Text("Missing on \(gap.missingInService.displayName)")
                                    .foregroundColor(PastelTheme.warmAmber)
                            }
                            .font(.system(size: 9.5, weight: .medium))
                        }
                        
                        Spacer()
                        
                        let isBridged = bridgedTrackIds.contains(gap.id)
                        
                        Button {
                            HapticManager.heavyImpact()
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                _ = bridgedTrackIds.insert(gap.id)
                            }
                            showToast(message: "⚡️ «\(gap.title)» перенесён в \(gap.missingInService.displayName)!")
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: isBridged ? "checkmark" : "bolt.fill")
                                    .font(.system(size: 9, weight: .bold))
                                Text(isBridged ? "BRIDGED" : "BRIDGE")
                                    .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                            }
                            .foregroundColor(isBridged ? PastelTheme.athleticEmerald : PastelTheme.textOnOat)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(isBridged ? PastelTheme.athleticEmerald.opacity(0.15) : PastelTheme.pastelOat)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(isBridged ? PastelTheme.athleticEmerald : Color.clear, lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(isBridged)
                    }
                    .padding(10)
                    .background(Color(hex: "#121317"))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(PastelTheme.cardBorder.opacity(0.6), lineWidth: 0.8)
                    )
                }
            }
        }
    }
    
    // MARK: - C. Curated Genre Discovery Stations
    private var curatedStationsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("DISCOVERY STATIONS")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(PastelTheme.textTertiary)
                
                Spacer()
                
                Text("\(genreCategories.count) станций")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(PastelTheme.textTertiary)
            }
            
            let columns = [
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10)
            ]
            
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(genreCategories) { card in
                    Button {
                        HapticManager.lightImpact()
                        searchText = card.title
                    } label: {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color(hex: card.hexColor))
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Image(systemName: card.iconSymbol)
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                )
                            
                            VStack(alignment: .leading, spacing: 1) {
                                Text(card.title)
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                Text("#\(card.queryTag)")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundColor(PastelTheme.textSecondary)
                            }
                            
                            Spacer()
                        }
                        .padding(10)
                        .background(PastelTheme.card)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(PastelTheme.cardBorder, lineWidth: 0.8)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    // Dynamic Match Generator based on Search Query
    private var currentMatchSample: BridgeMatchSample {
        let q = searchText.lowercased()
        if q.contains("nightcall") || q.contains("kavinsky") {
            return BridgeMatchSample(
                title: "Nightcall",
                artist: "Kavinsky",
                album: "OutRun",
                year: "2013",
                artworkGradient: [Color(hex: "#78350F"), Color(hex: "#1E1B4B")],
                isrc: "FR6V81000004",
                spotifyAvailable: true,
                spotifyQuality: "320k Ogg",
                appleAvailable: true,
                appleQuality: "Lossless ALAC 24-bit",
                yandexAvailable: true,
                yandexQuality: "MP3 320k"
            )
        } else if q.contains("open.spotify.com") {
            return BridgeMatchSample(
                title: "Recognized from Spotify URL",
                artist: "Travis Scott",
                album: "UTOPIA (Original Web Drop)",
                year: "2023",
                artworkGradient: [Color(hex: "#15803D"), Color(hex: "#064E3B")],
                isrc: "USUM72308902",
                spotifyAvailable: true,
                spotifyQuality: "Source Master 320k",
                appleAvailable: true,
                appleQuality: "ISRC Resolved",
                yandexAvailable: true,
                yandexQuality: "Acoustic Matched"
            )
        } else {
            return BridgeMatchSample(
                title: "FE!N (feat. Playboi Carti)",
                artist: "Travis Scott",
                album: "UTOPIA",
                year: "2023",
                artworkGradient: [Color(hex: "#DC2626"), Color(hex: "#1F2937")],
                isrc: "USUM72308902",
                spotifyAvailable: true,
                spotifyQuality: "3:11 • Ogg 320k",
                appleAvailable: true,
                appleQuality: "ALAC Lossless 24-bit",
                yandexAvailable: true,
                yandexQuality: "MP3 320k Verified"
            )
        }
    }
    
    // 1-Tap Bridge Execution
    private func triggerSingleTrackBridge(_ sample: BridgeMatchSample) {
        HapticManager.heavyImpact()
        isBridgingActive = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            isBridgingActive = false
            HapticManager.successNotification()
            showToast(message: "⚡️ «\(sample.title)» перенесён в Apple Music через прямой ISRC-мост!")
        }
    }
    
    private func showToast(message: String) {
        toastMessage = message
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            showToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                showToast = false
            }
        }
    }
    
    // Floating HUD Toast Pill
    private func hudToast(message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(PastelTheme.athleticEmerald)
            
            Text(message)
                .font(.system(size: 11.5, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(hex: "#17181D"))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(PastelTheme.athleticEmerald.opacity(0.6), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.6), radius: 10, y: 4)
        .padding(.top, 56)
    }
}

// Backward-compatible typealias for seamless compilation
public typealias SpotifySearchBrowseView = BridgeRadarSearchView

#if DEBUG
struct BridgeRadarSearchView_Previews: PreviewProvider {
    static var previews: some View {
        BridgeRadarSearchView()
    }
}
#endif
