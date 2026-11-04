import Foundation

/// Common contract for all streaming music providers
public protocol MusicProviderProtocol: AnyObject {
    var providerType: MusicProviderType { get }
    var isAuthenticated: Bool { get }
    var userDisplayName: String? { get }
    var trackCount: Int { get }
    var lastSyncDate: Date? { get }
    
    /// Trigger authentication flow (OAuth / WebBrowser / System Dialog)
    func authenticate() async throws -> Bool
    
    /// Disconnect and purge tokens from Keychain
    func revoke() async throws
    
    /// Fetch user's saved/favorite library tracks (C1, C3, C4)
    func fetchFavorites() async throws -> [UniversalTrack]
    
    /// Fetch user's custom and followed playlists
    func fetchPlaylists() async throws -> [UniversalPlaylist]
    
    /// Create a new playlist on the target service
    func createPlaylist(name: String, description: String?, tracks: [UniversalTrack]) async throws -> UniversalPlaylist
}

