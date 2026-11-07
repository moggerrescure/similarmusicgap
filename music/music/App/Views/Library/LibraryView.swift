import SwiftUI

/// Top-level filter routes for transferred songs
public enum TransferRouteFilter: String, CaseIterable, Identifiable {
    case all = "All Migrations"
    case yandexToApple = "Yandex → Apple"
    case spotifyToApple = "Spotify → Apple"
    case yandexToSpotify = "Yandex → Spotify"
    case exactISRC = "100% ISRC"
    
    public var id: String { rawValue }
}

/// Transferred Track Item Model with Migration Provenance
public struct TransferredTrackRecord: Identifiable {
    public let id: UUID
    public let title: String
    public let artist: String
    public let album: String
    public let sourceService: MusicProviderType
    public let destinationService: MusicProviderType
    public let matchType: String
    public let isrc: String
    public let durationMs: Int
    public let isSuccess: Bool
    public let transferDateStr: String
    
    public init(
        id: UUID = UUID(),
        title: String,
        artist: String,
        album: String,
        sourceService: MusicProviderType,
        destinationService: MusicProviderType,
        matchType: String = "100% ISRC Match",
        isrc: String,
        durationMs: Int = 210000,
        isSuccess: Bool = true,
        transferDateStr: String = "Today"
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.album = album
        self.sourceService = sourceService
        self.destinationService = destinationService
        self.matchType = matchType
        self.isrc = isrc
        self.durationMs = durationMs
        self.isSuccess = isSuccess
        self.transferDateStr = transferDateStr
    }
    
    public var asUniversalTrack: UniversalTrack {
        UniversalTrack(
            isrc: isrc,
            title: title,
            artists: [artist],
            album: album,
            durationMs: durationMs,
            yandexId: sourceService == .yandexMusic ? "ydx_\(id)" : nil,
            spotifyId: sourceService == .spotify ? "sp_\(id)" : (destinationService == .spotify ? "sp_\(id)" : nil),
            appleMusicId: destinationService == .appleMusic ? "apl_\(id)" : nil
        )
    }
}

/// Migration Session Log Card Model (История того, что происходило и насколько успешно)
public struct MigrationSessionSummary: Identifiable {
    public let id: UUID
    public let sourceService: MusicProviderType
    public let destinationService: MusicProviderType
    public let timestampStr: String
    public let scopeName: String
    public let successfullyTransferred: Int
    public let totalTracks: Int
    public let matchRate: Double
    public let durationSeconds: Double
    public let status: String
    
    public init(
        id: UUID = UUID(),
        sourceService: MusicProviderType,
        destinationService: MusicProviderType,
        timestampStr: String,
        scopeName: String,
        successfullyTransferred: Int,
        totalTracks: Int,
        matchRate: Double,
        durationSeconds: Double,
        status: String = "Completed"
    ) {
        self.id = id
        self.sourceService = sourceService
        self.destinationService = destinationService
        self.timestampStr = timestampStr
        self.scopeName = scopeName
        self.successfullyTransferred = successfullyTransferred
        self.totalTracks = totalTracks
        self.matchRate = matchRate
        self.durationSeconds = durationSeconds
        self.status = status
    }
}

/// Screen: Library Tab transformed into Migration History & Transferred Songs Vault
/// Displays all songs transferred (e.g. Yandex -> Apple, Spotify -> Apple) with migration provenance,
/// success rates, and an interactive log of past migrations.
public struct LibraryView: View {
    @ObservedObject private var player = AudioPlayerManager.shared
    @ObservedObject private var coordinator = ServicesCoordinator.shared
    @ObservedObject private var transferManager = TransferManager.shared
    @ObservedObject private var navCoordinator = NavigationCoordinator.shared
    
    @State private var searchText: String = ""
    @State private var selectedFilter: TransferRouteFilter = .all
    @State private var selectedSessionForReport: MigrationSessionSummary? = nil
    
    // MARK: - Past Migration Sessions (История того, что происходило)
    private let migrationSessions: [MigrationSessionSummary] = [
        MigrationSessionSummary(
            sourceService: .yandexMusic,
            destinationService: .appleMusic,
            timestampStr: "Today, 14:20",
            scopeName: "Favorite Tracks & 3 Playlists",
            successfullyTransferred: 482,
            totalTracks: 486,
            matchRate: 99.2,
            durationSeconds: 3.4
        ),
        MigrationSessionSummary(
            sourceService: .spotify,
            destinationService: .appleMusic,
            timestampStr: "Nov 5, 2026",
            scopeName: "Liked Songs Vault",
            successfullyTransferred: 312,
            totalTracks: 318,
            matchRate: 98.1,
            durationSeconds: 2.8
        ),
        MigrationSessionSummary(
            sourceService: .yandexMusic,
            destinationService: .spotify,
            timestampStr: "Oct 28, 2026",
            scopeName: "Russian Indie & Rock Vault",
            successfullyTransferred: 50,
            totalTracks: 50,
            matchRate: 100.0,
            durationSeconds: 1.2
        )
    ]
    
