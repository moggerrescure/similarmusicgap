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
    let id: String
    let name: String
    let duration_ms: Int
    let explicit: Bool
    let artists: [SpotifyArtistObject]
    let album: SpotifyAlbumObject?
    let external_ids: SpotifyExternalIds?
    let preview_url: String?
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

struct SpotifyPlaylistTracksRef: Codable {
    let total: Int
}

// MARK: - Production Spotify Web API Client

public final class SpotifyWebAPIClient {
    public static let shared = SpotifyWebAPIClient()
    
    private let baseURL = "https://api.spotify.com/v1"
    
    private init() {}
    
    // MARK: - User Profile
    
    public func fetchCurrentUser(token: String) async throws -> SpotifyUserProfile {
        guard let url = URL(string: "\(baseURL)/me") else {
            throw NSError(domain: "SpotifyAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            let errorText = String(data: data, encoding: .utf8) ?? "Failed to fetch profile"
            throw NSError(domain: "SpotifyAPI", code: 401, userInfo: [NSLocalizedDescriptionKey: errorText])
        }
        
        return try JSONDecoder().decode(SpotifyUserProfile.self, from: data)
    }
    
    // MARK: - Saved Tracks (Liked Songs)
    
    public func fetchSavedTracks(token: String, limit: Int = 50, offset: Int = 0) async throws -> (tracks: [UniversalTrack], total: Int) {
        guard let url = URL(string: "\(baseURL)/me/tracks?limit=\(limit)&offset=\(offset)") else {
            throw NSError(domain: "SpotifyAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 500
            let errorText = String(data: data, encoding: .utf8) ?? "Failed to fetch saved tracks"
            throw NSError(domain: "SpotifyAPI", code: statusCode, userInfo: [NSLocalizedDescriptionKey: errorText])
        }
        
        let payload = try JSONDecoder().decode(SpotifySavedTracksResponse.self, from: data)
        
        let universalTracks = payload.items.map { item -> UniversalTrack in
            var year: Int? = nil
            if let dateString = item.track.album?.release_date, let prefix = dateString.split(separator: "-").first, let parsed = Int(prefix) {
                year = parsed
            }
            
            return UniversalTrack(
                isrc: item.track.external_ids?.isrc,
                title: item.track.name,
                artists: item.track.artists.map { $0.name },
                album: item.track.album?.name,
                durationMs: item.track.duration_ms,
                releaseYear: year,
                isExplicit: item.track.explicit,
                spotifyId: item.track.id
            )
        }
        
        return (universalTracks, payload.total)
    }
    
    // MARK: - User Playlists
    
    public func fetchUserPlaylists(token: String, limit: Int = 50) async throws -> [UniversalPlaylist] {
        guard let url = URL(string: "\(baseURL)/me/playlists?limit=\(limit)") else {
            throw NSError(domain: "SpotifyAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 500
            let errorText = String(data: data, encoding: .utf8) ?? "Failed to fetch playlists"
            throw NSError(domain: "SpotifyAPI", code: statusCode, userInfo: [NSLocalizedDescriptionKey: errorText])
        }
        
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
}

