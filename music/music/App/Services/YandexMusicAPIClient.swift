import Foundation

/// Thin authenticated client for api.music.yandex.net (no third-party SDK).
public final class YandexMusicAPIClient {
    public static let shared = YandexMusicAPIClient()
    
    public static let apiBase = URL(string: "https://api.music.yandex.net")!
    
    private let session: URLSession
    private let maxRetries = 3
    
    public init(session: URLSession = .shared) {
        self.session = session
    }
    
    // MARK: - Account
    
    public func fetchAccountStatus(token: String) async throws -> YandexAccountStatusResult {
        let data = try await get(path: "/account/status", token: token)
        let decoded = try JSONDecoder().decode(YandexAPIEnvelope<YandexAccountStatusResult>.self, from: data)
        guard let result = decoded.result else {
            throw YandexAPIError.badResponse("Empty account status")
        }
        return result
    }
    
    // MARK: - Likes
    
    public func fetchLikedTrackRefs(token: String, uid: Int) async throws -> [YandexLibraryTrackRef] {
        let data = try await get(path: "/users/\(uid)/likes/tracks", token: token)
        let decoded = try JSONDecoder().decode(YandexAPIEnvelope<YandexLibraryTracksResult>.self, from: data)
        return decoded.result?.library?.tracks ?? []
    }
    
    public func fetchTracksByIds(token: String, ids: [String]) async throws -> [YandexTrack] {
        guard !ids.isEmpty else { return [] }
        var all: [YandexTrack] = []
        // API accepts comma-separated batches; keep chunks modest.
        for chunk in stride(from: 0, to: ids.count, by: 50) {
            let slice = Array(ids[chunk..<min(chunk + 50, ids.count)])
            let joined = slice.joined(separator: ",")
            let data = try await get(path: "/tracks", token: token, query: ["track-ids": joined])
            // Response can be envelope of array OR raw array depending on endpoint version.
            if let env = try? JSONDecoder().decode(YandexAPIEnvelope<[YandexTrack]>.self, from: data),
               let result = env.result {
                all.append(contentsOf: result)
            } else if let direct = try? JSONDecoder().decode([YandexTrack].self, from: data) {
                all.append(contentsOf: direct)
            }
        }
        return all
    }
    
    public func addLikes(token: String, uid: Int, trackIds: [String]) async throws {
        guard !trackIds.isEmpty else { return }
        for chunk in stride(from: 0, to: trackIds.count, by: 50) {
            let slice = Array(trackIds[chunk..<min(chunk + 50, trackIds.count)])
            _ = try await postForm(
                path: "/users/\(uid)/likes/tracks/add-multiple",
                token: token,
                form: ["track-ids": slice.joined(separator: ",")]
            )
        }
    }
    
    public func removeLikes(token: String, uid: Int, trackIds: [String]) async throws {
        guard !trackIds.isEmpty else { return }
        for chunk in stride(from: 0, to: trackIds.count, by: 50) {
            let slice = Array(trackIds[chunk..<min(chunk + 50, trackIds.count)])
            _ = try await postForm(
                path: "/users/\(uid)/likes/tracks/remove",
                token: token,
                form: ["track-ids": slice.joined(separator: ",")]
            )
        }
    }
    
    // MARK: - Playlists
    
    public func fetchPlaylists(token: String, uid: Int) async throws -> [YandexPlaylistShort] {
        let data = try await get(path: "/users/\(uid)/playlists/list", token: token)
        let decoded = try JSONDecoder().decode(YandexAPIEnvelope<[YandexPlaylistShort]>.self, from: data)
        return decoded.result ?? []
    }
    
    public func fetchPlaylist(token: String, uid: Int, kind: Int) async throws -> YandexPlaylistFull {
        let data = try await get(path: "/users/\(uid)/playlists/\(kind)", token: token)
        let decoded = try JSONDecoder().decode(YandexAPIEnvelope<YandexPlaylistFull>.self, from: data)
        guard let result = decoded.result else {
            throw YandexAPIError.badResponse("Empty playlist \(kind)")
        }
        return result
    }
    
    public func createPlaylist(token: String, uid: Int, title: String, visibility: String = "private") async throws -> YandexPlaylistFull {
        let data = try await postForm(
            path: "/users/\(uid)/playlists/create",
            token: token,
            form: [
                "title": title,
                "visibility": visibility
            ]
        )
        let decoded = try JSONDecoder().decode(YandexAPIEnvelope<YandexPlaylistFull>.self, from: data)
        guard let result = decoded.result else {
            throw YandexAPIError.badResponse("Playlist create returned empty result")
        }
        return result
    }
    