    // MARK: - Pool of Transferred Tracks (Все перемещённые песни)
    private let transferredRecords: [TransferredTrackRecord] = [
        // 1. Yandex -> Apple Music
        TransferredTrackRecord(
            title: "Где нас нет",
            artist: "Oxxxymiron",
            album: "ГОРГОРОД",
            sourceService: .yandexMusic,
            destinationService: .appleMusic,
            matchType: "100% ISRC Match",
            isrc: "RUAA12000042",
            durationMs: 265000,
            transferDateStr: "Today"
        ),
        TransferredTrackRecord(
            title: "заставь меня плакать",
            artist: "CUPSIZE",
            album: "Королева двора",
            sourceService: .yandexMusic,
            destinationService: .appleMusic,
            matchType: "High Confidence Match",
            isrc: "RUA112300091",
            durationMs: 185000,
            transferDateStr: "Today"
        ),
        TransferredTrackRecord(
            title: "Город под подошвой",
            artist: "Oxxxymiron",
            album: "Город под подошвой",
            sourceService: .yandexMusic,
            destinationService: .appleMusic,
            matchType: "100% ISRC Match",
            isrc: "RUAA11500012",
            durationMs: 247000,
            transferDateStr: "Today"
        ),
        TransferredTrackRecord(
            title: "Instant Crush",
            artist: "Daft Punk, Julian Casablancas",
            album: "Random Access Memories",
            sourceService: .yandexMusic,
            destinationService: .appleMusic,
            matchType: "100% ISRC Match",
            isrc: "FRUM71300088",
            durationMs: 337560,
            transferDateStr: "Today"
        ),
        TransferredTrackRecord(
            title: "Судно (Борис Рыжий)",
            artist: "Молчат Дома",
            album: "Этажи",
            sourceService: .yandexMusic,
            destinationService: .appleMusic,
            matchType: "100% ISRC Match",
            isrc: "DEZ651900143",
            durationMs: 141000,
            transferDateStr: "Today"
        ),
        TransferredTrackRecord(
            title: "Барбисайз",
            artist: "Дора, Мэйби Бэйби",
            album: "МЕНТАЛЬНЫЙ",
            sourceService: .yandexMusic,
            destinationService: .appleMusic,
            matchType: "100% ISRC Match",
            isrc: "RUAA12000318",
            durationMs: 168000,
            transferDateStr: "Today"
        ),
        TransferredTrackRecord(
            title: "Поезда",
            artist: "Молчат Дома",
            album: "С крыш наших домов",
            sourceService: .yandexMusic,
            destinationService: .appleMusic,
            matchType: "100% ISRC Match",
            isrc: "DEZ651700082",
            durationMs: 236000,
            transferDateStr: "Today"
        ),
        TransferredTrackRecord(
            title: "5 минут назад",
            artist: "Pharaoh, Boulevard Depo",
            album: "Плакшери",
            sourceService: .yandexMusic,
            destinationService: .appleMusic,
            matchType: "100% ISRC Match",
            isrc: "RUAA11600045",
            durationMs: 202000,
            transferDateStr: "Today"
        ),
        
        // 2. Spotify -> Apple Music
        TransferredTrackRecord(
            title: "Starboy",
            artist: "The Weeknd, Daft Punk",
            album: "Starboy",
            sourceService: .spotify,
            destinationService: .appleMusic,
            matchType: "100% ISRC Match",
            isrc: "USUM71703861",
            durationMs: 230453,
            transferDateStr: "Nov 5"
        ),
        TransferredTrackRecord(
            title: "The Less I Know the Better",
            artist: "Tame Impala",
            album: "Currents",
            sourceService: .spotify,
            destinationService: .appleMusic,
            matchType: "100% ISRC Match",
            isrc: "GBUM71505080",
            durationMs: 216320,
            transferDateStr: "Nov 5"
        ),
        TransferredTrackRecord(
            title: "Blinding Lights",
            artist: "The Weeknd",
            album: "After Hours",
            sourceService: .spotify,
            destinationService: .appleMusic,
            matchType: "100% ISRC Match",
            isrc: "USAT21900122",
            durationMs: 200040,
            transferDateStr: "Nov 5"
        ),
        TransferredTrackRecord(
            title: "Midnight City",
            artist: "M83",
            album: "Hurry Up, We're Dreaming",
            sourceService: .spotify,
            destinationService: .appleMusic,
            matchType: "100% ISRC Match",
            isrc: "USWB11200021",
            durationMs: 243000,
            transferDateStr: "Nov 5"
        ),
        TransferredTrackRecord(
            title: "UTOPIA",
            artist: "Travis Scott",
            album: "UTOPIA",
            sourceService: .spotify,
            destinationService: .appleMusic,
            matchType: "100% ISRC Match",
            isrc: "USSM12304910",
            durationMs: 215000,
            transferDateStr: "Nov 5"
        ),
        TransferredTrackRecord(
            title: "Kill Bill",
            artist: "SZA",
            album: "SOS",
            sourceService: .spotify,
            destinationService: .appleMusic,
            matchType: "100% ISRC Match",
            isrc: "USRC12204128",
            durationMs: 153000,
            transferDateStr: "Nov 5"
        ),
        TransferredTrackRecord(
            title: "vampire",
            artist: "Olivia Rodrigo",
            album: "GUTS",
            sourceService: .spotify,
            destinationService: .appleMusic,
            matchType: "100% ISRC Match",
            isrc: "USUG12303810",
            durationMs: 219000,
            transferDateStr: "Nov 5"
        ),
        
        // 3. Yandex -> Spotify
        TransferredTrackRecord(
            title: "Искала",
            artist: "Zemfira",
            album: "Прости меня моя любовь",
            sourceService: .yandexMusic,
            destinationService: .spotify,
            matchType: "100% ISRC Match",
            isrc: "RUAA10000008",
            durationMs: 213000,
            transferDateStr: "Oct 28"
        ),
        TransferredTrackRecord(
            title: "Полковнику никто не пишет",
            artist: "Би-2",
            album: "Би-2",
            sourceService: .yandexMusic,
            destinationService: .spotify,
            matchType: "100% ISRC Match",
            isrc: "RUAA10100045",
            durationMs: 292000,
            transferDateStr: "Oct 28"
        ),
        TransferredTrackRecord(
            title: "дели на два",
            artist: "CUPSIZE",
            album: "дели на два",
            sourceService: .yandexMusic,
            destinationService: .spotify,
            matchType: "100% ISRC Match",
            isrc: "RUA112300104",
            durationMs: 172000,
            transferDateStr: "Oct 28"
        ),
        TransferredTrackRecord(
            title: "синий кит",
            artist: "влад пиво",
            album: "влад пиво singles",
            sourceService: .yandexMusic,
            destinationService: .spotify,
            matchType: "Acoustic Match",
            isrc: "RUA112400032",
            durationMs: 198000,
            transferDateStr: "Oct 28"
        ),
        TransferredTrackRecord(
            title: "Люди",
            artist: "Дайте танк (!)",
            album: "Человеко-часы",
            sourceService: .yandexMusic,
            destinationService: .spotify,
            matchType: "100% ISRC Match",
            isrc: "RUAA12000781",
            durationMs: 189000,
            transferDateStr: "Oct 28"
        )
    ]
    
