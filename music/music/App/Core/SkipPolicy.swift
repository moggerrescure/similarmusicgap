import Foundation

/// Skip-existing conflict check for migration writes.
/// Always evaluate against destination LIBRARY (favorites/playlists), never the
/// match pool — the matched candidate is always a member of the match pool.
public enum SkipPolicy {
    public static func isAlreadyInLibrary(
        matched: UniversalTrack,
        destinationLibrary: [UniversalTrack],
        source: UniversalTrack
    ) -> Bool {
        // Prefer ISRC when both sides have it — but fall through if library rows lack ISRC.
        if let isrc = source.isrc?.uppercased(), !isrc.isEmpty {
            if destinationLibrary.contains(where: { $0.isrc?.uppercased() == isrc }) {
                return true
            }
        }
        if let matchedISRC = matched.isrc?.uppercased(), !matchedISRC.isEmpty {
            if destinationLibrary.contains(where: { $0.isrc?.uppercased() == matchedISRC }) {
                return true
            }
        }
        if let sp = matched.spotifyId, !sp.isEmpty {
            if destinationLibrary.contains(where: { $0.spotifyId == sp }) {
                return true
            }
        }
        if let am = matched.appleMusicId, !am.isEmpty {
            if destinationLibrary.contains(where: { $0.appleMusicId == am }) {
                return true
            }
        }
        if let sourceSp = source.spotifyId, !sourceSp.isEmpty {
            if destinationLibrary.contains(where: { $0.spotifyId == sourceSp }) {
                return true
            }
        }
        if let sourceAm = source.appleMusicId, !sourceAm.isEmpty {
            if destinationLibrary.contains(where: { $0.appleMusicId == sourceAm }) {
                return true
            }
        }
        let title = matched.title.lowercased()
        let artist = matched.primaryArtist.lowercased()
        return destinationLibrary.contains {
            $0.title.lowercased() == title
                && $0.primaryArtist.lowercased() == artist
                && abs($0.durationMs - matched.durationMs) < 2000
        }
    }
}
