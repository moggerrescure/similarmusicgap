import SwiftUI

/// Root Tab Navigation Bar replicating Spotify Production Standard
public struct MainTabView: View {
    @ObservedObject private var navCoordinator = NavigationCoordinator.shared
    
    public init() {}
    
    public var body: some View {
        ZStack(alignment: .bottom) {
            // Pure Pitch Black Base (#121212)
            Color(hex: "#121212")
                .ignoresSafeArea()
            
            TabView(selection: $navCoordinator.selectedTab) {
                // Tab 1: SoundShift Acoustic Command Deck (Apple HIG HUD)
                SoundShiftHomeFeedView()
                    .tabItem {
                        Image(systemName: navCoordinator.selectedTab == 0 ? "house.fill" : "house")
                        Text("Home")
                    }
                    .tag(0)
                
                // Tab 2: Search (Search & Browse All Genres)
                SpotifySearchBrowseView()
                    .tabItem {
                        Image(systemName: "magnifyingglass")
                        Text("Search")
                    }
                    .tag(1)
                
                // Tab 3: Your Library
                LibraryView()
                    .tabItem {
                        Image(systemName: navCoordinator.selectedTab == 2 ? "books.vertical.fill" : "books.vertical")
                        Text("Your Library")
                    }
                    .tag(2)
                
                // Tab 4: Create / Transfer
                NavigationStack {
                    TransferConfigView()
                }
                .tabItem {
                    Image(systemName: "plus")
                    Text("Create")
                }
                .tag(3)
            }
            .tint(Color.white)
            
            // Spotify-Grade Floating Mini-Player (docked above bottom nav bar)
            FloatingMiniPlayerView()
        }
        .onAppear {
            customizeSpotifyTabBarAppearance()
        }
    }
    
    private func customizeSpotifyTabBarAppearance() {
        #if os(iOS)
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        appearance.backgroundColor = UIColor(Color(hex: "#090909")).withAlphaComponent(0.94)
        
        // Unselected items (muted gray #B3B3B3)
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(Color(hex: "#B3B3B3"))
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(Color(hex: "#B3B3B3")),
            .font: UIFont.systemFont(ofSize: 10, weight: .medium)
        ]
        
        // Selected items (pure white #FFFFFF)
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor.white
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 10, weight: .bold)
        ]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        #endif
    }
}

#if DEBUG
struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
#endif
