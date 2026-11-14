import Foundation

// MARK: - Wire DTOs (subset of api.music.yandex.net)

public struct YandexAPIEnvelope<T: Decodable>: Decodable {
    public let result: T?
}

public struct YandexAccountStatusResult: Decodable {
    public let account: YandexAccountInfo?
}

public struct YandexAccountInfo: Decodable {
    public let uid: Int?
    public let login: String?
    public let displayName: String?
    public let fullName: String?
}

public struct YandexLibraryTracksResult: Decodable {
    public let library: YandexLibraryTracksLibrary?
}

public struct YandexLibraryTracksLibrary: Decodable {
    public let uid: Int?
    public let tracks: [YandexLibraryTrackRef]?
}

public struct YandexLibraryTrackRef: Decodable {
    public let id: String?
    public let albumId: String?
    public let timestamp: String?
}

public struct YandexTrack: Decodable {
    public let id: String?
    public let title: String?
    public let durationMs: Int?
    public let artists: [YandexArtist]?
    public let albums: [YandexAlbum]?
    public let contentWarning: String?
}

public struct YandexArtist: Decodable {
    public let id: Int?
    public let name: String?
}

public struct YandexAlbum: Decodable {
    public let id: Int?
    public let title: String?
    public let year: Int?
}

public struct YandexPlaylistShort: Decodable {
    public let uid: Int?
    public let kind: Int?
    public let title: String?
    public let description: String?
    public let trackCount: Int?
}

public struct YandexPlaylistFull: Decodable {
    public let uid: Int?
    public let kind: Int?
    public let title: String?
    public let description: String?
    public let trackCount: Int?
    public let revision: Int?
    public let tracks: [YandexPlaylistTrackEntry]?
}

public struct YandexPlaylistTrackEntry: Decodable {
    public let id: String?
    public let track: YandexTrack?
}

public struct YandexSearchResult: Decodable {
    public let tracks: YandexSearchTracksBucket?
}

public struct YandexSearchTracksBucket: Decodable {
    public let results: [YandexTrack]?
}

/// Pure mapping + resolve helpers for Yandex Music (testable without network).
public enum YandexMusicMapper {
    
    public static func displayName(from status: YandexAccountStatusResult) -> String {
        let account = status.account
        if let full = account?.fullName?.trimmingCharacters(in: .whitespacesAndNewlines), !full.isEmpty {
            return full
        }
        if let display = account?.displayName?.trimmingCharacters(in: .whitespacesAndNewlines), !display.isEmpty {
            return display
        }
        if let login = account?.login?.trimmingCharacters(in: .whitespacesAndNewlines), !login.isEmpty {
            return login
        }
        if let uid = account?.uid {
            return "Yandex \(uid)"
        }
        return "Yandex Music"
    }
    
    public static func mapTrack(_ track: YandexTrack, addedAt: Date = Date()) -> UniversalTrack? {
        guard let id = track.id?.trimmingCharacters(in: .whitespacesAndNewlines), !id.isEmpty else {
            return nil
        }
        let title = (track.title ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return nil }
        let artists = (track.artists ?? []).compactMap { $0.name?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let album = track.albums?.first?.title
        let year = track.albums?.first?.year
        let explicit = (track.contentWarning?.lowercased().contains("explicit") == true)
        return UniversalTrack(
            title: title,
            artists: artists.isEmpty ? ["Unknown Artist"] : artists,
            album: album,
            durationMs: track.durationMs ?? 0,
            releaseYear: year,
            isExplicit: explicit,
            yandexId: id,
            addedAt: addedAt
        )
    }
    
    public static func mapPlaylistShort(_ playlist: YandexPlaylistShort, ownerUid: Int) -> UniversalPlaylist? {
        guard let kind = playlist.kind else { return nil }
        let title = (playlist.title ?? "Playlist").trimmingCharacters(in: .whitespacesAndNewlines)
        let providerId = "\(playlist.uid ?? ownerUid):\(kind)"
        return UniversalPlaylist(
            providerPlaylistId: providerId,
            providerType: .yandexMusic,
            title: title.isEmpty ? "Playlist" : title,
            description: playlist.description,
            trackCount: playlist.trackCount ?? 0,
            tracks: []
        )
    }
    
    public static func mapPlaylistFull(_ playlist: YandexPlaylistFull, ownerUid: Int) -> UniversalPlaylist? {
        guard let kind = playlist.kind else { return nil }
        let title = (playlist.title ?? "Playlist").trimmingCharacters(in: .whitespacesAndNewlines)
        let tracks = (playlist.tracks ?? []).compactMap { entry -> UniversalTrack? in
            if let track = entry.track {
                return mapTrack(track)
            }
            // Some payloads only expose composite id "trackId:albumId"
            guard let raw = entry.id else { return nil }
            let trackId = raw.split(separator: ":").first.map(String.init) ?? raw
            return UniversalTrack(
                title: "Track \(trackId)",
                artists: ["Unknown Artist"],
                durationMs: 0,
                yandexId: trackId
            )
        }
        let providerId = "\(playlist.uid ?? ownerUid):\(kind)"
        return UniversalPlaylist(
            providerPlaylistId: providerId,
            providerType: .yandexMusic,
            title: title.isEmpty ? "Playlist" : title,
            description: playlist.description,
            trackCount: playlist.trackCount ?? tracks.count,
            tracks: tracks
        )
    }
    
    /// Parse `"uid:kind"` playlist ids used across SoundShift.
    public static func splitPlaylistId(_ providerPlaylistId: String) -> (uid: Int, kind: Int)? {
        let parts = providerPlaylistId.split(separator: ":")
        guard parts.count == 2,
              let uid = Int(parts[0]),
              let kind = Int(parts[1]) else { return nil }
        return (uid, kind)
    }
    
    /// When creating a playlist: if user passed tracks but none resolved, refuse.
    public static func shouldRefuseEmptyWrite(requestedCount: Int, resolvedCount: Int) -> Bool {
        requestedCount > 0 && resolvedCount == 0
    }
    
    public static func resolveYandexTrackId(from track: UniversalTrack) -> String? {
        if let id = track.yandexId?.trimmingCharacters(in: .whitespacesAndNewlines), !id.isEmpty {
            return id
        }
        return nil
    }
}
