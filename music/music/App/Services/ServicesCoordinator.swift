import Foundation
import Combine
import SwiftUI

/// Main orchestrator for streaming providers and local library synchronization
@MainActor
public final class ServicesCoordinator: ObservableObject {
    public static let shared = ServicesCoordinator()
    
    @Published public var spotify = SpotifyProvider()
    @Published public var appleMusic = AppleMusicProvider()
    @Published public var yandexMusic = YandexMusicProvider()
    
    @Published public var isSyncing: Bool = false
    @Published public var allTracks: [UniversalTrack] = []
    @Published public var allPlaylists: [UniversalPlaylist] = []
    @Published public var lastErrorMessage: String?
    @Published public var lastSyncAt: Date?
    @Published public var lastSyncSummary: String = ""
    
    // MARK: - User Custom Avatar & Personalization
    private static let avatarKey = "soundshift_user_custom_avatar_data"
    private static let particlesKey = "soundshift_particles_enabled"
    private static let flaskStyleKey = "soundshift_flask_filling_style_key"
    
    @Published public var customAvatarData: Data? {
        didSet {
            if let data = customAvatarData {
                UserDefaults.standard.set(data, forKey: Self.avatarKey)
            } else {
                UserDefaults.standard.removeObject(forKey: Self.avatarKey)
            }
        }
    }
    
