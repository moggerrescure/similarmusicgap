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
    private let userIdKey = "spotify_user_id"
    private var isMockSession: Bool = false
    private var cachedUserId: String?
    
    public init() {
        checkExistingAuth()
    }
    
    private func checkExistingAuth() {
        if let token = KeychainManager.loadToken(for: tokenKey), !token.isEmpty {
            self.isMockSession = token.hasPrefix("mock_spotify_token_")
            self.isAuthenticated = true
            self.userDisplayName = UserDefaults.standard.string(forKey: "spotify_user_display_name")
                ?? (isMockSession ? "Demo Spotify User" : "Spotify User")
            self.trackCount = UserDefaults.standard.integer(forKey: "spotify_cached_track_count")
            self.lastSyncDate = UserDefaults.standard.object(forKey: "spotify_last_sync") as? Date
            self.cachedUserId = UserDefaults.standard.string(forKey: userIdKey)
            
            if !isMockSession {
                Task { await refreshProfileSilently() }
            }
        }
    }
    
    public var isUsingDemoData: Bool { isMockSession }
    
    public var isLiveSession: Bool {
        isAuthenticated && !isMockSession && SpotifyConfig.isConfigured
    }
    
    private func requireLiveToken() async throws -> String {
        guard isAuthenticated else { throw SpotifyProviderError.notAuthenticated }
        guard !isMockSession, SpotifyConfig.isConfigured else {
            throw SpotifyProviderError.networkError("Spotify live API requires a real Client ID session (not Demo Mode).")
        }
        return try await SpotifyAuthManager.shared.getValidAccessToken(clientId: SpotifyConfig.activeClientId)
    }
    
    private func refreshProfileSilently() async {
        guard SpotifyConfig.isConfigured else { return }
        do {
            let token = try await SpotifyAuthManager.shared.getValidAccessToken(clientId: SpotifyConfig.activeClientId)
            let profile = try await SpotifyWebAPIClient.shared.fetchCurrentUser(token: token)
            await MainActor.run {
                self.userDisplayName = profile.display_name ?? profile.id
                self.cachedUserId = profile.id
                UserDefaults.standard.set(self.userDisplayName, forKey: "spotify_user_display_name")
                UserDefaults.standard.set(profile.id, forKey: self.userIdKey)
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
                // Demo cannot sync a real library — never advertise a fake catalog size.
                self.trackCount = 0
                self.lastSyncDate = nil
            }
            return true
        }
        
        guard SpotifyConfig.isConfigured else {
            throw SpotifyProviderError.clientIdMissing
        }
        
        let wasDemo = isMockSession
        let clientId = SpotifyConfig.activeClientId
        
        // Keep Demo flags until PKCE succeeds — cancel/error must not flip to fake LIVE.
        let authCode: String
        do {
            authCode = try await SpotifyAuthManager.shared.startPKCEFlow(clientId: clientId)
        } catch {
            if wasDemo {
                self.isMockSession = true
            }
            throw error
        }
        
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
            self.isMockSession = false
            self.isAuthenticated = true
            self.userDisplayName = profile.display_name ?? profile.id
            self.cachedUserId = profile.id
            self.trackCount = totalTracks
            self.lastSyncDate = Date()
            
            UserDefaults.standard.set(self.userDisplayName, forKey: "spotify_user_display_name")
            UserDefaults.standard.set(profile.id, forKey: self.userIdKey)
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
        UserDefaults.standard.removeObject(forKey: userIdKey)
        
        await MainActor.run {
            self.isAuthenticated = false
            self.userDisplayName = nil
            self.trackCount = 0
            self.lastSyncDate = nil
            self.isMockSession = false
            self.cachedUserId = nil
        }
    }
    
    // MARK: - Library & Favorites Ingestion
    
    public func fetchFavorites() async throws -> [UniversalTrack] {
        guard isAuthenticated else { throw SpotifyProviderError.notAuthenticated }
        
        // Demo / unconfigured: never seed the synced library with mock tracks.
        if isMockSession || !SpotifyConfig.isConfigured {
            await MainActor.run {
                self.trackCount = 0
            }
            return []
        }
        
        // In live mode: fetch full liked library (paginated)
        let token = try await SpotifyAuthManager.shared.getValidAccessToken(clientId: SpotifyConfig.activeClientId)
        let (tracks, total) = try await SpotifyWebAPIClient.shared.fetchAllSavedTracks(token: token)
        
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
            return []
        }
        
        let token = try await requireLiveToken()
        return try await SpotifyWebAPIClient.shared.fetchAllUserPlaylists(token: token)
    }
    
    public func fetchPlaylistTracks(providerPlaylistId: String) async throws -> [UniversalTrack] {
        guard isAuthenticated else { throw SpotifyProviderError.notAuthenticated }
        
        if isMockSession || !SpotifyConfig.isConfigured {
            return []
        }
        
        let token = try await requireLiveToken()
        return try await SpotifyWebAPIClient.shared.fetchAllPlaylistTracks(token: token, playlistId: providerPlaylistId)
    }
    
    public func searchCatalog(title: String, artist: String, limit: Int = 5) async throws -> [UniversalTrack] {
        guard isAuthenticated else { throw SpotifyProviderError.notAuthenticated }
        
        if isMockSession || !SpotifyConfig.isConfigured {
            return []
        }
        
        let token = try await requireLiveToken()
        return try await SpotifyWebAPIClient.shared.searchTracks(token: token, title: title, artist: artist, limit: limit)
    }
    
    public func createPlaylist(name: String, description: String?, tracks: [UniversalTrack]) async throws -> UniversalPlaylist {
        guard isAuthenticated else { throw SpotifyProviderError.notAuthenticated }
        
        if isMockSession || !SpotifyConfig.isConfigured {
            throw SpotifyProviderError.networkError(
                "Demo Mode cannot write playlists. Connect Spotify with a real Client ID for live transfer."
            )
        }
        
        let token = try await requireLiveToken()
        var userId = cachedUserId ?? UserDefaults.standard.string(forKey: userIdKey)
        if userId == nil {
            let profile = try await SpotifyWebAPIClient.shared.fetchCurrentUser(token: token)
            userId = profile.id
            cachedUserId = profile.id
            UserDefaults.standard.set(profile.id, forKey: userIdKey)
        }
        guard let userId else {
            throw SpotifyProviderError.networkError("Spotify user id unavailable.")
        }
        
        // Resolve Spotify IDs: prefer existing, otherwise catalog search (yield so UI stays responsive)
        var resolvedIds: [String] = []
        var resolvedTracks: [UniversalTrack] = []
        for (index, track) in tracks.enumerated() {
            if index % 15 == 0 {
                await Task.yield()
            }
            if let id = track.spotifyId {
                resolvedIds.append(id)
                resolvedTracks.append(track)
                continue
            }
            let hits = try await SpotifyWebAPIClient.shared.searchTracks(
                token: token,
                title: track.title,
                artist: track.primaryArtist,
                limit: 1
            )
            if let hit = hits.first, let id = hit.spotifyId {
                resolvedIds.append(id)
                resolvedTracks.append(hit)
            }
        }
        
        let created = try await SpotifyWebAPIClient.shared.createPlaylist(
            token: token,
            userId: userId,
            name: name,
            description: description,
            isPublic: false
        )
        
        if !resolvedIds.isEmpty {
            try await SpotifyWebAPIClient.shared.addTracksToPlaylist(
                token: token,
                playlistId: created.id,
                trackIds: resolvedIds
            )
        }
        
        return UniversalPlaylist(
            providerPlaylistId: created.id,
            providerType: .spotify,
            title: created.name,
            description: created.description ?? description,
            trackCount: resolvedIds.count,
            tracks: resolvedTracks
        )
    }
    
    public func saveTracksToLibrary(_ tracks: [UniversalTrack]) async throws -> Int {
        guard isAuthenticated else { throw SpotifyProviderError.notAuthenticated }
        if isMockSession || !SpotifyConfig.isConfigured {
            throw SpotifyProviderError.networkError(
                "Demo Mode cannot save Liked Songs. Connect Spotify with a real Client ID."
            )
        }
        
        let token = try await requireLiveToken()
        var ids: [String] = []
        for track in tracks {
            if let id = track.spotifyId {
                ids.append(id)
                continue
            }
            let hits = try await SpotifyWebAPIClient.shared.searchTracks(
                token: token,
                title: track.title,
                artist: track.primaryArtist,
                limit: 1
            )
            if let id = hits.first?.spotifyId {
                ids.append(id)
            }
        }
        
        let unique = Array(Set(ids))
        guard !unique.isEmpty else { return 0 }
        try await SpotifyWebAPIClient.shared.saveTracksToLibrary(token: token, trackIds: unique)
        return unique.count
    }
    
    public func removeTracksFromLibrary(_ tracks: [UniversalTrack]) async throws -> Int {
        guard isAuthenticated else { throw SpotifyProviderError.notAuthenticated }
        if isMockSession || !SpotifyConfig.isConfigured {
            throw SpotifyProviderError.networkError(
                "Demo Mode cannot edit Liked Songs. Connect Spotify with a real Client ID."
            )
        }
        let token = try await requireLiveToken()
        let ids = tracks.compactMap(\.spotifyId).filter { !$0.isEmpty }
        let unique = Array(Set(ids))
        guard !unique.isEmpty else { return 0 }
        try await SpotifyWebAPIClient.shared.removeTracksFromLibrary(token: token, trackIds: unique)
        return unique.count
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
                trackCount: sampleMockTracks.count,
                tracks: sampleMockTracks
            ),
            UniversalPlaylist(
                providerPlaylistId: "spotify_pl_2",
                providerType: .spotify,
                title: "Gym Power Phonk",
                description: "Max heart rate workout sessions",
                trackCount: Array(sampleMockTracks.prefix(6)).count,
                tracks: Array(sampleMockTracks.prefix(6))
            )
        ]
    }
}
