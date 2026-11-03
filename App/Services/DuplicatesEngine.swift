import Foundation

/// Duplicate track group across connected streaming hubs (P2 - L5)
public struct DuplicateGroup: Identifiable, Equatable {
    public var id: String { normalizedKey }
    public let normalizedKey: String
    public let canonicalTitle: String
    public let canonicalArtist: String
    public let services: [MusicProviderType]
    public let tracks: [UniversalTrack]
    
    public init(
        normalizedKey: String,
        canonicalTitle: String,
        canonicalArtist: String,
        services: [MusicProviderType],
        tracks: [UniversalTrack]
    ) {
        self.normalizedKey = normalizedKey
        self.canonicalTitle = canonicalTitle
        self.canonicalArtist = canonicalArtist
        self.services = services
        self.tracks = tracks
    }
}

/// Cross-platform library duplicate detector
public final class DuplicatesEngine {
    public static let shared = DuplicatesEngine()
    private let matchingEngine = MatchingEngine()
    
    private init() {}
    
    /// Scans a library and detects songs present in multiple services
    public func findDuplicates(in tracks: [UniversalTrack]) -> [DuplicateGroup] {
        var groups: [String: [UniversalTrack]] = [:]
        
        for track in tracks {
            let key: String
            if let isrc = track.isrc, !isrc.isEmpty {
                key = "ISRC_\(isrc.uppercased())"
            } else {
                let cleanTitle = matchingEngine.normalizeString(track.title)
                let cleanArtist = matchingEngine.normalizeString(track.primaryArtist)
                key = "\(cleanTitle)_\(cleanArtist)"
            }
            groups[key, default: []].append(track)
        }
        
        var duplicateGroups: [DuplicateGroup] = []
        
        for (key, groupedTracks) in groups {
            var distinctServices: Set<MusicProviderType> = []
            for t in groupedTracks {
                if t.yandexId != nil { distinctServices.insert(.yandexMusic) }
                if t.spotifyId != nil { distinctServices.insert(.spotify) }
                if t.appleMusicId != nil { distinctServices.insert(.appleMusic) }
            }
            
            // If track is in 2 or more distinct services, or multiple entries exist
            if distinctServices.count >= 2 || groupedTracks.count >= 2 {
                if let first = groupedTracks.first {
                    duplicateGroups.append(
                        DuplicateGroup(
                            normalizedKey: key,
                            canonicalTitle: first.title,
                            canonicalArtist: first.primaryArtist,
                            services: Array(distinctServices),
                            tracks: groupedTracks
                        )
                    )
                }
            }
        }
        
        return duplicateGroups.sorted(by: { $0.canonicalTitle < $1.canonicalTitle })
    }
}

