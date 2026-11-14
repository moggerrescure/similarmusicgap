import Foundation

/// Honest progress stages for live migration UI (HUD / Bridge).
public enum MigrationPhase: String, Equatable {
    case idle
    case preparing
    case matching
    case writingPlaylist
    case done
    case failed
    
    /// Short eyebrow above the progress ring.
    public var eyebrow: String {
        switch self {
        case .idle: return "READY"
        case .preparing: return "PREPARING"
        case .matching: return "MATCHING"
        case .writingPlaylist: return "WRITING PLAYLIST"
        case .done: return "DONE"
        case .failed: return "FAILED"
        }
    }
    
    /// What the processedCount counter means right now.
    public var counterLabel: String {
        switch self {
        case .matching, .preparing:
            return "CHECKED"
        case .writingPlaylist:
            return "WRITING"
        case .done:
            return "FINISHED"
        case .failed:
            return "STOPPED"
        case .idle:
            return "TRACKS"
        }
    }
    
    /// One-line tip under the counter for non-experts.
    public var userHint: String {
        switch self {
        case .idle:
            return "Start a dry-run first, then migrate when the pair is LIVE."
        case .preparing:
            return "Collecting your selected tracks…"
        case .matching:
            return "Finding each song on the destination — nothing is written yet."
        case .writingPlaylist:
            return "Creating a new playlist on the destination service."
        case .done:
            return "You can open the report for missing tracks and rematches."
        case .failed:
            return "Nothing harmful was assumed — check Connect and try again."
        }
    }
    
    public var showsSuccessChrome: Bool {
        self == .done
    }
}

/// Builds the destination playlist title the user will recognize.
public enum PlaylistNameBuilder {
    public static func resolve(custom: String?, source: MusicProviderType) -> String {
        let trimmed = custom?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !trimmed.isEmpty { return trimmed }
        return "SoundShift · from \(source.displayName)"
    }
}

/// Plain-text list for clipboard / share of unresolved tracks.
public enum MissingTracksExport {
    public static func plainText(_ tracks: [UniversalTrack], limit: Int = 200) -> String {
        guard !tracks.isEmpty else { return "No missing tracks." }
        let lines = tracks.prefix(limit).map { "\($0.primaryArtist) — \($0.title)" }
        let suffix = tracks.count > limit ? "\n…and \(tracks.count - limit) more" : ""
        return lines.joined(separator: "\n") + suffix
    }
}
