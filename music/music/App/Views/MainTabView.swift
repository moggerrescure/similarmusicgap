import SwiftUI

/// Root Tab Navigation Bar (Apple HIG HUD Standard)
public struct MainTabView: View {
    @ObservedObject private var navCoordinator = NavigationCoordinator.shared
    
    public init() {}
    
    public var body: some View {
        ZStack(alignment: .bottom) {
            // Deep OLED Canvas Base
            PastelTheme.canvas
                .ignoresSafeArea()
            
            TabView(selection: $navCoordinator.selectedTab) {
                // Tab 1: Services Hub
                ServicesHubView()
                    .tabItem {
                        Label("Services", systemImage: "link.circle.fill")
                    }
                    .tag(0)
                
                // Tab 2: Library
                LibraryView()
                    .tabItem {
                        Label("Library", systemImage: "music.note.list")
                    }
                    .tag(1)
                
                // Tab 3: Transfer
                NavigationStack {
                    TransferConfigView()
                }
                .tabItem {
                    Label("Transfer", systemImage: "arrow.triangle.swap")
                }
                .tag(2)
                
                // Tab 4: Taste Profile
                NavigationStack {
                    TasteAnalyticsView()
                }
                .tabItem {
                    Label("Taste", systemImage: "chart.bar.fill")
                }
                .tag(3)
            }
            .tint(PastelTheme.pastelOat)
            
            FloatingMiniPlayerView()
        }
        .onAppear {
            customizeTabBarAppearance()
        }
    }
    
    private func customizeTabBarAppearance() {
        #if os(iOS)
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        appearance.backgroundColor = UIColor(PastelTheme.canvas).withAlphaComponent(0.85)
        
        // Unselected items
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(PastelTheme.textTertiary)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(PastelTheme.textTertiary),
            .font: UIFont.systemFont(ofSize: 10, weight: .medium)
        ]
        
        // Selected items
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(PastelTheme.pastelOat)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(PastelTheme.pastelOat),
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

