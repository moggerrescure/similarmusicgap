import SwiftUI

/// Root Tab Navigation Bar (Apple HIG HUD Standard)
public struct MainTabView: View {
    @State private var selectedTab: Int = 0
    
    public init() {}
    
    public var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Connected Services (A4, A5)
            ServicesHubView()
                .tabItem {
                    Label("Services", systemImage: "antenna.radiowaves.left.and.right")
                }
                .tag(0)
            
            // Tab 2: Universal Library (L1, L2, L3, L5, L6)
            LibraryView()
                .tabItem {
                    Label("Library", systemImage: "music.note.list")
                }
                .tag(1)
            
            // Tab 3: Transfer Studio (T1 - T13)
            NavigationStack {
                TransferConfigView()
            }
            .tabItem {
                Label("Transfer", systemImage: "arrow.left.arrow.right")
            }
            .tag(2)
            
            // Tab 4: Taste DNA & 9:16 Social Stories (S1 - S3, SO1)
            NavigationStack {
                TasteAnalyticsView()
            }
            .tabItem {
                Label("Taste DNA", systemImage: "sparkles")
            }
            .tag(3)
        }
        .tint(PastelTheme.pastelOat)
        .onAppear {
            customizeTabBarAppearance()
        }
    }
    
    private func customizeTabBarAppearance() {
        #if os(iOS)
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(PastelTheme.canvas)
        
        // Unselected items
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(PastelTheme.textTertiary)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(PastelTheme.textTertiary)
        ]
        
        // Selected items
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(PastelTheme.pastelOat)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(PastelTheme.pastelOat)
        ]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        #endif
    }
}

#Preview {
    MainTabView()
}

