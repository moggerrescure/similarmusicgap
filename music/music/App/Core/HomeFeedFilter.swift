import Foundation

/// Home header pills: All / Music / Podcasts.
public enum HomeFeedFilter: String, CaseIterable, Identifiable, Sendable {
    case all = "All"
    case music = "Music"
    case podcasts = "Podcasts"
    
    public var id: String { rawValue }
}

/// What the Home feed should show for a given filter (honest: no podcast catalog).
public enum HomeFeedFilterLogic {
    /// Music shelves, vinyl, cassettes, shortcuts — yes for All & Music.
    public static func showsMusicContent(_ filter: HomeFeedFilter) -> Bool {
        switch filter {
        case .all, .music: return true
        case .podcasts: return false
        }
    }
    
    /// Empty-state card: Podcasts aren't supported in SoundShift yet.
    public static func showsPodcastsEmptyState(_ filter: HomeFeedFilter) -> Bool {
        filter == .podcasts
    }
}
