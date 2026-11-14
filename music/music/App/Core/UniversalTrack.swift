import Foundation
import CryptoKit

/// Supported streaming platforms
public enum MusicProviderType: String, Codable, CaseIterable, Identifiable {
    case yandexMusic = "yandex_music"
    case spotify = "spotify"
    case appleMusic = "apple_music"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .yandexMusic: return "Yandex Music"
        case .spotify: return "Spotify"
        case .appleMusic: return "Apple Music"
        }
    }
    
    public var brandColorHex: String {
        switch self {
        case .yandexMusic: return "#FBBF24" // Amber/Yellow
        case .spotify: return "#10B981"     // Emerald/Green
        case .appleMusic: return "#FB7185"   // Rose/Pink
        }
    }
    
    public var iconName: String {
        switch self {
        case .yandexMusic: return "waveform"
        case .spotify: return "dot.radiowaves.left.and.right"
        case .appleMusic: return "applelogo"
        }
    }
    
    public var assetIconName: String {
        switch self {
        case .spotify: return "spotify_icon"
        case .appleMusic: return "apple_music_icon"
        case .yandexMusic: return "yandex_music_icon"
        }
    }
    
    /// Connectors that are live in the current build (YM is flagged off until Transfer/TestFlight).
    public static var availableConnectors: [MusicProviderType] {
        allCases.filter { type in
            if type == .yandexMusic { return YandexMusicProvider.isConnectorEnabled }
            return true
        }
    }
}

/// Universal canonical music track model across all streaming platforms
public struct UniversalTrack: Identifiable, Codable, Equatable, Hashable {
    public let id: UUID
    public var isrc: String?
    public var title: String
    public var rawTitle: String
    public var artists: [String]
    public var album: String?
    public var durationMs: Int
    public var releaseYear: Int?
    public var isExplicit: Bool
    
    // Platform-specific ID references
    public var yandexId: String?
    public var spotifyId: String?
    public var appleMusicId: String?
    
    /// 30s preview stream when the source API provides one (Spotify).
    public var previewURL: String?
    
    // Metadata timestamps
    public var addedAt: Date
    
    public init(
        id: UUID? = nil,
        isrc: String? = nil,
        title: String,
        rawTitle: String? = nil,
        artists: [String],
        album: String? = nil,
        durationMs: Int,
        releaseYear: Int? = nil,
        isExplicit: Bool = false,
        yandexId: String? = nil,
        spotifyId: String? = nil,
        appleMusicId: String? = nil,
        previewURL: String? = nil,
        addedAt: Date = Date()
    ) {
        self.isrc = isrc
        self.title = title
        self.rawTitle = rawTitle ?? title
        self.artists = artists
        self.album = album
        self.durationMs = durationMs
        self.releaseYear = releaseYear
        self.isExplicit = isExplicit
        self.yandexId = yandexId
        self.spotifyId = spotifyId
        self.appleMusicId = appleMusicId
        self.previewURL = previewURL
        self.addedAt = addedAt
        // Stable IDs keep Transfer archive selection valid across re-sync / re-fetch
        if let id {
            self.id = id
        } else {
            self.id = Self.stableUUID(
                spotifyId: spotifyId,
                appleMusicId: appleMusicId,
                yandexId: yandexId,
                isrc: isrc,
                title: title,
                artist: artists.first ?? ""
            )
        }
    }
    
    public static func stableUUID(
        spotifyId: String? = nil,
        appleMusicId: String? = nil,
        yandexId: String? = nil,
        isrc: String? = nil,
        title: String,
        artist: String
    ) -> UUID {
        let seed: String
        if let spotifyId, !spotifyId.isEmpty {
            seed = "spotify:\(spotifyId)"
        } else if let appleMusicId, !appleMusicId.isEmpty {
            seed = "apple:\(appleMusicId)"
        } else if let yandexId, !yandexId.isEmpty {
            seed = "yandex:\(yandexId)"
        } else if let isrc, !isrc.isEmpty {
            seed = "isrc:\(isrc.uppercased())"
        } else {
            seed = "meta:\(title.lowercased())|\(artist.lowercased())"
        }
        let digest = SHA256.hash(data: Data(seed.utf8))
        var bytes = Array(digest.prefix(16))
        // RFC 4122 variant bits for a synthetic UUID
        bytes[6] = (bytes[6] & 0x0F) | 0x50
        bytes[8] = (bytes[8] & 0x3F) | 0x80
        return UUID(uuid: (
            bytes[0], bytes[1], bytes[2], bytes[3],
            bytes[4], bytes[5], bytes[6], bytes[7],
            bytes[8], bytes[9], bytes[10], bytes[11],
            bytes[12], bytes[13], bytes[14], bytes[15]
        ))
    }
    
    /// Clean formatted primary artist
    public var primaryArtist: String {
        artists.first ?? "Unknown Artist"
    }
    
    /// Formatted duration string (e.g. "3:42")
    public var formattedDuration: String {
        let totalSeconds = durationMs / 1000
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

