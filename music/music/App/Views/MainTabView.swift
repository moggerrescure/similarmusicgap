import SwiftUI

/// Root Tab Navigation — 3-tab architecture: Radar / Vault / Bridge + mini-player.
/// Connect & Taste stay sheets.
public struct MainTabView: View {
    @ObservedObject private var navCoordinator = NavigationCoordinator.shared
    
    public init() {}
    
    public var body: some View {
        ZStack(alignment: .bottom) {
            // OLED Cashmere Charcoal Base (#0E0F12)
            PastelTheme.canvas
                .ignoresSafeArea()
            
            TabView(selection: $navCoordinator.selectedTab) {
                // Tab 1: Radar (Cross-Platform Matcher & Gap Resolver)
                BridgeRadarSearchView()
                    .tabItem {
                        Image(systemName: navCoordinator.selectedTab == AppTab.search.rawValue ? "sparkle.magnifyingglass" : "magnifyingglass")
                        Text("Radar")
                    }
                    .accessibilityIdentifier("tab.search")
                    .tag(AppTab.search.rawValue)
                
                // Tab 2: Vault (Universal Library & Duplicates)
                LibraryView()
                    .tabItem {
                        Image(systemName: navCoordinator.selectedTab == AppTab.library.rawValue ? "books.vertical.fill" : "books.vertical")
                        Text("Vault")
                    }
                    .accessibilityIdentifier("tab.library")
                    .tag(AppTab.library.rawValue)
                
                // Tab 3: Bridge (Mass Migration & File Export)
                NavigationStack {
                    TransferConfigView()
                }
                .tabItem {
                    Image(systemName: navCoordinator.selectedTab == AppTab.create.rawValue ? "bolt.horizontal.fill" : "arrow.left.arrow.right")
                    Text("Bridge")
                }
                .accessibilityIdentifier("tab.create")
                .tag(AppTab.create.rawValue)
            }
            .tint(Color.white)
            
            // Spotify-Grade Floating Mini-Player (docked above bottom nav bar)
            FloatingMiniPlayerView()
        }
        .sheet(isPresented: $navCoordinator.showingPersonalLibrarySheet) {
            UserPersonalLibrarySheet()
        }
        .sheet(isPresented: $navCoordinator.showingConnectSheet) {
            NavigationStack {
                ServicesHubView()
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                navCoordinator.showingConnectSheet = false
                            }
                            .foregroundColor(PastelTheme.pastelOat)
                        }
                    }
            }
        }
        .sheet(isPresented: $navCoordinator.showingTasteSheet) {
            NavigationStack {
                TasteAnalyticsView()
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                navCoordinator.showingTasteSheet = false
                            }
                            .foregroundColor(PastelTheme.pastelOat)
                        }
                    }
            }
        }
        .sheet(isPresented: $navCoordinator.showingYandexConnectSheet) {
            YandexConnectSheet()
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
