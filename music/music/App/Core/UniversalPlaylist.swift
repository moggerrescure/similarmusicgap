import Foundation

/// Canonical playlist representation across all connected services
public struct UniversalPlaylist: Identifiable, Codable, Equatable, Hashable {
    public let id: UUID
    public var providerPlaylistId: String
    public var providerType: MusicProviderType
    public var title: String
    public var description: String?
    public var coverUrl: URL?
    public var trackCount: Int
    public var isPublic: Bool
    public var tracks: [UniversalTrack]
    
    public init(
        id: UUID? = nil,
        providerPlaylistId: String,
        providerType: MusicProviderType,
        title: String,
        description: String? = nil,
        coverUrl: URL? = nil,
        trackCount: Int = 0,
        isPublic: Bool = true,
        tracks: [UniversalTrack] = []
    ) {
        self.id = id ?? UniversalTrack.stableUUID(
            title: "\(providerType.rawValue):\(providerPlaylistId)",
            artist: "playlist"
        )
        self.providerPlaylistId = providerPlaylistId
        self.providerType = providerType
        self.title = title
        self.description = description
        self.coverUrl = coverUrl
        self.trackCount = trackCount > 0 ? trackCount : tracks.count
        self.isPublic = isPublic
        self.tracks = tracks
    }
}

