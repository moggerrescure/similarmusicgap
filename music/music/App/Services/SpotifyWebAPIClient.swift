import Foundation

// MARK: - Spotify API Response Models

public struct SpotifyUserProfile: Codable {
    public let id: String
    public let display_name: String?
    public let email: String?
}

struct SpotifySavedTracksResponse: Codable {
    let items: [SpotifySavedTrackWrapper]
    let total: Int
}

struct SpotifySavedTrackWrapper: Codable {
    let added_at: String
    let track: SpotifyTrackObject
}

struct SpotifyTrackObject: Codable {
    let id: String?
    let name: String?
    let duration_ms: Int?
    let explicit: Bool?
    let artists: [SpotifyArtistObject]?
    let album: SpotifyAlbumObject?
    let external_ids: SpotifyExternalIds?
    let preview_url: String?
    let uri: String?
    let type: String?
}

struct SpotifyArtistObject: Codable {
    let id: String?
    let name: String
}

struct SpotifyAlbumObject: Codable {
    let id: String?
    let name: String
    let release_date: String?
    let images: [SpotifyImageObject]?
}

struct SpotifyImageObject: Codable {
    let url: String
    let height: Int?
    let width: Int?
}

struct SpotifyExternalIds: Codable {
    let isrc: String?
}

struct SpotifyPlaylistsResponse: Codable {
    let items: [SpotifyPlaylistItemObject]
    let total: Int
}

struct SpotifyPlaylistItemObject: Codable {
    let id: String
    let name: String
    let description: String?
    let tracks: SpotifyPlaylistTracksRef?
}

public struct SpotifyPlaylistTracksRef: Codable {
    public let total: Int?
}

struct SpotifyPlaylistTracksPage: Codable {
    let items: [SpotifyPlaylistTrackItem]
    let total: Int
    let next: String?
}

struct SpotifyPlaylistTrackItem: Codable {
    let track: SpotifyTrackObject?
}

struct SpotifySearchResponse: Codable {
    let tracks: SpotifySearchTracksBucket?
}

struct SpotifySearchTracksBucket: Codable {
    let items: [SpotifyTrackObject]
}

public struct SpotifyCreatedPlaylist: Codable {
    public let id: String
    public let name: String
    public let description: String?
    public let tracks: SpotifyPlaylistTracksRef?
}

// MARK: - Production Spotify Web API Client

public final class SpotifyWebAPIClient {
    public static let shared = SpotifyWebAPIClient()
    
    private let baseURL = "https://api.spotify.com/v1"
    
    private init() {}
    
    // MARK: - Helpers
    
