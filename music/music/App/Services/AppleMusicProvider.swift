import Foundation
import Combine
#if canImport(MusicKit)
import MusicKit
#endif

/// Apple Music Provider integrating Apple MusicKit & Cloud Library
public final class AppleMusicProvider: MusicProviderProtocol, ObservableObject {
    public let providerType: MusicProviderType = .appleMusic
    
    @Published public private(set) var isAuthenticated: Bool = false
    @Published public private(set) var userDisplayName: String?
    @Published public private(set) var trackCount: Int = 0
    @Published public private(set) var lastSyncDate: Date?
    
    public var isLiveSession: Bool {
        #if canImport(MusicKit) && os(iOS)
        return isAuthenticated && MusicAuthorization.currentStatus == .authorized
        #else
        return false
        #endif
    }
    
    private let tokenKey = "apple_music_user_token"
    private let trackCountKey = "apple_music_cached_track_count"
    private let intentionallyRevokedKey = "apple_music_intentionally_revoked"
    
    public init() {
        checkExistingAuth()
    }
    
    private func checkExistingAuth() {
        #if canImport(MusicKit)
        // Honor in-app Disconnect even if system MusicAuthorization stays .authorized.
        if UserDefaults.standard.bool(forKey: intentionallyRevokedKey) {
            self.isAuthenticated = false
            self.userDisplayName = nil
            return
        }
        if MusicAuthorization.currentStatus == .authorized {
            self.isAuthenticated = true
            self.userDisplayName = "Apple Music Subscriber"
            self.trackCount = UserDefaults.standard.integer(forKey: trackCountKey)
            self.lastSyncDate = UserDefaults.standard.object(forKey: "apple_music_last_sync") as? Date
        }
        #endif
    }
    
    public func authenticate() async throws -> Bool {
        #if canImport(MusicKit)
        let status = await MusicAuthorization.request()
        if status == .authorized {
            KeychainManager.save(token: "authorized", for: tokenKey)
            UserDefaults.standard.set(false, forKey: intentionallyRevokedKey)
            let favorites = (try? await fetchFavorites()) ?? []
            await MainActor.run {
                self.isAuthenticated = true
                self.userDisplayName = "Apple Music Subscriber"
                self.trackCount = favorites.count
                self.lastSyncDate = Date()
                UserDefaults.standard.set(favorites.count, forKey: trackCountKey)
                UserDefaults.standard.set(Date(), forKey: "apple_music_last_sync")
            }
            return true
        }
        
        let message: String
        switch status {
        case .denied:
            message = "Apple Music access denied. Enable it in Settings → Privacy → Media & Apple Music."
        case .restricted:
            message = "Apple Music is restricted on this device."
        case .notDetermined:
            message = "Apple Music authorization was dismissed. Try Connect again."
        default:
            message = "Apple Music authorization was not granted."
        }
        let code: Int
        switch status {
        case .denied: code = 403
        case .restricted: code = 451
        case .notDetermined: code = 401
        default: code = 400
        }
        throw NSError(
            domain: "AppleMusic",
            code: code,
            userInfo: [NSLocalizedDescriptionKey: message]
        )
        #else
        KeychainManager.save(token: "mock_apple_token", for: tokenKey)
        await MainActor.run {
            self.isAuthenticated = true
            self.userDisplayName = "Apple Music User"
            self.trackCount = 0
            self.lastSyncDate = Date()
        }
        return true
        #endif
    }
    
    public func revoke() async throws {
        KeychainManager.deleteToken(for: tokenKey)
        UserDefaults.standard.set(true, forKey: intentionallyRevokedKey)
        UserDefaults.standard.removeObject(forKey: trackCountKey)
        UserDefaults.standard.removeObject(forKey: "apple_music_last_sync")
        await MainActor.run {
            self.isAuthenticated = false
            self.userDisplayName = nil
            self.trackCount = 0
            self.lastSyncDate = nil
        }
    }
    
    #if canImport(MusicKit)
    private func mapSong(_ song: Song) -> UniversalTrack {
        UniversalTrack(
            isrc: song.isrc,
            title: song.title,
            artists: [song.artistName],
            album: song.albumTitle,
            durationMs: Int((song.duration ?? 0) * 1000),
            releaseYear: song.releaseDate.map { Calendar.current.component(.year, from: $0) },
            appleMusicId: song.id.rawValue
        )
    }
    #endif
    
