import SwiftUI

/// Top-level filter routes for transferred songs
public enum TransferRouteFilter: String, CaseIterable, Identifiable {
    case all = "All Migrations"
    case yandexToApple = "Yandex → Apple"
    case spotifyToApple = "Spotify → Apple"
    case appleToSpotify = "Apple → Spotify"
    case yandexToSpotify = "Yandex → Spotify"
    case needsRematch = "Needs rematch"
    
    public var id: String { rawValue }
    
    /// Hide YM routes while Yandex connector is flagged off.
    public static var visibleCases: [TransferRouteFilter] {
        allCases.filter { route in
            switch route {
            case .yandexToApple, .yandexToSpotify:
                return YandexMusicProvider.isConnectorEnabled
            default:
                return true
            }
        }
    }
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
    
    // MARK: - Past Migration Sessions (real TransferManager history only)
    private var migrationSessions: [MigrationSessionSummary] {
        transferManager.history.map { report in
            let status: String
            if let error = report.errorMessage, !error.isEmpty {
                status = "Failed"
            } else if report.isNothingNewSuccess {
                status = "Already there"
            } else if report.didSucceed {
                status = report.missingTracks.isEmpty ? "Completed" : "Partial"
            } else {
                status = "Empty"
            }
            return MigrationSessionSummary(
                id: report.id,
                sourceService: report.sourceProvider,
                destinationService: report.destinationProvider,
                timestampStr: report.timestamp.formatted(date: .abbreviated, time: .shortened),
                scopeName: report.createdPlaylistName
                    ?? (report.isNothingNewSuccess ? "Nothing new to write" : "Migration job"),
                successfullyTransferred: report.successfullyTransferred,
                totalTracks: report.totalTracks,
                matchRate: report.matchRate,
                durationSeconds: report.durationSeconds,
                status: status
            )
        }
    }
    
    // MARK: - Unresolved / missing tracks from latest report (not successful writes)
    private var transferredRecords: [TransferredTrackRecord] {
        guard let last = transferManager.lastReport ?? transferManager.history.first else { return [] }
        return last.missingTracks.prefix(50).map { track in
            TransferredTrackRecord(
                id: track.id,
                title: track.title,
                artist: track.primaryArtist,
                album: track.album ?? "",
                sourceService: last.sourceProvider,
                destinationService: last.destinationProvider,
                matchType: last.errorMessage != nil ? "Transfer failed" : "Needs rematch",
                isrc: track.isrc ?? "",
                durationMs: track.durationMs,
                isSuccess: false,
                transferDateStr: last.timestamp.formatted(date: .abbreviated, time: .omitted)
            )
        }
    }
    
    private func statusAccent(for status: String) -> Color {
        switch status {
        case "Completed": return PastelTheme.emeraldSuccess
        case "Partial": return PastelTheme.amberWarning
        case "Failed": return Color.red.opacity(0.85)
        default: return PastelTheme.textTertiary
        }
    }
    
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
        case .appleToSpotify:
            list = list.filter { $0.sourceService == .appleMusic && $0.destinationService == .spotify }
        case .yandexToSpotify:
            list = list.filter { $0.sourceService == .yandexMusic && $0.destinationService == .spotify }
        case .needsRematch:
            list = list.filter {
                $0.matchType.localizedCaseInsensitiveContains("rematch")
                    || $0.matchType.localizedCaseInsensitiveContains("failed")
            }
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
                        
                        syncedCollectionCard
                        
                        if migrationSessions.isEmpty {
                            emptyMigrationsCard
                        } else {
                            migrationSessionsSection
                        }
                        
