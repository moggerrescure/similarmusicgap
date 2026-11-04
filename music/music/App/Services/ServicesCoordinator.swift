import Foundation
import Combine

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
    
    private init() {
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
            print("❌ Authentication failed for \(type.displayName): \(error)")
        }
    }
    
    public func revoke(type: MusicProviderType) async {
        do {
            try await provider(for: type).revoke()
            refreshAggregates()
        } catch {
            print("❌ Revoke failed for \(type.displayName): \(error)")
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
    
    // MARK: - Universal Backup Export (P0 - C8)
    public func exportUniversalJSON() -> URL? {
        struct BackupPayload: Codable {
            let exportedAt: Date
            let totalTracks: Int
            let tracks: [UniversalTrack]
            let playlists: [UniversalPlaylist]
        }
        
        let payload = BackupPayload(
            exportedAt: Date(),
            totalTracks: allTracks.count,
            tracks: allTracks,
            playlists: allPlaylists
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        
        guard let data = try? encoder.encode(payload) else { return nil }
        
        let tempUrl = FileManager.default.temporaryDirectory.appendingPathComponent("SoundShift_Universal_Backup_\(Int(Date().timeIntervalSince1970)).json")
        try? data.write(to: tempUrl)
        return tempUrl
    }
}

