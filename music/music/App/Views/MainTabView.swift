import SwiftUI

/// Root Tab Navigation — migrator: Home / Search / Migrations / Move + mini-player.
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
                SpotifyHomeFeedView()
                    .tabItem {
                        Image(systemName: navCoordinator.selectedTab == 0 ? "house.fill" : "house")
                        Text(MigratorChrome.homeTabTitle)
                    }
                    .accessibilityIdentifier("tab.home")
                    .tag(0)
                
                SpotifySearchBrowseView()
                    .tabItem {
                        Image(systemName: "magnifyingglass")
                        Text(MigratorChrome.searchTabTitle)
                    }
                    .accessibilityIdentifier("tab.search")
                    .tag(1)
                
                LibraryView()
                    .tabItem {
                        // Keep SF Symbol books.vertical — Maestro + a11y rely on it; label = Migrations.
                        Image(systemName: navCoordinator.selectedTab == 2 ? "books.vertical.fill" : "books.vertical")
                        Text(MigratorChrome.migrationsTabTitle)
                    }
                    .accessibilityIdentifier("tab.library")
                    .tag(2)
                
                NavigationStack {
                    TransferConfigView()
                }
                .tabItem {
                    Image(systemName: "plus")
                    Text(MigratorChrome.moveTabTitle)
                }
                .accessibilityIdentifier("tab.create")
                .tag(3)
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