    private func authorizedRequest(url: URL, token: String, method: String = "GET", body: Data? = nil) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        if body != nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = body
        }
        return request
    }
    
    private func perform(_ request: URLRequest, maxAttempts: Int = 4) async throws -> (Data, HTTPURLResponse) {
        var attempt = 0
        var lastError: NSError?
        
        while attempt < maxAttempts {
            attempt += 1
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw NSError(domain: "SpotifyAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "No HTTP response"])
            }
            
            if (200...299).contains(http.statusCode) {
                return (data, http)
            }
            
            if http.statusCode == 429, attempt < maxAttempts {
                let retryAfterHeader = http.value(forHTTPHeaderField: "Retry-After")
                let seconds = Double(retryAfterHeader ?? "") ?? Double(min(8, 1 << (attempt - 1)))
                let delay = min(max(seconds, 0.5), 30.0)
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                continue
            }
            
            let errorText = String(data: data, encoding: .utf8) ?? "HTTP \(http.statusCode)"
            lastError = NSError(domain: "SpotifyAPI", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: errorText])
            throw lastError!
        }
        
        throw lastError ?? NSError(domain: "SpotifyAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Spotify request failed"])
    }
    
    static func mapTrack(_ track: SpotifyTrackObject) -> UniversalTrack? {
        guard let id = track.id, let name = track.name, track.type != "episode" else { return nil }
        var year: Int?
        if let dateString = track.album?.release_date,
           let prefix = dateString.split(separator: "-").first,
           let parsed = Int(prefix) {
            year = parsed
        }
        return UniversalTrack(
            isrc: track.external_ids?.isrc,
            title: name,
            artists: (track.artists ?? []).map(\.name),
            album: track.album?.name,
            durationMs: track.duration_ms ?? 0,
            releaseYear: year,
            isExplicit: track.explicit ?? false,
            spotifyId: id,
            previewURL: track.preview_url
        )
    }
    
    // MARK: - User Profile
    
    public func fetchCurrentUser(token: String) async throws -> SpotifyUserProfile {
        guard let url = URL(string: "\(baseURL)/me") else {
            throw NSError(domain: "SpotifyAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        let (data, _) = try await perform(authorizedRequest(url: url, token: token))
        return try JSONDecoder().decode(SpotifyUserProfile.self, from: data)
    }
    
    // MARK: - Saved Tracks (Liked Songs)
    
    public func fetchSavedTracks(token: String, limit: Int = 50, offset: Int = 0) async throws -> (tracks: [UniversalTrack], total: Int) {
        guard let url = URL(string: "\(baseURL)/me/tracks?limit=\(min(limit, 50))&offset=\(offset)") else {
            throw NSError(domain: "SpotifyAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        let (data, _) = try await perform(authorizedRequest(url: url, token: token))
        let payload = try JSONDecoder().decode(SpotifySavedTracksResponse.self, from: data)
        let iso = ISO8601DateFormatter()
        let universalTracks = payload.items.compactMap { item -> UniversalTrack? in
            guard var track = Self.mapTrack(item.track) else { return nil }
            if let added = iso.date(from: item.added_at) {
                track.addedAt = added
            }
            return track
        }
        return (universalTracks, payload.total)
    }
    
    public func fetchAllSavedTracks(token: String, pageSize: Int = 50) async throws -> (tracks: [UniversalTrack], total: Int) {
        var allTracks: [UniversalTrack] = []
        var offset = 0
        var total = 0
        
        repeat {
            let page = try await fetchSavedTracks(token: token, limit: pageSize, offset: offset)
            total = page.total
            allTracks.append(contentsOf: page.tracks)
            offset += page.tracks.count
            if page.tracks.isEmpty { break }
        } while allTracks.count < total
        
        return (allTracks, total)
    }
    
    // MARK: - User Playlists (metadata)
    
    public func fetchUserPlaylists(token: String, limit: Int = 50, offset: Int = 0) async throws -> [UniversalPlaylist] {
        guard let url = URL(string: "\(baseURL)/me/playlists?limit=\(min(limit, 50))&offset=\(offset)") else {
            throw NSError(domain: "SpotifyAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        let (data, _) = try await perform(authorizedRequest(url: url, token: token))
        let payload = try JSONDecoder().decode(SpotifyPlaylistsResponse.self, from: data)
        return payload.items.map { item in
            UniversalPlaylist(
                providerPlaylistId: item.id,
                providerType: .spotify,
                title: item.name,
                description: item.description,
                trackCount: item.tracks?.total ?? 0
            )
        }
    }
    
    public func fetchAllUserPlaylists(token: String, pageSize: Int = 50) async throws -> [UniversalPlaylist] {
        var all: [UniversalPlaylist] = []
        var offset = 0
        while true {
            let page = try await fetchUserPlaylists(token: token, limit: pageSize, offset: offset)
            all.append(contentsOf: page)
            if page.count < pageSize { break }
            offset += page.count
        }
        return all
    }
    
    // MARK: - Playlist tracks (full contents)
    
    public func fetchPlaylistTracksPage(token: String, playlistId: String, limit: Int = 100, offset: Int = 0) async throws -> (tracks: [UniversalTrack], total: Int) {
        let encoded = playlistId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? playlistId
        guard let url = URL(string: "\(baseURL)/playlists/\(encoded)/tracks?limit=\(min(limit, 100))&offset=\(offset)&fields=total,next,items(track(id,name,duration_ms,explicit,artists(name),album(name,release_date),external_ids,preview_url,uri,type))") else {
            throw NSError(domain: "SpotifyAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid playlist tracks URL"])
        }
        let (data, _) = try await perform(authorizedRequest(url: url, token: token))
        let payload = try JSONDecoder().decode(SpotifyPlaylistTracksPage.self, from: data)
        let tracks = payload.items.compactMap { item -> UniversalTrack? in
            guard let track = item.track else { return nil }
            return Self.mapTrack(track)
        }
        return (tracks, payload.total)
    }
    
    public func fetchAllPlaylistTracks(token: String, playlistId: String) async throws -> [UniversalTrack] {
        var all: [UniversalTrack] = []
        var offset = 0
        let pageSize = 100
        var total = Int.max
        
        while offset < total {
            let page = try await fetchPlaylistTracksPage(token: token, playlistId: playlistId, limit: pageSize, offset: offset)
            total = page.total
            all.append(contentsOf: page.tracks)
            offset += pageSize
            if page.total == 0 { break }
        }
        return all
    }
    
    // MARK: - Catalog search
    
    public func searchTracks(token: String, title: String, artist: String, limit: Int = 5) async throws -> [UniversalTrack] {
        var components = URLComponents(string: "\(baseURL)/search")!
        let query = "track:\(title) artist:\(artist)"
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "type", value: "track"),
            URLQueryItem(name: "limit", value: String(min(max(limit, 1), 10)))
        ]
        guard let url = components.url else {
            throw NSError(domain: "SpotifyAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid search URL"])
        }
        let (data, _) = try await perform(authorizedRequest(url: url, token: token))
        let payload = try JSONDecoder().decode(SpotifySearchResponse.self, from: data)
        return (payload.tracks?.items ?? []).compactMap(Self.mapTrack)
    }
    
    // MARK: - Write: create playlist + add tracks
    
    public func createPlaylist(token: String, userId: String, name: String, description: String?, isPublic: Bool = false) async throws -> SpotifyCreatedPlaylist {
        let encodedUser = userId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? userId
        guard let url = URL(string: "\(baseURL)/users/\(encodedUser)/playlists") else {
            throw NSError(domain: "SpotifyAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid create playlist URL"])
        }
        var body: [String: Any] = ["name": name, "public": isPublic]
        if let description, !description.isEmpty {
            body["description"] = description
        }
        let bodyData = try JSONSerialization.data(withJSONObject: body)
        let (data, _) = try await perform(authorizedRequest(url: url, token: token, method: "POST", body: bodyData))
        return try JSONDecoder().decode(SpotifyCreatedPlaylist.self, from: data)
    }
    
    /// Save tracks to Liked Songs (`PUT /me/tracks`, batches of 50).
    public func saveTracksToLibrary(token: String, trackIds: [String]) async throws {
        let chunkSize = 50
        var index = 0
        while index < trackIds.count {
            let end = min(index + chunkSize, trackIds.count)
            let chunk = Array(trackIds[index..<end])
            var components = URLComponents(string: "\(baseURL)/me/tracks")!
            components.queryItems = [URLQueryItem(name: "ids", value: chunk.joined(separator: ","))]
            guard let url = components.url else {
                throw NSError(domain: "SpotifyAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid save tracks URL"])
            }
            _ = try await perform(authorizedRequest(url: url, token: token, method: "PUT", body: Data("{}".utf8)))
            index = end
        }
    }
    
    /// Remove tracks from Liked Songs (`DELETE /me/tracks`, batches of 50).
    public func removeTracksFromLibrary(token: String, trackIds: [String]) async throws {
        let chunkSize = 50
        var index = 0
        while index < trackIds.count {
            let end = min(index + chunkSize, trackIds.count)
            let chunk = Array(trackIds[index..<end])
            var components = URLComponents(string: "\(baseURL)/me/tracks")!
            components.queryItems = [URLQueryItem(name: "ids", value: chunk.joined(separator: ","))]
            guard let url = components.url else {
                throw NSError(domain: "SpotifyAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid remove tracks URL"])
            }
            _ = try await perform(authorizedRequest(url: url, token: token, method: "DELETE", body: Data("{}".utf8)))
            index = end
        }
    }
    
    /// Adds track URIs in batches of 100 (Spotify hard limit).
    public func addTracksToPlaylist(token: String, playlistId: String, trackIds: [String]) async throws {
        let uris = trackIds.map { "spotify:track:\($0)" }
        let encoded = playlistId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? playlistId
        guard let url = URL(string: "\(baseURL)/playlists/\(encoded)/tracks") else {
            throw NSError(domain: "SpotifyAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid add tracks URL"])
        }
        
        let chunkSize = 100
        var index = 0
        while index < uris.count {
            let end = min(index + chunkSize, uris.count)
            let chunk = Array(uris[index..<end])
            let bodyData = try JSONSerialization.data(withJSONObject: ["uris": chunk])
            _ = try await perform(authorizedRequest(url: url, token: token, method: "POST", body: bodyData))
            index = end
        }
    }
}
