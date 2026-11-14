import Foundation

/// Common contract for all streaming music providers
public protocol MusicProviderProtocol: AnyObject {
    var providerType: MusicProviderType { get }
    var isAuthenticated: Bool { get }
    var userDisplayName: String? { get }
    var trackCount: Int { get }
    var lastSyncDate: Date? { get }
    
    /// True when the session can perform real API reads/writes (not Demo / mock).
    var isLiveSession: Bool { get }
    
    /// Trigger authentication flow (OAuth / WebBrowser / System Dialog)
    func authenticate() async throws -> Bool
    
    /// Disconnect and purge tokens from Keychain
    func revoke() async throws
    
    /// Fetch user's saved/favorite library tracks (C1, C3, C4)
    func fetchFavorites() async throws -> [UniversalTrack]
    
    /// Fetch user's custom and followed playlists (metadata; tracks may be empty until hydrated)
    func fetchPlaylists() async throws -> [UniversalPlaylist]
    
    /// Load full track list for a playlist (paginated on the provider side)
    func fetchPlaylistTracks(providerPlaylistId: String) async throws -> [UniversalTrack]
    
    /// Catalog search used to resolve tracks missing from the destination library
    func searchCatalog(title: String, artist: String, limit: Int) async throws -> [UniversalTrack]
    
    /// Create a playlist on the target service and add the given tracks (live write)
    func createPlaylist(name: String, description: String?, tracks: [UniversalTrack]) async throws -> UniversalPlaylist
    
    /// Save tracks into the user's Liked / library (live write). Returns count saved.
    func saveTracksToLibrary(_ tracks: [UniversalTrack]) async throws -> Int
    
    /// Remove tracks from Liked / library when the provider supports it. Returns count removed.
    func removeTracksFromLibrary(_ tracks: [UniversalTrack]) async throws -> Int
}