    // Filtered transferred tracks
    private var filteredRecords: [TransferredTrackRecord] {
        var list = transferredRecords
        
        switch selectedFilter {
        case .all:
            break
        case .yandexToApple:
            list = list.filter { $0.sourceService == .yandexMusic && $0.destinationService == .appleMusic }
        case .spotifyToApple:
            list = list.filter { $0.sourceService == .spotify && $0.destinationService == .appleMusic }
        case .yandexToSpotify:
            list = list.filter { $0.sourceService == .yandexMusic && $0.destinationService == .spotify }
        case .exactISRC:
            list = list.filter { $0.matchType.contains("ISRC") }
        }
        
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !query.isEmpty {
            list = list.filter {
                $0.title.lowercased().contains(query) ||
                $0.artist.lowercased().contains(query) ||
                $0.album.lowercased().contains(query) ||
                $0.sourceService.displayName.lowercased().contains(query) ||
                $0.destinationService.displayName.lowercased().contains(query)
            }
        }
        
        return list
    }
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                // Dynamic Ambient Gradient Wash (Library Tone)
                AmbientWashBackgroundView(tab: .library)
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        // 1. Header Bar with Direct Bridge to User Personal Library
                        libraryHeaderBar
                            .padding(.top, 10)
                        
                        // 2. Migration History Carousel (История того, что происходило)
                        migrationSessionsSection
                        
