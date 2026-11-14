import Foundation

/// Merges duplicate library rows while preserving every platform ID.
public enum TrackDeduper {
    /// Union-find merge so A↔B and B↔C collapse to one row (transitive ID links).
    public static func merge(_ tracks: [UniversalTrack]) -> [UniversalTrack] {
        guard tracks.count > 1 else { return tracks }
        
        var parent = Array(tracks.indices)
        
        func find(_ i: Int) -> Int {
            var i = i
            while parent[i] != i {
                parent[i] = parent[parent[i]]
                i = parent[i]
            }
            return i
        }
        
        func union(_ a: Int, _ b: Int) {
            let ra = find(a)
            let rb = find(b)
            if ra != rb {
                parent[rb] = ra
            }
        }
        
        var keyOwner: [String: Int] = [:]
        for (index, track) in tracks.enumerated() {
            for key in identityKeys(for: track) {
                if let existing = keyOwner[key] {
                    union(index, existing)
                } else {
                    keyOwner[key] = index
                }
            }
        }
        
        // Re-point every key to the component root after unions settle.
        for (index, track) in tracks.enumerated() {
            let root = find(index)
            for key in identityKeys(for: track) {
                if let owner = keyOwner[key] {
                    union(root, owner)
                    keyOwner[key] = find(root)
                } else {
                    keyOwner[key] = root
                }
            }
        }
        
        var mergedByRoot: [Int: UniversalTrack] = [:]
        var order: [Int] = []
        for (index, track) in tracks.enumerated() {
            let root = find(index)
            if let existing = mergedByRoot[root] {
                mergedByRoot[root] = mergePair(existing, track)
            } else {
                mergedByRoot[root] = track
                order.append(root)
            }
        }
        
        return order.compactMap { mergedByRoot[$0] }
    }
    
    public static func identityKeys(for track: UniversalTrack) -> [String] {
        var keys: [String] = []
        if let isrc = track.isrc?.uppercased(), !isrc.isEmpty {
            keys.append("isrc:\(isrc)")
        }
        if let sp = track.spotifyId, !sp.isEmpty {
            keys.append("sp:\(sp)")
        }
        if let am = track.appleMusicId, !am.isEmpty {
            keys.append("am:\(am)")
        }
        if YandexMusicProvider.isConnectorEnabled, let yd = track.yandexId, !yd.isEmpty {
            keys.append("yd:\(yd)")
        }
        if keys.isEmpty {
            keys.append(
                "meta:\(track.title.lowercased())|\(track.primaryArtist.lowercased())|\(track.durationMs)"
            )
        }
        return keys
    }
    
    public static func mergePair(_ a: UniversalTrack, _ b: UniversalTrack) -> UniversalTrack {
        var merged = a
        if merged.isrc == nil || merged.isrc?.isEmpty == true { merged.isrc = b.isrc }
        if merged.spotifyId == nil { merged.spotifyId = b.spotifyId }
        if merged.appleMusicId == nil { merged.appleMusicId = b.appleMusicId }
        if merged.yandexId == nil { merged.yandexId = b.yandexId }
        if merged.previewURL == nil { merged.previewURL = b.previewURL }
        if merged.album == nil { merged.album = b.album }
        if merged.releaseYear == nil { merged.releaseYear = b.releaseYear }
        if merged.artists.count < b.artists.count { merged.artists = b.artists }
        if b.addedAt < merged.addedAt { merged.addedAt = b.addedAt }
        return merged
    }
}
