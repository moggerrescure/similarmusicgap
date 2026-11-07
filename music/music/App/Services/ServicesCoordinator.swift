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
        
        refreshAggregates()
    }
    
    // MARK: - Aggregate Metrics (HUD)
    public var totalTracksCount: Int {
        spotify.trackCount + appleMusic.trackCount + yandexMusic.trackCount
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
        isSyncing = true
        defer { isSyncing = false }
        
        do {
            _ = try await provider(for: type).authenticate()
            await syncAll()
        } catch {
            print("[ServicesCoordinator] Authentication failed for \(type.displayName): \(error)")
        }
    }
    
    public func revoke(type: MusicProviderType) async {
        do {
            try await provider(for: type).revoke()
            refreshAggregates()
        } catch {
            print("[ServicesCoordinator] Revoke failed for \(type.displayName): \(error)")
        }
    }
    
    public func syncAll() async {
        isSyncing = true
        defer { isSyncing = false }
        
        var aggregatedTracks: [UniversalTrack] = []
        var aggregatedPlaylists: [UniversalPlaylist] = []
        
        for type in MusicProviderType.allCases {
            let p = provider(for: type)
            if p.isAuthenticated {
                if let favs = try? await p.fetchFavorites() {
                    aggregatedTracks.append(contentsOf: favs)
                }
                if let pls = try? await p.fetchPlaylists() {
                    aggregatedPlaylists.append(contentsOf: pls)
                }
            }
        }
        
        self.allTracks = aggregatedTracks
        self.allPlaylists = aggregatedPlaylists
        HapticManager.successNotification()
    }
    
    private func refreshAggregates() {
        objectWillChange.send()
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
        refreshAggregates()
        HapticManager.successNotification()
        return pl
    }
    
    public func deletePlaylist(id: UUID) {
        allPlaylists.removeAll { $0.id == id }
        refreshAggregates()
        HapticManager.lightImpact()
    }
    
    public func addTrackToPlaylist(track: UniversalTrack, playlistId: UUID) {
        if let idx = allPlaylists.firstIndex(where: { $0.id == playlistId }) {
            if !allPlaylists[idx].tracks.contains(where: { $0.id == track.id }) {
                allPlaylists[idx].tracks.append(track)
                allPlaylists[idx].trackCount = allPlaylists[idx].tracks.count
                refreshAggregates()
                HapticManager.lightImpact()
            }
        }
    }
    
    public func removeTrackFromPlaylist(track: UniversalTrack, playlistId: UUID) {
        if let idx = allPlaylists.firstIndex(where: { $0.id == playlistId }) {
            allPlaylists[idx].tracks.removeAll(where: { $0.id == track.id })
            allPlaylists[idx].trackCount = allPlaylists[idx].tracks.count
            refreshAggregates()
            HapticManager.lightImpact()
        }
    }
    
    public func reorderTracks(fromOffsets: IndexSet, toOffset: Int) {
        guard !allTracks.isEmpty else { return }
        guard let maxIdx = fromOffsets.max(), maxIdx < allTracks.count else { return }
        guard toOffset >= 0 && toOffset <= allTracks.count else { return }
        allTracks.move(fromOffsets: fromOffsets, toOffset: toOffset)
        refreshAggregates()
        HapticManager.lightImpact()
    }
    
    // MARK: - Universal Backup Export & Track Ingestion
    public func tracks(for type: MusicProviderType) -> [UniversalTrack] {
        let matching = allTracks.filter { track in
            switch type {
            case .spotify: return track.spotifyId != nil
            case .appleMusic: return track.appleMusicId != nil
            case .yandexMusic: return track.yandexId != nil
            }
        }
        if !matching.isEmpty { return matching }
        // Fallback to sample library if not yet synced
        return spotify.sampleMockTracks
    }
    
    public func exportUniversalJSON(for tracks: [UniversalTrack]? = nil, filename: String = "SoundShift_Backup") -> URL? {
        struct BackupPayload: Codable {
            let exportedAt: Date
            let totalTracks: Int
            let tracks: [UniversalTrack]
            let playlists: [UniversalPlaylist]
        }
        
        let exportTracks = (tracks != nil && !tracks!.isEmpty) ? tracks! : (allTracks.isEmpty ? spotify.sampleMockTracks : allTracks)
        let exportPlaylists = allPlaylists.isEmpty ? [
            UniversalPlaylist(providerPlaylistId: "pl_backup", providerType: .spotify, title: "Favorites Vault", trackCount: exportTracks.count, tracks: exportTracks)
        ] : allPlaylists
        
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
        let exportTracks = (tracks != nil && !tracks!.isEmpty) ? tracks! : (allTracks.isEmpty ? spotify.sampleMockTracks : allTracks)
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
        let exportTracks = (tracks != nil && !tracks!.isEmpty) ? tracks! : (allTracks.isEmpty ? spotify.sampleMockTracks : allTracks)
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
        let exportTracks = (tracks != nil && !tracks!.isEmpty) ? tracks! : (allTracks.isEmpty ? spotify.sampleMockTracks : allTracks)
        var m3u = "#EXTM3U\n"
        for t in exportTracks {
            let durationSeconds = t.durationMs / 1000
            m3u += "#EXTINF:\(durationSeconds),\(t.primaryArtist) - \(t.title)\n"
            m3u += "\(t.title).mp3\n"
        }
        let tempUrl = FileManager.default.temporaryDirectory.appendingPathComponent("\(filename)_\(Int(Date().timeIntervalSince1970)).m3u8")
        try? m3u.data(using: .utf8)?.write(to: tempUrl)
        return tempUrl
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
        HapticManager.successNotification()
        return true
    }
}