    public func insertTracks(
        token: String,
        uid: Int,
        kind: Int,
        revision: Int,
        trackIds: [String]
    ) async throws -> YandexPlaylistFull {
        guard !trackIds.isEmpty else {
            return try await fetchPlaylist(token: token, uid: uid, kind: kind)
        }
        let trackPayload: [[String: String]] = trackIds.map { ["id": $0] }
        let diff: [[String: Any]] = [[
            "op": "insert",
            "at": 0,
            "tracks": trackPayload
        ]]
        let diffData = try JSONSerialization.data(withJSONObject: diff)
        let diffString = String(data: diffData, encoding: .utf8) ?? "[]"
        let data = try await postForm(
            path: "/users/\(uid)/playlists/\(kind)/change-relative",
            token: token,
            form: [
                "diff": diffString,
                "revision": "\(revision)"
            ]
        )
        let decoded = try JSONDecoder().decode(YandexAPIEnvelope<YandexPlaylistFull>.self, from: data)
        guard let result = decoded.result else {
            throw YandexAPIError.badResponse("Playlist change returned empty result")
        }
        return result
    }
    
    // MARK: - Search
    
    public func searchTracks(token: String, text: String, page: Int = 0) async throws -> [YandexTrack] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        let data = try await get(
            path: "/search",
            token: token,
            query: [
                "text": trimmed,
                "type": "track",
                "page": "\(page)",
                "nocorrect": "false"
            ]
        )
        let decoded = try JSONDecoder().decode(YandexAPIEnvelope<YandexSearchResult>.self, from: data)
        return decoded.result?.tracks?.results ?? []
    }
    
    // MARK: - HTTP
    
    private func apiURL(_ path: String, query: [String: String] = [:]) throws -> URL {
        let normalized = path.hasPrefix("/") ? path : "/\(path)"
        guard var components = URLComponents(string: "https://api.music.yandex.net\(normalized)") else {
            throw YandexAPIError.invalidURL
        }
        if !query.isEmpty {
            components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        guard let url = components.url else { throw YandexAPIError.invalidURL }
        return url
    }
    
    private func get(path: String, token: String, query: [String: String] = [:]) async throws -> Data {
        var request = URLRequest(url: try apiURL(path, query: query))
        request.httpMethod = "GET"
        applyCommonHeaders(&request, token: token)
        return try await perform(request)
    }
    
    private func postForm(path: String, token: String, form: [String: String]) async throws -> Data {
        let url = try apiURL(path)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        applyCommonHeaders(&request, token: token)
        request.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
        let body = form
            .map { key, value in
                let k = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? key
                let v = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
                return "\(k)=\(v)"
            }
            .joined(separator: "&")
        request.httpBody = body.data(using: .utf8)
        return try await perform(request)
    }
    
    private func applyCommonHeaders(_ request: inout URLRequest, token: String) {
        request.setValue("OAuth \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("SoundShift/1.0 (iOS)", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
    }
    
    private func perform(_ request: URLRequest) async throws -> Data {
        var attempt = 0
        var lastError: Error?
        while attempt < maxRetries {
            attempt += 1
            do {
                let (data, response) = try await session.data(for: request)
                guard let http = response as? HTTPURLResponse else {
                    throw YandexAPIError.badResponse("No HTTP response")
                }
                if http.statusCode == 429 {
                    let retryAfter = Double(http.value(forHTTPHeaderField: "Retry-After") ?? "") ?? Double(attempt)
                    try await Task.sleep(nanoseconds: UInt64(max(retryAfter, 0.5) * 1_000_000_000))
                    continue
                }
                guard (200..<300).contains(http.statusCode) else {
                    let text = String(data: data, encoding: .utf8) ?? ""
                    throw YandexAPIError.http(http.statusCode, text)
                }
                return data
            } catch {
                lastError = error
                if attempt >= maxRetries { break }
                try await Task.sleep(nanoseconds: UInt64(attempt) * 300_000_000)
            }
        }
        throw lastError ?? YandexAPIError.badResponse("Request failed")
    }
}

public enum YandexAPIError: LocalizedError {
    case invalidURL
    case badResponse(String)
    case http(Int, String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid Yandex Music URL"
        case .badResponse(let msg): return msg
        case .http(let code, let body):
            return "Yandex Music HTTP \(code): \(body.prefix(180))"
        }
    }
}