                        if !transferredRecords.isEmpty {
                            transferredSearchBar
                            routeFilterStrip
                            transferredTracksSection
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 120) // Full clearance for Floating Mini Player
                }
            }
            #if os(iOS)
            .navigationBarHidden(true)
            #endif
            .sheet(item: $selectedSessionForReport) { session in
                if let report = transferManager.history.first(where: { $0.id == session.id })
                    ?? transferManager.lastReport {
                    TransferReportView(report: report)
                } else {
                    TransferReportView(
                        report: TransferExecutionReport(
                            id: session.id,
                            sourceProvider: session.sourceService,
                            destinationProvider: session.destinationService,
                            totalTracks: session.totalTracks,
                            successfullyTransferred: session.successfullyTransferred,
                            durationSeconds: session.durationSeconds,
                            createdPlaylistName: session.scopeName == "Migration job" ? nil : session.scopeName
                        )
                    )
                }
            }
        }
    }
    
    private var syncedCollectionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Synced Collection")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(PastelTheme.textPrimary)
                    Text(coordinator.activeProvidersCount == 0
                         ? "Connect Spotify or Apple Music to import liked songs."
                         : "\(coordinator.allTracks.count) tracks · \(coordinator.allPlaylists.count) playlists")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(PastelTheme.textSecondary)
                }
                Spacer()
                if coordinator.isSyncing {
                    ProgressView().tint(PastelTheme.pastelOat)
                }
            }
            
            HStack(spacing: 10) {
                if coordinator.activeProvidersCount == 0 {
                    Button {
                        NavigationCoordinator.shared.navigateToConnect()
                    } label: {
                        Text("Connect services")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(PastelTheme.textOnOat)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(PastelTheme.pastelOat)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    Button {
                        Task { await coordinator.syncAll() }
                    } label: {
                        Text("Sync now")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(PastelTheme.textOnOat)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(PastelTheme.pastelOat)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button {
                        navCoordinator.openPersonalLibrary()
                    } label: {
                        Text("Open collection")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(PastelTheme.pastelOat)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(PastelTheme.cardSubtle)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(16)
        .background(PastelTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(PastelTheme.cardBorder, lineWidth: 1)
        )
    }
    
    private var emptyMigrationsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Migration History")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(PastelTheme.textPrimary)
            Text("No transfers yet. Run a migration from Create — reports land here automatically.")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(PastelTheme.textSecondary)
            Button {
                NavigationCoordinator.shared.navigateToCreate()
            } label: {
                Text("Go to Create")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(PastelTheme.pastelOat)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.top, 4)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PastelTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(PastelTheme.cardBorder, lineWidth: 1)
        )
    }
    
    // MARK: - 1. Header Bar with Direct 1-Tap Bridge to Personal Library
    private var libraryHeaderBar: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Library")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(PastelTheme.textPrimary)
                
                Text(coordinator.allTracks.isEmpty
                       ? "Sync a service to fill your collection"
                       : "\(coordinator.allTracks.count) synced tracks · migration history below")
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
                    
                    // Status pill — color matches Completed / Partial / Failed
                    let accent = statusAccent(for: session.status)
                    HStack(spacing: 4) {
                        Circle()
                            .fill(accent)
                            .frame(width: 6, height: 6)
                        Text(session.status)
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(accent)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(accent.opacity(0.12))
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
                ForEach(TransferRouteFilter.visibleCases) { route in
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
                Text("Needs attention (\(filteredRecords.count))")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(PastelTheme.textPrimary)
                
                Spacer()
                
                Text("Missing / rematch")
                    .font(.system(size: 12))
                    .foregroundColor(PastelTheme.amberWarning)
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
                    
                    // Status icon & Date — missing tracks are not successes
                    VStack(alignment: .trailing, spacing: 6) {
                        Image(systemName: record.isSuccess ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                            .font(.system(size: 15))
                            .foregroundColor(record.isSuccess ? PastelTheme.emeraldSuccess : PastelTheme.amberWarning)
                        
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
                #if os(iOS)
                UIPasteboard.general.string = "\(record.title) - \(record.artist) (ISRC: \(record.isrc))"
                #elseif os(macOS)
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString("\(record.title) - \(record.artist) (ISRC: \(record.isrc))", forType: .string)
                #endif
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