                        // 4. Sticky Search & Route Filter Bar
                        transferredSearchBar
                        
                        routeFilterStrip
                        
                        // 5. Transferred Tracks List (Все песни, перемещённые между сервисами)
                        transferredTracksSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 120) // Full clearance for Floating Mini Player
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $selectedSessionForReport) { session in
                let report = TransferExecutionReport(
                    sourceProvider: session.sourceService,
                    destinationProvider: session.destinationService,
                    totalTracks: session.totalTracks,
                    successfullyTransferred: session.successfullyTransferred,
                    durationSeconds: session.durationSeconds
                )
                TransferReportView(report: report)
            }
        }
    }
    
    // MARK: - 1. Header Bar with Direct 1-Tap Bridge to Personal Library
    private var libraryHeaderBar: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Library")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(PastelTheme.textPrimary)
                
                Text("Transferred songs & migration history")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(PastelTheme.textSecondary)
            }
            
            Spacer()
            
            // 1-Tap Bridge to "Liked Songs & Playlists"
            Button {
                HapticManager.lightImpact()
                navCoordinator.openPersonalLibrary()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 12))
                        .foregroundColor(PastelTheme.emeraldSuccess)
                    
                    Text("Liked Songs")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(PastelTheme.textOnOat)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(PastelTheme.pastelOat)
                .clipShape(Capsule())
                .shadow(color: Color.black.opacity(0.3), radius: 4, y: 2)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - 2. Migration History Carousel (История того, что происходило)
    private var migrationSessionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Migration History")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(PastelTheme.textPrimary)
                
                Spacer()
                
                Text("Tap for report")
                    .font(.system(size: 12))
                    .foregroundColor(PastelTheme.textTertiary)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(migrationSessions) { session in
                        migrationSessionCard(session: session)
                    }
                }
            }
        }
    }
    
    private func migrationSessionCard(session: MigrationSessionSummary) -> some View {
        Button {
            HapticManager.lightImpact()
            selectedSessionForReport = session
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                // Top: Platforms & Status
                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        PlatformBrandBadgeView(type: session.sourceService, size: 16)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(PastelTheme.textTertiary)
                        PlatformBrandBadgeView(type: session.destinationService, size: 16)
                    }
                    
                    Spacer()
                    
                    // Completed status pill
                    HStack(spacing: 4) {
                        Circle()
                            .fill(PastelTheme.emeraldSuccess)
                            .frame(width: 6, height: 6)
                        Text(session.status)
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(PastelTheme.emeraldSuccess)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(PastelTheme.emeraldSuccess.opacity(0.12))
                    .clipShape(Capsule())
                }
                
                // Scope & Date
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(session.sourceService.displayName) → \(session.destinationService.displayName)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(PastelTheme.textPrimary)
                        .lineLimit(1)
                    
                    Text("\(session.scopeName) • \(session.timestampStr)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(PastelTheme.textSecondary)
                        .lineLimit(1)
                }
                
                // Progress Bar & Success Metric
                VStack(spacing: 5) {
                    HStack {
                        Text("\(session.successfullyTransferred) / \(session.totalTracks) songs")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(PastelTheme.pastelOat)
                        
                        Spacer()
                        
                        Text(String(format: "%.1f%%", session.matchRate))
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(PastelTheme.emeraldSuccess)
                    }
                    
                    // Thin progress track
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 4)
                            
                            Capsule()
                                .fill(PastelTheme.emeraldSuccess)
                                .frame(width: geo.size.width * CGFloat(session.matchRate / 100.0), height: 4)
                        }
                    }
                    .frame(height: 4)
                }
            }
            .padding(14)
            .frame(width: 250)
            .background(PastelTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - 4. Sticky Search & Route Filter Bar
    private var transferredSearchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(PastelTheme.textTertiary)
            
            TextField("Search transferred songs, artists, routes...", text: $searchText)
                .font(.system(size: 14))
                .foregroundColor(PastelTheme.textPrimary)
                .autocorrectionDisabled()
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(PastelTheme.textTertiary)
                }
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 44)
        .background(PastelTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(PastelTheme.cardBorder, lineWidth: 1)
        )
    }
    
    private var routeFilterStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TransferRouteFilter.allCases) { route in
                    let isSel = selectedFilter == route
                    Button {
                        HapticManager.lightImpact()
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            selectedFilter = route
                        }
                    } label: {
                        Text(route.rawValue)
                            .font(.system(size: 12, weight: isSel ? .bold : .medium, design: .rounded))
                            .foregroundColor(isSel ? PastelTheme.textOnOat : PastelTheme.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(isSel ? PastelTheme.pastelOat : PastelTheme.card)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(isSel ? Color.clear : PastelTheme.marbleBorder, lineWidth: 1)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    // MARK: - 5. Transferred Tracks List (Все песни, перемещённые между сервисами)
    private var transferredTracksSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("All Transferred Tracks (\(filteredRecords.count))")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(PastelTheme.textPrimary)
                
                Spacer()
                
                Text("Tap to play")
                    .font(.system(size: 12))
                    .foregroundColor(PastelTheme.textTertiary)
            }
            
            LazyVStack(spacing: 0) {
                ForEach(filteredRecords) { record in
                    transferredTrackRow(record: record)
                }
            }
        }
    }
    
    private func transferredTrackRow(record: TransferredTrackRecord) -> some View {
        let uTrack = record.asUniversalTrack
        let isCurr = player.currentTrack?.title == record.title
        let isPlaying = isCurr && player.isPlaying
        
        return Button {
            HapticManager.lightImpact()
            if isCurr {
                player.togglePlayPause()
            } else {
                player.play(track: uTrack)
            }
        } label: {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    // Mini Circular Disc Artwork
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "#1E2026"), Color(hex: "#111317")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)
                        
                        if isPlaying {
                            WaveformBarsView()
                        } else if isCurr {
                            Image(systemName: "play.fill")
                                .font(.system(size: 13))
                                .foregroundColor(PastelTheme.pastelOat)
                        } else {
                            Image(systemName: "opticaldisc")
                                .font(.system(size: 18))
                                .foregroundColor(PastelTheme.pastelOat.opacity(0.8))
                        }
                    }
                    
                    // Title, Artist & Album
                    VStack(alignment: .leading, spacing: 3) {
                        Text(record.title)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(isCurr ? PastelTheme.pastelOat : PastelTheme.textPrimary)
                            .lineLimit(1)
                        
                        HStack(spacing: 4) {
                            Text(record.artist)
                                .foregroundColor(PastelTheme.textSecondary)
                            Text("•")
                                .foregroundColor(PastelTheme.textTertiary)
                            Text(record.album)
                                .foregroundColor(PastelTheme.textTertiary)
                                .lineLimit(1)
                        }
                        .font(.system(size: 12))
                        
                        // Clean Route Badge (No green labels, no separate outlines)
                        HStack(spacing: 4) {
                            PlatformBrandBadgeView(type: record.sourceService, size: 11)
                            Image(systemName: "arrow.right")
                                .font(.system(size: 7, weight: .bold))
                                .foregroundColor(PastelTheme.textTertiary)
                            PlatformBrandBadgeView(type: record.destinationService, size: 11)
                            Text("\(record.sourceService.displayName) → \(record.destinationService.displayName)")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundColor(PastelTheme.textSecondary)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(PastelTheme.cardSubtle)
                        .clipShape(Capsule())
                        .padding(.top, 2)
                    }
                    
                    Spacer()
                    
                    // Status Checkmark & Date
                    VStack(alignment: .trailing, spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 15))
                            .foregroundColor(PastelTheme.emeraldSuccess)
                        
                        Text(record.transferDateStr)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(PastelTheme.textTertiary)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 9)
                .background(isCurr ? PastelTheme.pastelOat.opacity(0.08) : Color.clear)
                .contentShape(Rectangle())
                
                // Fine hairline divider
                Rectangle()
                    .fill(Color.white.opacity(0.06))
                    .frame(height: 0.5)
                    .padding(.leading, 64)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            Button {
                player.play(track: uTrack)
            } label: {
                Label("Play Now", systemImage: "play.circle")
            }
            Button {
                UIPasteboard.general.string = "\(record.title) - \(record.artist) (ISRC: \(record.isrc))"
                HapticManager.successNotification()
            } label: {
                Label("Copy Song & ISRC", systemImage: "doc.on.doc")
            }
            Button {
                navCoordinator.openPersonalLibrary()
            } label: {
                Label("Open Liked Songs & Playlists", systemImage: "heart")
            }
        }
    }
}
