import Foundation

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
    
    // Metadata timestamps
    public var addedAt: Date
    
    public init(
        id: UUID = UUID(),
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
        addedAt: Date = Date()
    ) {
        self.id = id
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
        self.addedAt = addedAt
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

