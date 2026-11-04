import Foundation
import Combine

/// Spotify Web API Provider with PKCE token management
public final class SpotifyProvider: MusicProviderProtocol, ObservableObject {
    public let providerType: MusicProviderType = .spotify
    
    @Published public private(set) var isAuthenticated: Bool = false
    @Published public private(set) var userDisplayName: String?
    @Published public private(set) var trackCount: Int = 0
    @Published public private(set) var lastSyncDate: Date?
    
    private let tokenKey = "spotify_access_token"
    private let refreshKey = "spotify_refresh_token"
    
    public init() {
        checkExistingAuth()
    }
    
    private func checkExistingAuth() {
        if let token = KeychainManager.loadToken(for: tokenKey), !token.isEmpty {
            self.isAuthenticated = true
            self.userDisplayName = "Spotify User"
        }
    }
    
    public func authenticate() async throws -> Bool {
        // In production: triggers ASWebAuthenticationSession with Spotify PKCE flow
        // Redirect: soundshift://spotify-callback
        let mockAccessToken = "mock_spotify_token_\(UUID().uuidString.prefix(8))"
        KeychainManager.save(token: mockAccessToken, for: tokenKey)
        
        await MainActor.run {
            self.isAuthenticated = true
            self.userDisplayName = "Connected Account"
            self.trackCount = 4210
            self.lastSyncDate = Date()
        }
        return true
    }
    
    public func revoke() async throws {
        KeychainManager.deleteToken(for: tokenKey)
        KeychainManager.deleteToken(for: refreshKey)
        
        await MainActor.run {
            self.isAuthenticated = false
            self.userDisplayName = nil
            self.trackCount = 0
            self.lastSyncDate = nil
        }
    }
    
    public func fetchFavorites() async throws -> [UniversalTrack] {
        guard isAuthenticated else { throw NSError(domain: "SpotifyProvider", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"]) }
        
        // Mock sample library ingestion (in production calls https://api.spotify.com/v1/me/tracks)
        let sampleTracks: [UniversalTrack] = [
            UniversalTrack(
                isrc: "USUM71703861",
                title: "Starboy",
                artists: ["The Weeknd", "Daft Punk"],
                album: "Starboy",
                durationMs: 230453,
                releaseYear: 2016,
                spotifyId: "7a26vX02Y4vYj9P6RrqU04"
            ),
            UniversalTrack(
                isrc: "GBUM71505080",
                title: "The Less I Know the Better",
                artists: ["Tame Impala"],
                album: "Currents",
                durationMs: 216320,
                releaseYear: 2015,
                spotifyId: "6K4t31amVTKVgPeRoxXErq"
            )
        ]
        return sampleTracks
    }
    
    public func fetchPlaylists() async throws -> [UniversalPlaylist] {
        guard isAuthenticated else { throw NSError(domain: "SpotifyProvider", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"]) }
        
        return [
            UniversalPlaylist(
                providerPlaylistId: "spotify_pl_1",
                providerType: .spotify,
                title: "Night Drive Synth",
                description: "Deep retro analog soundscapes",
                trackCount: 48
            ),
            UniversalPlaylist(
                providerPlaylistId: "spotify_pl_2",
                providerType: .spotify,
                title: "Gym Power Phonk",
                description: "Max heart rate workout sessions",
                trackCount: 82
            )
        ]
    }
    
    public func createPlaylist(name: String, description: String?, tracks: [UniversalTrack]) async throws -> UniversalPlaylist {
        // In production calls POST https://api.spotify.com/v1/users/{id}/playlists
        return UniversalPlaylist(
            providerPlaylistId: "spotify_new_\(UUID().uuidString.prefix(6))",
            providerType: .spotify,
            title: name,
            description: description,
            trackCount: tracks.count,
            tracks: tracks
        )
    }
}

