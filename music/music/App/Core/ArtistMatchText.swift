import Foundation

/// Artist string used by MatchingEngine fuzzy compare (all credited artists).
public enum ArtistMatchText {
    public static func joined(_ artists: [String]) -> String {
        let cleaned = artists
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        if cleaned.isEmpty { return "" }
        return cleaned.joined(separator: " ")
    }
    
    public static func joined(from track: UniversalTrack) -> String {
        let joined = Self.joined(track.artists)
        return joined.isEmpty ? track.primaryArtist : joined
    }
}
