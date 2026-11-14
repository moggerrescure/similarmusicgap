import Foundation
import Combine

/// Yandex Music connector — isolated stub until official/partner path is decided (brief: feature-flagged).
public final class YandexMusicProvider: MusicProviderProtocol, ObservableObject {
    public let providerType: MusicProviderType = .yandexMusic
    
    /// Public Store / Phase 1: YM stays off. Flip for TestFlight experiments later.
    public static let isConnectorEnabled: Bool = false
    
    @Published public private(set) var isAuthenticated: Bool = false
    @Published public private(set) var userDisplayName: String?
    @Published public private(set) var trackCount: Int = 0
    @Published public private(set) var lastSyncDate: Date?
    
    public var isLiveSession: Bool { false }
    
    private let tokenKey = "yandex_music_oauth_token"
    private let uidKey = "yandex_music_uid"
    
    public init() {
        if KeychainManager.loadToken(for: tokenKey) != nil {
            KeychainManager.deleteToken(for: tokenKey)
            KeychainManager.deleteToken(for: uidKey)
        }
        isAuthenticated = false
    }
    
    private func unavailable(_ action: String) -> NSError {
        NSError(
            domain: "YandexMusicProvider",
            code: 501,
            userInfo: [NSLocalizedDescriptionKey: "Yandex Music \(action) is not available yet. Use Spotify or Apple Music."]
        )
    }
    
    public func authenticate() async throws -> Bool {
        throw unavailable("connect")
    }
    
    public func revoke() async throws {
        KeychainManager.deleteToken(for: tokenKey)
        KeychainManager.deleteToken(for: uidKey)
        await MainActor.run {
            self.isAuthenticated = false
            self.userDisplayName = nil
            self.trackCount = 0
            self.lastSyncDate = nil
        }
    }
    
    public func fetchFavorites() async throws -> [UniversalTrack] {
        throw unavailable("import")
    }
    
    public func fetchPlaylists() async throws -> [UniversalPlaylist] {
        throw unavailable("playlists")
    }
    
    public func fetchPlaylistTracks(providerPlaylistId: String) async throws -> [UniversalTrack] {
        throw unavailable("playlist tracks")
    }
    
    public func searchCatalog(title: String, artist: String, limit: Int) async throws -> [UniversalTrack] {
        throw unavailable("catalog search")
    }
    
    public func createPlaylist(name: String, description: String?, tracks: [UniversalTrack]) async throws -> UniversalPlaylist {
        throw unavailable("playlist create")
    }
    
    public func saveTracksToLibrary(_ tracks: [UniversalTrack]) async throws -> Int {
        throw unavailable("liked songs save")
    }
    
    public func removeTracksFromLibrary(_ tracks: [UniversalTrack]) async throws -> Int {
        throw unavailable("liked songs remove")
    }
}
