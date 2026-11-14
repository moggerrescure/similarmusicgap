import Foundation
import Combine

/// Live Yandex Music connector — full MusicProviderProtocol for migrate in/out.
public final class YandexMusicProvider: MusicProviderProtocol, ObservableObject {
    public let providerType: MusicProviderType = .yandexMusic
    
    /// First-class peer of Spotify / Apple Music.
    public static let isConnectorEnabled: Bool = true
    
    @Published public private(set) var isAuthenticated: Bool = false
    @Published public private(set) var userDisplayName: String?
    @Published public private(set) var trackCount: Int = 0
    @Published public private(set) var lastSyncDate: Date?
    
    public var isLiveSession: Bool {
        isAuthenticated && YandexAuthManager.shared.loadAccessToken() != nil
    }
    
    private let auth = YandexAuthManager.shared
    private let api = YandexMusicAPIClient.shared
    private var cachedUid: Int?
    
    public init() {
        if let token = auth.loadAccessToken(), !token.isEmpty {
            isAuthenticated = true
            userDisplayName = auth.loadDisplayName()
            cachedUid = auth.loadUid()
        } else {
            isAuthenticated = false
        }
    }
    
    private func requireToken() throws -> String {
        guard let token = auth.loadAccessToken(), !token.isEmpty else {
            throw NSError(
                domain: "YandexMusicProvider",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: "Connect Yandex Music first."]
            )
        }
        return token
    }
    
    /// Prefer a refreshed access token when Device Flow stored a refresh_token.
    private func requireFreshToken() async throws -> String {
        if let refreshed = await auth.refreshAccessTokenIfPossible(), !refreshed.isEmpty {
            return refreshed
        }
        return try requireToken()
    }
    
    private func requireUid(token: String) async throws -> Int {
        if let cachedUid { return cachedUid }
        if let stored = auth.loadUid() {
            cachedUid = stored
            return stored
        }
        let status = try await api.fetchAccountStatus(token: token)
        guard let uid = status.account?.uid else {
            throw NSError(
                domain: "YandexMusicProvider",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: "Couldn’t read Yandex account id."]
            )
        }
        cachedUid = uid
        auth.persist(
            token: .init(accessToken: token, refreshToken: nil, expiresIn: nil, tokenType: "bearer"),
            uid: uid,
            displayName: YandexMusicMapper.displayName(from: status)
        )
        await MainActor.run {
            self.userDisplayName = YandexMusicMapper.displayName(from: status)
        }
        return uid
    }
    
    // MARK: - Auth
    
    public func authenticate() async throws -> Bool {
        // Device Flow is driven by YandexConnectSheet; this path restores session if token exists.
        guard let token = auth.loadAccessToken(), !token.isEmpty else {
            return false
        }
        let status = try await api.fetchAccountStatus(token: token)
        let name = YandexMusicMapper.displayName(from: status)
        let uid = status.account?.uid
        auth.persist(
            token: .init(accessToken: token, refreshToken: auth.loadAccessToken().flatMap { _ in nil }, expiresIn: nil, tokenType: "bearer"),
            uid: uid,
            displayName: name
        )
        // Re-save access token explicitly (persist above may rewrite)
        auth.persistManualAccessToken(token)
        if let uid {
            _ = KeychainManager.save(token: "\(uid)", for: YandexAuthManager.uidKey)
            cachedUid = uid
        }
        await MainActor.run {
            self.isAuthenticated = true
            self.userDisplayName = name
        }
        return true
    }
    
    /// Completes Device Flow after the Connect sheet obtains a token payload.
    public func completeLogin(with token: YandexAuthManager.TokenPayload) async throws {
        auth.persist(token: token, uid: nil, displayName: nil)
        let status = try await api.fetchAccountStatus(token: token.accessToken)
        let name = YandexMusicMapper.displayName(from: status)
        let uid = status.account?.uid
        auth.persist(token: token, uid: uid, displayName: name)
        cachedUid = uid
        await MainActor.run {
            self.isAuthenticated = true
            self.userDisplayName = name
        }
    }
    
    public func revoke() async throws {
        auth.clear()
        cachedUid = nil
        await MainActor.run {
            self.isAuthenticated = false
            self.userDisplayName = nil
            self.trackCount = 0
            self.lastSyncDate = nil
        }
    }
    
    // MARK: - Library
    
    public func fetchFavorites() async throws -> [UniversalTrack] {
        let token = try await requireFreshToken()
        let uid = try await requireUid(token: token)
        let refs = try await api.fetchLikedTrackRefs(token: token, uid: uid)
        let ids = refs.compactMap { ref -> String? in
            guard let id = ref.id, !id.isEmpty else { return nil }
            // refs sometimes use "trackId:albumId"
            return id.split(separator: ":").first.map(String.init) ?? id
        }
        let detailed = try await api.fetchTracksByIds(token: token, ids: ids)
        let mapped = detailed.compactMap { YandexMusicMapper.mapTrack($0) }
        await MainActor.run {
            self.trackCount = mapped.count
            self.lastSyncDate = Date()
        }
        return mapped
    }
    
    public func fetchPlaylists() async throws -> [UniversalPlaylist] {
        let token = try await requireFreshToken()
        let uid = try await requireUid(token: token)
        let list = try await api.fetchPlaylists(token: token, uid: uid)
        return list.compactMap { YandexMusicMapper.mapPlaylistShort($0, ownerUid: uid) }
    }
    
    public func fetchPlaylistTracks(providerPlaylistId: String) async throws -> [UniversalTrack] {
        let token = try await requireFreshToken()
        let uid = try await requireUid(token: token)
        guard let parts = YandexMusicMapper.splitPlaylistId(providerPlaylistId) else {
            throw NSError(
                domain: "YandexMusicProvider",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: "Invalid Yandex playlist id."]
            )
        }
        let full = try await api.fetchPlaylist(token: token, uid: parts.uid, kind: parts.kind)
        return YandexMusicMapper.mapPlaylistFull(full, ownerUid: uid)?.tracks ?? []
    }
    
    public func searchCatalog(title: String, artist: String, limit: Int) async throws -> [UniversalTrack] {
        let token = try await requireFreshToken()
        let query = [title, artist].map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        let hits = try await api.searchTracks(token: token, text: query)
        return Array(hits.prefix(max(limit, 1)).compactMap { YandexMusicMapper.mapTrack($0) })
    }
    
    public func createPlaylist(name: String, description: String?, tracks: [UniversalTrack]) async throws -> UniversalPlaylist {
        let token = try await requireFreshToken()
        let uid = try await requireUid(token: token)
        
        var resolvedIds: [String] = []
        for track in tracks {
            if let existing = YandexMusicMapper.resolveYandexTrackId(from: track) {
                resolvedIds.append(existing)
                continue
            }
            let hits = try await searchCatalog(title: track.title, artist: track.primaryArtist, limit: 1)
            if let id = hits.first.flatMap({ YandexMusicMapper.resolveYandexTrackId(from: $0) }) {
                resolvedIds.append(id)
            }
        }
        
        if YandexMusicMapper.shouldRefuseEmptyWrite(requestedCount: tracks.count, resolvedCount: resolvedIds.count) {
            throw NSError(
                domain: "YandexMusicProvider",
                code: 422,
                userInfo: [NSLocalizedDescriptionKey: "Couldn’t resolve any of \(tracks.count) matched tracks on Yandex Music — no playlist was created."]
            )
        }
        
        let created = try await api.createPlaylist(token: token, uid: uid, title: name)
        guard let kind = created.kind else {
            throw NSError(
                domain: "YandexMusicProvider",
                code: 500,
                userInfo: [NSLocalizedDescriptionKey: "Yandex playlist create returned no kind."]
            )
        }
        let revision = created.revision ?? 0
        let updated: YandexPlaylistFull
        if resolvedIds.isEmpty {
            updated = created
        } else {
            updated = try await api.insertTracks(
                token: token,
                uid: uid,
                kind: kind,
                revision: revision,
                trackIds: resolvedIds
            )
        }
        
        guard let mapped = YandexMusicMapper.mapPlaylistFull(updated, ownerUid: uid) else {
            throw NSError(
                domain: "YandexMusicProvider",
                code: 500,
                userInfo: [NSLocalizedDescriptionKey: "Failed to map created Yandex playlist."]
            )
        }
        let tracksOut: [UniversalTrack] = mapped.tracks.isEmpty
            ? resolvedIds.map {
                UniversalTrack(title: "Track \($0)", artists: ["Yandex Music"], durationMs: 0, yandexId: $0)
            }
            : mapped.tracks
        return UniversalPlaylist(
            providerPlaylistId: mapped.providerPlaylistId,
            providerType: .yandexMusic,
            title: mapped.title,
            description: description ?? mapped.description,
            trackCount: max(mapped.trackCount, resolvedIds.count),
            isPublic: false,
            tracks: tracksOut
        )
    }
    
    public func saveTracksToLibrary(_ tracks: [UniversalTrack]) async throws -> Int {
        let token = try await requireFreshToken()
        let uid = try await requireUid(token: token)
        var ids: [String] = []
        for track in tracks {
            if let id = YandexMusicMapper.resolveYandexTrackId(from: track) {
                ids.append(id)
                continue
            }
            let hits = try await searchCatalog(title: track.title, artist: track.primaryArtist, limit: 1)
            if let id = hits.first.flatMap({ YandexMusicMapper.resolveYandexTrackId(from: $0) }) {
                ids.append(id)
            }
        }
        guard !ids.isEmpty else { return 0 }
        try await api.addLikes(token: token, uid: uid, trackIds: ids)
        return ids.count
    }
    
    public func removeTracksFromLibrary(_ tracks: [UniversalTrack]) async throws -> Int {
        let token = try await requireFreshToken()
        let uid = try await requireUid(token: token)
        let ids = tracks.compactMap { YandexMusicMapper.resolveYandexTrackId(from: $0) }
        guard !ids.isEmpty else { return 0 }
        try await api.removeLikes(token: token, uid: uid, trackIds: ids)
        return ids.count
    }
}
