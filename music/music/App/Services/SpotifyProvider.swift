import Foundation
import Combine

/// Error types for Spotify Provider operations
public enum SpotifyProviderError: LocalizedError {
    case clientIdMissing
    case notAuthenticated
    case networkError(String)
    
    public var errorDescription: String? {
        switch self {
        case .clientIdMissing:
            return "Spotify Client ID not configured. Please enter your Client ID in Settings or Dashboard."
        case .notAuthenticated:
            return "Spotify account is not connected."
        case .networkError(let message):
            return message
        }
    }
}

/// Spotify Web API Provider with native OAuth 2.0 PKCE and Keychain management
public final class SpotifyProvider: MusicProviderProtocol, ObservableObject {
    public let providerType: MusicProviderType = .spotify
    
    @Published public private(set) var isAuthenticated: Bool = false
    @Published public private(set) var userDisplayName: String?
    @Published public private(set) var trackCount: Int = 0
    @Published public private(set) var lastSyncDate: Date?
    
    private let tokenKey = "spotify_access_token"
    private var isMockSession: Bool = false
    
    public init() {
        checkExistingAuth()
    }
    
    private func checkExistingAuth() {
        if let token = KeychainManager.loadToken(for: tokenKey), !token.isEmpty {
            self.isAuthenticated = true
            self.userDisplayName = UserDefaults.standard.string(forKey: "spotify_user_display_name") ?? "Spotify User"
            self.trackCount = UserDefaults.standard.integer(forKey: "spotify_cached_track_count")
            self.lastSyncDate = UserDefaults.standard.object(forKey: "spotify_last_sync") as? Date
            
            // Background refresh of user profile
            Task {
                await refreshProfileSilently()
            }
        }
    }
    
    private func refreshProfileSilently() async {
        guard SpotifyConfig.isConfigured else { return }
        do {
            let token = try await SpotifyAuthManager.shared.getValidAccessToken(clientId: SpotifyConfig.activeClientId)
            let profile = try await SpotifyWebAPIClient.shared.fetchCurrentUser(token: token)
            await MainActor.run {
                self.userDisplayName = profile.display_name ?? profile.id
                UserDefaults.standard.set(self.userDisplayName, forKey: "spotify_user_display_name")
            }
        } catch {
            print("⚠️ [SpotifyProvider] Silent profile refresh skipped: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Authentication Flow
    
    /// Authenticates via real OAuth 2.0 PKCE session, or demo mode if requested
    public func authenticate() async throws -> Bool {
        return try await authenticate(isDemoMode: false)
    }
    
    public func authenticate(isDemoMode: Bool) async throws -> Bool {
        if isDemoMode {
            self.isMockSession = true
            let mockToken = "mock_spotify_token_\(UUID().uuidString.prefix(8))"
            KeychainManager.save(token: mockToken, for: tokenKey)
            
            await MainActor.run {
                self.isAuthenticated = true
                self.userDisplayName = "Demo Spotify User"
                self.trackCount = 4210
                self.lastSyncDate = Date()
            }
            return true
        }
        
        guard SpotifyConfig.isConfigured else {
            throw SpotifyProviderError.clientIdMissing
        }
        
        self.isMockSession = false
        let clientId = SpotifyConfig.activeClientId
        
        // 1. Launch ASWebAuthenticationSession with PKCE challenge
        let authCode = try await SpotifyAuthManager.shared.startPKCEFlow(clientId: clientId)
        
        // 2. Exchange authorization code for access & refresh tokens
        let tokenResponse = try await SpotifyAuthManager.shared.exchangeCodeForTokens(code: authCode, clientId: clientId)
        
        // 3. Fetch user profile from Spotify Web API
        let profile = try await SpotifyWebAPIClient.shared.fetchCurrentUser(token: tokenResponse.access_token)
        
        // 4. Ingest library count
        var totalTracks = 0
        if let (_, count) = try? await SpotifyWebAPIClient.shared.fetchSavedTracks(token: tokenResponse.access_token, limit: 1) {
            totalTracks = count
        }
        
        await MainActor.run {
            self.isAuthenticated = true
            self.userDisplayName = profile.display_name ?? profile.id
            self.trackCount = totalTracks
            self.lastSyncDate = Date()
            
            UserDefaults.standard.set(self.userDisplayName, forKey: "spotify_user_display_name")
            UserDefaults.standard.set(totalTracks, forKey: "spotify_cached_track_count")
            UserDefaults.standard.set(self.lastSyncDate, forKey: "spotify_last_sync")
        }
        
        return true
    }
    
    // MARK: - Revoke / Disconnect
    
    public func revoke() async throws {
        SpotifyAuthManager.shared.clearTokens()
        UserDefaults.standard.removeObject(forKey: "spotify_user_display_name")
        UserDefaults.standard.removeObject(forKey: "spotify_cached_track_count")
        UserDefaults.standard.removeObject(forKey: "spotify_last_sync")
        
        await MainActor.run {
            self.isAuthenticated = false
            self.userDisplayName = nil
            self.trackCount = 0
            self.lastSyncDate = nil
            self.isMockSession = false
        }
    }
    
    // MARK: - Library & Favorites Ingestion
    
    public func fetchFavorites() async throws -> [UniversalTrack] {
        guard isAuthenticated else { throw SpotifyProviderError.notAuthenticated }
        
        // If demo session, return mock catalog
        if isMockSession || !SpotifyConfig.isConfigured {
            return sampleMockTracks
        }
        
        // In live mode: fetch from Spotify Web API
        let token = try await SpotifyAuthManager.shared.getValidAccessToken(clientId: SpotifyConfig.activeClientId)
        let (tracks, total) = try await SpotifyWebAPIClient.shared.fetchSavedTracks(token: token, limit: 50)
        
        await MainActor.run {
            self.trackCount = total
            self.lastSyncDate = Date()
            UserDefaults.standard.set(total, forKey: "spotify_cached_track_count")
            UserDefaults.standard.set(Date(), forKey: "spotify_last_sync")
        }
        
        return tracks
    }
    
    // MARK: - Playlists
    
    public func fetchPlaylists() async throws -> [UniversalPlaylist] {
        guard isAuthenticated else { throw SpotifyProviderError.notAuthenticated }
        
        if isMockSession || !SpotifyConfig.isConfigured {
            return sampleMockPlaylists
        }
        
        let token = try await SpotifyAuthManager.shared.getValidAccessToken(clientId: SpotifyConfig.activeClientId)
        return try await SpotifyWebAPIClient.shared.fetchUserPlaylists(token: token, limit: 50)
    }
    
    public func createPlaylist(name: String, description: String?, tracks: [UniversalTrack]) async throws -> UniversalPlaylist {
        return UniversalPlaylist(
            providerPlaylistId: "spotify_\(UUID().uuidString.prefix(6))",
            providerType: .spotify,
            title: name,
            description: description,
            trackCount: tracks.count,
            tracks: tracks
        )
    }
    
    // MARK: - Mock Fallback Data
    
    private var sampleMockTracks: [UniversalTrack] {
        [
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
            ),
            UniversalTrack(
                isrc: "USAT21900122",
                title: "Blinding Lights",
                artists: ["The Weeknd"],
                album: "After Hours",
                durationMs: 200040,
                releaseYear: 2019,
                spotifyId: "0VjIjW4GlUZAMYd2vXMi3b"
            )
        ]
    }
    
    private var sampleMockPlaylists: [UniversalPlaylist] {
        [
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
}
