import SwiftUI

@main
struct SoundShiftApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    // Spotify PKCE redirect is registered as soundshift://spotify-callback
                    // and is consumed by ASWebAuthenticationSession during Connect.
                    // This handler covers cold-start / non-ASWeb deep links only.
                    handleIncomingURL(url)
                }
        }
    }
    
    private func handleIncomingURL(_ url: URL) {
        guard let link = AppDeepLinkRouter.parse(url) else { return }
        // OAuth callback is owned by ASWebAuthenticationSession during Connect.
        guard link != .spotifyCallback else { return }
        Task { @MainActor in
            NavigationCoordinator.shared.apply(link)
        }
    }
}
