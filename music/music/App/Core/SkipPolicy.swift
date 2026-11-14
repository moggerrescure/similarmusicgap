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
        if let isrc = source.isrc?.uppercased(), !isrc.isEmpty {
            return destinationLibrary.contains { $0.isrc?.uppercased() == isrc }
        }
        if let sp = matched.spotifyId, !sp.isEmpty {
            return destinationLibrary.contains { $0.spotifyId == sp }
        }
        if let am = matched.appleMusicId, !am.isEmpty {
            return destinationLibrary.contains { $0.appleMusicId == am }
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
