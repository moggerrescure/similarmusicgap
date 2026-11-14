import Foundation

/// In-app destinations reachable via `soundshift://` URLs.
public enum AppDeepLink: Equatable {
    case home
    case search(query: String?)
    case library
    case connect
    case move
    case taste
    
    /// OAuth callback — owned by ASWebAuthenticationSession; app ignores.
    case spotifyCallback
}

/// Pure URL → destination parser (no UIKit). Testable offline.
public enum AppDeepLinkRouter {
    public static func parse(_ url: URL) -> AppDeepLink? {
        guard let scheme = url.scheme?.lowercased(), scheme == "soundshift" else {
            return nil
        }
        
        let host = (url.host ?? "").lowercased()
        let path = url.path.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        
        // soundshift://spotify-callback  OR  soundshift:///spotify-callback
        if host == "spotify-callback" || path == "spotify-callback" {
            return .spotifyCallback
        }
        
        let route = host.isEmpty ? path : host
        switch route {
        case "", "home":
            return .home
        case "search", "browse":
            let q = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?
                .first(where: { $0.name == "q" || $0.name == "query" })?
                .value
            return .search(query: q)
        case "library", "liked":
            return .library
        case "connect", "services":
            return .connect
        case "move", "create", "transfer":
            return .move
        case "taste", "insights":
            return .taste
        default:
            return nil
        }
    }
}
