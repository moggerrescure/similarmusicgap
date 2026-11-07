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
            print("[SpotifyProvider] Silent profile refresh skipped: \(error.localizedDescription)")
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
    
    public func fetchFavoritesFallback() -> [UniversalTrack] {
        return sampleMockTracks
    }
    
    public static let cachedSampleMockTracks: [UniversalTrack] = [
        UniversalTrack(
            isrc: "USUM71703861",
            title: "Starboy",
            artists: ["The Weeknd", "Daft Punk"],
            album: "Starboy",
            durationMs: 230453,
            releaseYear: 2016,
            yandexId: "29871638",
            spotifyId: "7a26vX02Y4vYj9P6RrqU04",
            appleMusicId: "1156443290"
        ),
        UniversalTrack(
            isrc: "GBUM71505080",
            title: "The Less I Know the Better",
            artists: ["Tame Impala"],
            album: "Currents",
            durationMs: 216320,
            releaseYear: 2015,
            yandexId: "27811920",
            spotifyId: "6K4t31amVTKVgPeRoxXErq",
            appleMusicId: "985067994"
        ),
        UniversalTrack(
            isrc: "USAT21900122",
            title: "Blinding Lights",
            artists: ["The Weeknd"],
            album: "After Hours",
            durationMs: 200040,
            releaseYear: 2019,
            yandexId: "63219011",
            spotifyId: "0VjIjW4GlUZAMYd2vXMi3b",
            appleMusicId: "1499378607"
        ),
        UniversalTrack(
            isrc: "RUAA12000042",
            title: "Где нас нет",
            artists: ["Oxxxymiron"],
            album: "ГОРГОРОД",
            durationMs: 265000,
            releaseYear: 2015,
            yandexId: "24981120",
            spotifyId: "4RTYu892p",
            appleMusicId: "105891104"
        ),
        UniversalTrack(
            isrc: "FRUM71300088",
            title: "Instant Crush",
            artists: ["Daft Punk", "Julian Casablancas"],
            album: "Random Access Memories",
            durationMs: 337560,
            releaseYear: 2013,
            yandexId: "14589231",
            spotifyId: "2bpgKp31sOVoTeStOXzi8C",
            appleMusicId: "617154241"
        ),
        UniversalTrack(
            isrc: "USWB11200021",
            title: "Midnight City",
            artists: ["M83"],
            album: "Hurry Up, We're Dreaming",
            durationMs: 243000,
            releaseYear: 2011,
            yandexId: "1892019",
            spotifyId: "1eyzqe2QqGZUmfcPZtrIyt",
            appleMusicId: "466487841"
        ),
        UniversalTrack(
            isrc: "RUAA12000318",
            title: "Барбисайз",
            artists: ["Дора", "Мэйби Бэйби"],
            album: "МЕНТАЛЬНЫЙ",
            durationMs: 168000,
            releaseYear: 2022,
            yandexId: "9871120",
            spotifyId: "3x9k12a",
            appleMusicId: "15982103"
        ),
        UniversalTrack(
            isrc: "DEZ651900143",
            title: "Судно (Борис Рыжий)",
            artists: ["Молчат Дома"],
            album: "Этажи",
            durationMs: 141000,
            releaseYear: 2018,
            yandexId: "4591102",
            spotifyId: "6W4k12s",
            appleMusicId: "14498112"
        ),
        UniversalTrack(
            isrc: "USSM12304910",
            title: "UTOPIA",
            artists: ["Travis Scott"],
            album: "UTOPIA",
            durationMs: 215000,
            releaseYear: 2023,
            yandexId: "8912304",
            spotifyId: "5b8v123",
            appleMusicId: "16998124"
        ),
        UniversalTrack(
            isrc: "USRC12204128",
            title: "Kill Bill",
            artists: ["SZA"],
            album: "SOS",
            durationMs: 153000,
            releaseYear: 2022,
            yandexId: "7781290",
            spotifyId: "1Qrg8KqiI2V",
            appleMusicId: "16578210"
        ),
        UniversalTrack(
            isrc: "USUG12303810",
            title: "vampire",
            artists: ["Olivia Rodrigo"],
            album: "GUTS",
            durationMs: 219000,
            releaseYear: 2023,
            yandexId: "8891203",
            spotifyId: "3k79jB4",
            appleMusicId: "16942109"
        ),
        UniversalTrack(
            isrc: "RUAA10000008",
            title: "Искала",
            artists: ["Zemfira"],
            album: "Прости меня моя любовь",
            durationMs: 213000,
            releaseYear: 2000,
            yandexId: "109823",
            spotifyId: "7821bc",
            appleMusicId: "3498102"
        )
    ]
    
    public var sampleMockTracks: [UniversalTrack] {
        Self.cachedSampleMockTracks
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