    @Published public var backgroundParticlesEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(backgroundParticlesEnabled, forKey: Self.particlesKey)
        }
    }
    
    @Published public var flaskFillingStyle: FlaskFillingStyle = .chronosStardust {
        didSet {
            UserDefaults.standard.set(flaskFillingStyle.rawValue, forKey: Self.flaskStyleKey)
        }
    }
    
    #if os(iOS)
    public var customAvatarImage: Image? {
        guard let data = customAvatarData, let uiImg = UIImage(data: data) else { return nil }
        return Image(uiImage: uiImg)
    }
    #else
    public var customAvatarImage: Image? {
        guard let data = customAvatarData, let nsImg = NSImage(data: data) else { return nil }
        return Image(nsImage: nsImg)
    }
    #endif
    
    public func saveCustomAvatar(data: Data) {
        self.customAvatarData = data
        HapticManager.successNotification()
    }
    
    public func clearCustomAvatar() {
        self.customAvatarData = nil
        HapticManager.lightImpact()
    }
    
    public func setFlaskFillingStyle(_ style: FlaskFillingStyle) {
        self.flaskFillingStyle = style
        HapticManager.lightImpact()
    }
    
    private init() {
        self.customAvatarData = UserDefaults.standard.data(forKey: Self.avatarKey)
        if UserDefaults.standard.object(forKey: Self.particlesKey) != nil {
            self.backgroundParticlesEnabled = UserDefaults.standard.bool(forKey: Self.particlesKey)
        } else {
            self.backgroundParticlesEnabled = true
        }
        
        if let savedStyleRaw = UserDefaults.standard.string(forKey: Self.flaskStyleKey),
           let savedStyle = FlaskFillingStyle(rawValue: savedStyleRaw) {
            self.flaskFillingStyle = savedStyle
        } else {
            self.flaskFillingStyle = .chronosStardust
        }
        
        let snapshot = LibrarySnapshotStore.load()
        self.allTracks = snapshot.tracks
        self.allPlaylists = snapshot.playlists
        self.lastSyncAt = snapshot.savedAt
        if let savedAt = snapshot.savedAt {
            self.lastSyncSummary = "Restored \(snapshot.tracks.count) tracks from device"
            _ = savedAt
        }
    }
    
    // MARK: - Aggregate Metrics (HUD)
    public var totalTracksCount: Int {
        max(allTracks.count, spotify.trackCount + appleMusic.trackCount + yandexMusic.trackCount)
    }
    
    public var activeProvidersCount: Int {
        var count = 0
        if spotify.isAuthenticated { count += 1 }
        if appleMusic.isAuthenticated { count += 1 }
        if yandexMusic.isAuthenticated { count += 1 }
        return count
    }
    
    public func provider(for type: MusicProviderType) -> any MusicProviderProtocol {
        switch type {
        case .spotify: return spotify
        case .appleMusic: return appleMusic
        case .yandexMusic: return yandexMusic
        }
    }
    
    public func authenticate(type: MusicProviderType) async {
        lastErrorMessage = nil
        
        if type == .yandexMusic && !YandexMusicProvider.isConnectorEnabled {
            lastErrorMessage = "Yandex Music is coming later (TestFlight). Connect Spotify or Apple Music now."
            HapticManager.errorNotification()
            return
        }
        
        isSyncing = true
        defer { isSyncing = false }
        
        do {
            let ok = try await provider(for: type).authenticate()
            guard ok else {
                lastErrorMessage = "\(type.displayName) authorization was not granted."
                HapticManager.errorNotification()
                return
            }
            await syncAll()
        } catch {
            lastErrorMessage = error.localizedDescription
            HapticManager.errorNotification()
            print("[ServicesCoordinator] Authentication failed for \(type.displayName): \(error)")
        }
    }
    
    public func revoke(type: MusicProviderType) async {
        lastErrorMessage = nil
        do {
            try await provider(for: type).revoke()
            // Remove tracks that only belonged to the revoked provider
            allTracks = allTracks.filter { track in
                switch type {
                case .spotify:
                    return !(track.spotifyId != nil && track.appleMusicId == nil && track.yandexId == nil)
                case .appleMusic:
                    return !(track.appleMusicId != nil && track.spotifyId == nil && track.yandexId == nil)
                case .yandexMusic:
                    return !(track.yandexId != nil && track.spotifyId == nil && track.appleMusicId == nil)
                }
            }
            allPlaylists = allPlaylists.filter { $0.providerType != type }
            persistSnapshot()
            refreshAggregates()
            HapticManager.lightImpact()
        } catch {
            lastErrorMessage = error.localizedDescription
            print("[ServicesCoordinator] Revoke failed for \(type.displayName): \(error)")
        }
    }
    
    public func syncAll() async {
        isSyncing = true
        lastErrorMessage = nil
        defer { isSyncing = false }
        
        var aggregatedTracks: [UniversalTrack] = []
        var aggregatedPlaylists: [UniversalPlaylist] = []
        var syncedProviders: [String] = []
        var failures: [String] = []
        
        for type in MusicProviderType.allCases {
            if type == .yandexMusic && !YandexMusicProvider.isConnectorEnabled {
                continue
            }
            let p = provider(for: type)
            guard p.isAuthenticated else { continue }
            
            // Demo / non-live sessions must not ingest mock catalogs into the snapshot.
            guard p.isLiveSession else {
                failures.append("\(type.displayName): Demo Mode — reconnect with a real account to sync (no mock library).")
                continue
            }
            
            do {
                let favs = try await p.fetchFavorites()
                aggregatedTracks.append(contentsOf: favs)
                var pls = try await p.fetchPlaylists()
                // Hydrate playlist track contents (bounded concurrency) so Transfer can use real rows
                pls = await Self.hydratePlaylistTracks(pls, using: p, concurrency: 3)
                aggregatedPlaylists.append(contentsOf: pls)
                syncedProviders.append(type.displayName)
            } catch {
                failures.append("\(type.displayName): \(error.localizedDescription)")
            }
        }
        
        // Never wipe a good snapshot when sync produced nothing usable.
        if syncedProviders.isEmpty {
            if !failures.isEmpty {
                lastErrorMessage = failures.joined(separator: "\n")
                lastSyncSummary = allTracks.isEmpty
                    ? "Sync failed — library unchanged"
                    : "Sync failed — kept \(allTracks.count) cached tracks"
                HapticManager.errorNotification()
            } else {
                lastSyncSummary = activeProvidersCount == 0
                    ? "Connect a service to import your library"
                    : "No live library data returned — cache kept"
            }
            refreshAggregates()
            return
        }
        
        // Deduplicate by ISRC when possible, else title+artist+duration
        self.allTracks = Self.deduplicate(aggregatedTracks)
        self.allPlaylists = aggregatedPlaylists
        self.lastSyncAt = Date()
        self.lastSyncSummary = "Synced \(allTracks.count) tracks from \(syncedProviders.joined(separator: ", "))"
        
        if !failures.isEmpty {
            lastErrorMessage = failures.joined(separator: "\n")
            HapticManager.errorNotification()
        } else {
            HapticManager.successNotification()
        }
        
        persistSnapshot()
        refreshAggregates()
    }
    
    private func persistSnapshot() {
        LibrarySnapshotStore.save(tracks: allTracks, playlists: allPlaylists)
    }
    
    private func refreshAggregates() {
        objectWillChange.send()
    }
    
    private static func hydratePlaylistTracks(
        _ playlists: [UniversalPlaylist],
        using provider: any MusicProviderProtocol,
        concurrency: Int
    ) async -> [UniversalPlaylist] {
        guard !playlists.isEmpty else { return playlists }
        
        var hydrated = playlists
        let ids = playlists.map(\.providerPlaylistId)
        var index = 0
        
        while index < ids.count {
            let end = min(index + max(concurrency, 1), ids.count)
            let slice = Array(ids[index..<end])
            
            await withTaskGroup(of: (String, [UniversalTrack]?).self) { group in
                for playlistId in slice {
                    group.addTask {
                        let tracks = try? await provider.fetchPlaylistTracks(providerPlaylistId: playlistId)
                        return (playlistId, tracks)
                    }
                }
                for await (playlistId, tracks) in group {
                    guard let tracks else { continue }
                    if let idx = hydrated.firstIndex(where: { $0.providerPlaylistId == playlistId }) {
                        hydrated[idx].tracks = tracks
                        hydrated[idx].trackCount = tracks.count
                    }
                }
            }
            
            index = end
        }
        
        return hydrated
    }
    
    private static func deduplicate(_ tracks: [UniversalTrack]) -> [UniversalTrack] {
        TrackDeduper.merge(tracks)
    }
    
    // MARK: - Local Playlist & Reorder Management
    public func createPlaylist(title: String, description: String? = nil, tracks: [UniversalTrack] = []) -> UniversalPlaylist {
        let pl = UniversalPlaylist(
            providerPlaylistId: "local_\(UUID().uuidString.prefix(8))",
            providerType: .spotify,
            title: title,
            description: description,
            trackCount: tracks.count,
            tracks: tracks
        )
        allPlaylists.insert(pl, at: 0)
        persistSnapshot()
        refreshAggregates()
        HapticManager.successNotification()
        return pl
    }
    
    /// Persist a playlist created via a live provider write into the local snapshot.
    public func ingestRemotePlaylist(_ playlist: UniversalPlaylist) {
        if let idx = allPlaylists.firstIndex(where: { $0.providerPlaylistId == playlist.providerPlaylistId && $0.providerType == playlist.providerType }) {
            allPlaylists[idx] = playlist
        } else {
            allPlaylists.insert(playlist, at: 0)
        }
        persistSnapshot()
        refreshAggregates()
    }
    
    public func deletePlaylist(id: UUID) {
        allPlaylists.removeAll { $0.id == id }
        persistSnapshot()
        refreshAggregates()
        HapticManager.lightImpact()
    }
    
    public func addTrackToPlaylist(track: UniversalTrack, playlistId: UUID) {
        if let idx = allPlaylists.firstIndex(where: { $0.id == playlistId }) {
            if !allPlaylists[idx].tracks.contains(where: { $0.id == track.id }) {
                allPlaylists[idx].tracks.append(track)
                allPlaylists[idx].trackCount = allPlaylists[idx].tracks.count
                persistSnapshot()
                refreshAggregates()
                HapticManager.lightImpact()
            }
        }
    }
    
    public func removeTrackFromPlaylist(track: UniversalTrack, playlistId: UUID) {
        if let idx = allPlaylists.firstIndex(where: { $0.id == playlistId }) {
            allPlaylists[idx].tracks.removeAll(where: { $0.id == track.id })
            allPlaylists[idx].trackCount = allPlaylists[idx].tracks.count
            persistSnapshot()
            refreshAggregates()
            HapticManager.lightImpact()
        }
    }
    
    public func reorderTracks(fromOffsets: IndexSet, toOffset: Int) {
        guard !allTracks.isEmpty else { return }
        guard let maxIdx = fromOffsets.max(), maxIdx < allTracks.count else { return }
        guard toOffset >= 0 && toOffset <= allTracks.count else { return }
        allTracks.move(fromOffsets: fromOffsets, toOffset: toOffset)
        persistSnapshot()
        refreshAggregates()
        HapticManager.lightImpact()
    }
    
    // MARK: - Universal Backup Export & Track Ingestion
    public func tracks(for type: MusicProviderType) -> [UniversalTrack] {
        allTracks.filter { track in
            switch type {
            case .spotify: return track.spotifyId != nil
            case .appleMusic: return track.appleMusicId != nil
            case .yandexMusic: return track.yandexId != nil
            }
        }
    }
    
    public func exportUniversalJSON(for tracks: [UniversalTrack]? = nil, filename: String = "SoundShift_Backup") -> URL? {
        struct BackupPayload: Codable {
            let exportedAt: Date
            let totalTracks: Int
            let tracks: [UniversalTrack]
            let playlists: [UniversalPlaylist]
        }
        
        let exportTracks = (tracks != nil && !tracks!.isEmpty) ? tracks! : allTracks
        guard !exportTracks.isEmpty else { return nil }
        let exportPlaylists = allPlaylists
        
        let payload = BackupPayload(
            exportedAt: Date(),
            totalTracks: exportTracks.count,
            tracks: exportTracks,
            playlists: exportPlaylists
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        
        guard let data = try? encoder.encode(payload) else { return nil }
        
        let tempUrl = FileManager.default.temporaryDirectory.appendingPathComponent("\(filename)_\(Int(Date().timeIntervalSince1970)).json")
        try? data.write(to: tempUrl)
        return tempUrl
    }
    
    public func exportCSV(for tracks: [UniversalTrack]? = nil, filename: String = "SoundShift_Tracks") -> URL? {
        let exportTracks = (tracks != nil && !tracks!.isEmpty) ? tracks! : allTracks
        guard !exportTracks.isEmpty else { return nil }
        var csv = "Title,Artist,Album,Duration,ISRC,Spotify_ID,Apple_ID,Yandex_ID\n"
        for t in exportTracks {
            let title = "\"\(t.title.replacingOccurrences(of: "\"", with: "\"\""))\""
            let artist = "\"\(t.primaryArtist.replacingOccurrences(of: "\"", with: "\"\""))\""
            let album = "\"\(t.album?.replacingOccurrences(of: "\"", with: "\"\"") ?? "")\""
            let duration = t.formattedDuration
            let isrc = t.isrc ?? ""
            let sId = t.spotifyId ?? ""
            let aId = t.appleMusicId ?? ""
            let yId = t.yandexId ?? ""
            csv += "\(title),\(artist),\(album),\(duration),\(isrc),\(sId),\(aId),\(yId)\n"
        }
        let tempUrl = FileManager.default.temporaryDirectory.appendingPathComponent("\(filename)_\(Int(Date().timeIntervalSince1970)).csv")
        try? csv.data(using: .utf8)?.write(to: tempUrl)
        return tempUrl
    }
    
    public func exportPlainText(for tracks: [UniversalTrack]? = nil, filename: String = "SoundShift_TrackList") -> URL? {
        let exportTracks = (tracks != nil && !tracks!.isEmpty) ? tracks! : allTracks
        guard !exportTracks.isEmpty else { return nil }
        var text = "# SoundShift Music Export (\(Date().formatted(date: .abbreviated, time: .shortened)))\n"
        text += "# Total tracks: \(exportTracks.count)\n\n"
        for (index, t) in exportTracks.enumerated() {
            text += "\(index + 1). \(t.primaryArtist) — \(t.title)\n"
        }
        let tempUrl = FileManager.default.temporaryDirectory.appendingPathComponent("\(filename)_\(Int(Date().timeIntervalSince1970)).txt")
        try? text.data(using: .utf8)?.write(to: tempUrl)
        return tempUrl
    }
    
    public func exportM3U(for tracks: [UniversalTrack]? = nil, filename: String = "SoundShift_Playlist") -> URL? {
        let exportTracks = (tracks != nil && !tracks!.isEmpty) ? tracks! : allTracks
        guard !exportTracks.isEmpty else { return nil }
        var m3u = "#EXTM3U\n# SoundShift export — open Spotify/Apple links in the matching app\n"
        for t in exportTracks {
            let durationSeconds = max(t.durationMs / 1000, -1)
            m3u += "#EXTINF:\(durationSeconds),\(t.primaryArtist) - \(t.title)\n"
            m3u += "\(Self.m3uEntryURL(for: t))\n"
        }
        let tempUrl = FileManager.default.temporaryDirectory.appendingPathComponent("\(filename)_\(Int(Date().timeIntervalSince1970)).m3u")
        try? m3u.data(using: .utf8)?.write(to: tempUrl)
        return tempUrl
    }
    
    /// Prefer real catalog deep links over fake `.mp3` filenames.
    public static func m3uEntryURL(for track: UniversalTrack) -> String {
        if let sp = track.spotifyId, !sp.isEmpty {
            return "https://open.spotify.com/track/\(sp)"
        }
        if let am = track.appleMusicId, !am.isEmpty {
            return "https://music.apple.com/song/\(am)"
        }
        if YandexMusicProvider.isConnectorEnabled, let yd = track.yandexId, !yd.isEmpty {
            return "https://music.yandex.ru/track/\(yd)"
        }
        let safeTitle = track.title.replacingOccurrences(of: "\n", with: " ")
        let safeArtist = track.primaryArtist.replacingOccurrences(of: "\n", with: " ")
        return "# no-stream-url \(safeArtist) - \(safeTitle)"
    }
    
    // MARK: - Universal Backup Import
    @discardableResult
    public func importUniversalJSON(from url: URL) -> Bool {
        struct BackupPayload: Codable {
            let exportedAt: Date
            let totalTracks: Int
            let tracks: [UniversalTrack]
            let playlists: [UniversalPlaylist]
        }
        
        guard let data = try? Data(contentsOf: url) else { return false }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        guard let payload = try? decoder.decode(BackupPayload.self, from: data) else { return false }
        
        self.allTracks = payload.tracks
        self.allPlaylists = payload.playlists
        self.lastSyncAt = Date()
        self.lastSyncSummary = "Imported \(payload.tracks.count) tracks from backup"
        persistSnapshot()
        HapticManager.successNotification()
        return true
    }
}
