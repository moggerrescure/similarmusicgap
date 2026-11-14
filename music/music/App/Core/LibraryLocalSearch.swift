import Foundation

/// On-device search over the synced SoundShift library (no remote Spotify catalog).
public enum LibraryLocalSearch {
    public struct Results: Equatable {
        public var tracks: [UniversalTrack]
        public var playlists: [UniversalPlaylist]
        public var artists: [String]
        
        public var isEmpty: Bool {
            tracks.isEmpty && playlists.isEmpty && artists.isEmpty
        }
        
        public init(
            tracks: [UniversalTrack] = [],
            playlists: [UniversalPlaylist] = [],
            artists: [String] = []
        ) {
            self.tracks = tracks
            self.playlists = playlists
            self.artists = artists
        }
    }
    
    /// Case-insensitive match against title / artists / album / playlist title.
    public static func search(
        query: String,
        tracks: [UniversalTrack],
        playlists: [UniversalPlaylist],
        trackLimit: Int = 40,
        playlistLimit: Int = 12,
        artistLimit: Int = 12
    ) -> Results {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else {
            return Results()
        }
        
        let matchedTracks = tracks.filter { track in
            if track.title.lowercased().contains(q) { return true }
            if track.primaryArtist.lowercased().contains(q) { return true }
            if track.artists.contains(where: { $0.lowercased().contains(q) }) { return true }
            if let album = track.album?.lowercased(), album.contains(q) { return true }
            return false
        }
        
        let matchedPlaylists = playlists.filter { playlist in
            if playlist.title.lowercased().contains(q) { return true }
            if let description = playlist.description?.lowercased(), description.contains(q) {
                return true
            }
            return false
        }
        
        var seenArtists = Set<String>()
        var artists: [String] = []
        for track in matchedTracks {
            let name = track.primaryArtist
            let key = name.lowercased()
            if seenArtists.insert(key).inserted {
                artists.append(name)
            }
            if artists.count >= artistLimit { break }
        }
        
        return Results(
            tracks: Array(matchedTracks.prefix(trackLimit)),
            playlists: Array(matchedPlaylists.prefix(playlistLimit)),
            artists: artists
        )
    }
    
    /// Prefer a real synced track for a browse tag; never invent a fake track.
    public static func firstTrack(
        matchingTag tag: String,
        in tracks: [UniversalTrack]
    ) -> UniversalTrack? {
        let q = tag.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return tracks.first }
        return tracks.first { track in
            track.title.lowercased().contains(q)
                || track.primaryArtist.lowercased().contains(q)
                || track.artists.contains(where: { $0.lowercased().contains(q) })
                || (track.album?.lowercased().contains(q) ?? false)
        }
    }
}