    public func fetchFavorites() async throws -> [UniversalTrack] {
        guard isAuthenticated else {
            throw NSError(domain: "AppleMusicProvider", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authorized for Apple Music"])
        }
        
        #if canImport(MusicKit)
        if MusicAuthorization.currentStatus == .authorized {
            do {
                var request = MusicLibraryRequest<Song>()
                request.limit = 10_000
                let response = try await request.response()
                let liveTracks = response.items.map { mapSong($0) }
                await MainActor.run {
                    self.trackCount = liveTracks.count
                    self.lastSyncDate = Date()
                    UserDefaults.standard.set(liveTracks.count, forKey: trackCountKey)
                    UserDefaults.standard.set(Date(), forKey: "apple_music_last_sync")
                }
                return liveTracks
            } catch {
                throw Self.friendlyLibraryError(from: error, operation: "songs")
            }
        }
        #endif
        
        return []
    }
    
    #if canImport(MusicKit)
    private static func friendlyLibraryError(from error: Error, operation: String) -> NSError {
        #if targetEnvironment(simulator)
        let message = "Simulator often can’t read Apple Music \(operation). Use a physical iPhone with songs in the Music app, or sync Spotify first."
        #else
        let detail = error.localizedDescription
        let message = detail.isEmpty || detail == "Unknown error"
            ? "Couldn’t read Apple Music \(operation). Open the Music app, confirm the library has songs, then Sync again."
            : "Apple Music \(operation): \(detail)"
        #endif
        return NSError(
            domain: "AppleMusicProvider",
            code: (error as NSError).code,
            userInfo: [NSLocalizedDescriptionKey: message]
        )
    }
    #endif
    
    public func fetchPlaylists() async throws -> [UniversalPlaylist] {
        guard isAuthenticated else {
            throw NSError(domain: "AppleMusicProvider", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authorized for Apple Music"])
        }
        
        #if canImport(MusicKit)
        if MusicAuthorization.currentStatus == .authorized {
            do {
                var request = MusicLibraryRequest<Playlist>()
                request.limit = 500
                let response = try await request.response()
                var result: [UniversalPlaylist] = []
                for playlist in response.items {
                    // Prefer lightweight metadata here; hydrate tracks via fetchPlaylistTracks / sync hydrate.
                    result.append(
                        UniversalPlaylist(
                            providerPlaylistId: playlist.id.rawValue,
                            providerType: .appleMusic,
                            title: playlist.name,
                            description: nil,
                            trackCount: 0
                        )
                    )
                }
                return result
            } catch {
                throw Self.friendlyLibraryError(from: error, operation: "playlists")
            }
        }
        #endif
        
        return []
    }
    
    public func fetchPlaylistTracks(providerPlaylistId: String) async throws -> [UniversalTrack] {
        guard isAuthenticated else {
            throw NSError(domain: "AppleMusicProvider", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authorized for Apple Music"])
        }
        
        #if canImport(MusicKit)
        if MusicAuthorization.currentStatus == .authorized {
            var request = MusicLibraryRequest<Playlist>()
            request.limit = 500
            let response = try await request.response()
            guard let playlist = response.items.first(where: { $0.id.rawValue == providerPlaylistId }) else {
                return []
            }
            
            // Documented MusicKit pattern: playlist.with([.tracks])
            let detailed = try await playlist.with([.tracks])
            guard let tracks = detailed.tracks else { return [] }
            
            var mapped: [UniversalTrack] = []
            mapped.reserveCapacity(tracks.count)
            for item in tracks {
                switch item {
                case .song(let song):
                    mapped.append(mapSong(song))
                default:
                    continue
                }
            }
            return mapped
        }
        #endif
        
        return []
    }
    
    public func searchCatalog(title: String, artist: String, limit: Int = 5) async throws -> [UniversalTrack] {
        guard isAuthenticated else {
            throw NSError(domain: "AppleMusicProvider", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authorized for Apple Music"])
        }
        
        #if canImport(MusicKit)
        if MusicAuthorization.currentStatus == .authorized {
            let term = "\(title) \(artist)".trimmingCharacters(in: .whitespaces)
            var request = MusicCatalogSearchRequest(term: term, types: [Song.self])
            request.limit = min(max(limit, 1), 10)
            let response = try await request.response()
            return response.songs.prefix(limit).map { mapSong($0) }
        }
        #endif
        
        return []
    }
    
    public func createPlaylist(name: String, description: String?, tracks: [UniversalTrack]) async throws -> UniversalPlaylist {
        guard isAuthenticated else {
            throw NSError(domain: "AppleMusicProvider", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authorized for Apple Music"])
        }
        
        #if canImport(MusicKit) && os(iOS)
        if MusicAuthorization.currentStatus == .authorized {
            var resolvedSongs: [Song] = []
            for track in tracks {
                if let song = try await resolveSong(for: track) {
                    resolvedSongs.append(song)
                }
            }
            
            // Docs: MusicLibrary.shared.createPlaylist(name:description:authorDisplayName:items:)
            // https://developer.apple.com/documentation/musickit/musiclibrary/createplaylist(name:description:authordisplayname:items:)
            if resolvedSongs.isEmpty && !tracks.isEmpty {
                throw NSError(
                    domain: "AppleMusicProvider",
                    code: 422,
                    userInfo: [NSLocalizedDescriptionKey: "Couldn’t resolve any of \(tracks.count) matched tracks in Apple Music catalog — no playlist was created."]
                )
            }
            let created: Playlist
            if resolvedSongs.isEmpty {
                created = try await MusicLibrary.shared.createPlaylist(
                    name: name,
                    description: description,
                    authorDisplayName: nil
                )
            } else {
                let collection = MusicItemCollection(resolvedSongs)
                created = try await MusicLibrary.shared.createPlaylist(
                    name: name,
                    description: description,
                    authorDisplayName: nil,
                    items: collection
                )
            }
            
            return UniversalPlaylist(
                providerPlaylistId: created.id.rawValue,
                providerType: .appleMusic,
                title: created.name,
                description: description,
                trackCount: resolvedSongs.count,
                tracks: resolvedSongs.map { mapSong($0) }
            )
        }
        #endif
        
        throw NSError(
            domain: "AppleMusicProvider",
            code: 501,
            userInfo: [NSLocalizedDescriptionKey: "Apple Music playlist write requires MusicKit on iOS with library authorization. Use a physical device with Apple Music access — the Simulator library is often empty."]
        )
    }
    
    public func removeTracksFromLibrary(_ tracks: [UniversalTrack]) async throws -> Int {
        // MusicKit has no stable public “unlike” for library songs across OS versions.
        // Throw so the player can show an honest notice (local ♥ still updates).
        _ = tracks
        throw NSError(
            domain: "AppleMusicProvider",
            code: 501,
            userInfo: [NSLocalizedDescriptionKey: "Apple Music can’t remove likes from SoundShift yet — unsaved here only. Remove the song in the Music app if you need it gone there too."]
        )
    }
    
    public func saveTracksToLibrary(_ tracks: [UniversalTrack]) async throws -> Int {
        guard isAuthenticated else {
            throw NSError(domain: "AppleMusicProvider", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authorized for Apple Music"])
        }
        
        #if canImport(MusicKit) && os(iOS)
        if MusicAuthorization.currentStatus == .authorized {
            var saved = 0
            for track in tracks {
                guard let song = try await resolveSong(for: track) else { continue }
                do {
                    try await MusicLibrary.shared.add(song)
                    saved += 1
                } catch {
                    // Skip tracks already in library or unavailable for add
                    continue
                }
            }
            return saved
        }
        #endif
        
        throw NSError(
            domain: "AppleMusicProvider",
            code: 501,
            userInfo: [NSLocalizedDescriptionKey: "Saving Liked songs requires MusicKit on a real iPhone with Apple Music library access."]
        )
    }
    
    #if canImport(MusicKit)
    private func resolveSong(for track: UniversalTrack) async throws -> Song? {
        if let id = track.appleMusicId {
            let request = MusicCatalogResourceRequest<Song>(matching: \.id, equalTo: MusicItemID(id))
            let response = try await request.response()
            if let song = response.items.first {
                return song
            }
        }
        
        let hits = try await searchCatalog(title: track.title, artist: track.primaryArtist, limit: 3)
        // Prefer ISRC match from catalog search results if available
        if let isrc = track.isrc?.uppercased(), !isrc.isEmpty {
            for hit in hits {
                if hit.isrc?.uppercased() == isrc, let id = hit.appleMusicId {
                    let request = MusicCatalogResourceRequest<Song>(matching: \.id, equalTo: MusicItemID(id))
                    if let song = try await request.response().items.first {
                        return song
                    }
                }
            }
        }
        
        if let first = hits.first, let id = first.appleMusicId {
            let request = MusicCatalogResourceRequest<Song>(matching: \.id, equalTo: MusicItemID(id))
            return try await request.response().items.first
        }
        
        return nil
    }
    #endif
}
