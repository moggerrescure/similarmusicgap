import SwiftUI

/// Root Tab Navigation — designer Spotify-standard tabs + floating mini-player
/// Home / Search / Your Library / Create(+Transfer). Connect & Taste as sheets.
public struct MainTabView: View {
    @ObservedObject private var navCoordinator = NavigationCoordinator.shared
    @ObservedObject private var coordinator = ServicesCoordinator.shared
    @ObservedObject private var player = AudioPlayerManager.shared
    
    public init() {}
    
    public var body: some View {
        ZStack(alignment: .bottom) {
            // OLED Cashmere Charcoal Base (#0E0F12)
            PastelTheme.canvas
                .ignoresSafeArea()
            
            TabView(selection: $navCoordinator.selectedTab) {
                // Tab 1: Home (Personalized Feed)
                SpotifyHomeFeedView()
                    .tabItem {
                        Image(systemName: navCoordinator.selectedTab == 0 ? "house.fill" : "house")
                        Text("Home")
                    }
                    .accessibilityIdentifier("tab.home")
                    .tag(0)
                
                // Tab 2: Search (Search & Browse All Genres)
                SpotifySearchBrowseView()
                    .tabItem {
                        Image(systemName: "magnifyingglass")
                        Text("Search")
                    }
                    .accessibilityIdentifier("tab.search")
                    .tag(1)
                
                // Tab 3: Your Library
                LibraryView()
                    .tabItem {
                        Image(systemName: navCoordinator.selectedTab == 2 ? "books.vertical.fill" : "books.vertical")
                        Text("Your Library")
                    }
                    .accessibilityIdentifier("tab.library")
                    .tag(2)
                
                // Tab 4: Create / Transfer
                NavigationStack {
                    TransferConfigView()
                }
                .tabItem {
                    Image(systemName: "plus")
                    Text("Create")
                }
                .accessibilityIdentifier("tab.create")
                .tag(3)
            }
            .tint(Color.white)
            
            VStack(spacing: 8) {
                if let notice = player.favoriteSyncNotice {
                    Text(notice)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(PastelTheme.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(PastelTheme.card)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(PastelTheme.amberWarning.opacity(0.45), lineWidth: 1)
                        )
                        .padding(.horizontal, 16)
                        .accessibilityIdentifier("notice.favorite_sync")
                        .onTapGesture { player.dismissFavoriteSyncNotice() }
                }
                
                // Spotify-Grade Floating Mini-Player (docked above bottom nav bar)
                FloatingMiniPlayerView()
            }
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
        .task {
            if coordinator.activeProvidersCount > 0 && coordinator.allTracks.isEmpty {
                await coordinator.syncAll()
            }
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
