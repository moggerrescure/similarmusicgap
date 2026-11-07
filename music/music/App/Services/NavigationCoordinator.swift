import SwiftUI
import Combine

/// App Tab Identifiers (Matching Spotify Production 4-Tab Standard)
public enum AppTab: Int, CaseIterable, Identifiable {
    case home = 0
    case search = 1
    case library = 2
    case create = 3
    
    // Aliases for compatibility
    public static let services = AppTab.home
    public static let transfer = AppTab.create
    public static let taste = AppTab.create
    
    public var id: Int { rawValue }
    
    public var title: String {
        switch self {
        case .home: return "Home"
        case .search: return "Search"
        case .library: return "Your Library"
        case .create: return "Create"
        }
    }
}

/// Central Tab and Navigation Orchestrator for 1-Tap Metric Linking
@MainActor
public final class NavigationCoordinator: ObservableObject {
    public static let shared = NavigationCoordinator()
    
    @Published public var selectedTab: Int = AppTab.home.rawValue
    
    private init() {}
    
    public func navigateTo(tab: AppTab) {
        HapticManager.lightImpact()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            self.selectedTab = tab.rawValue
        }
    }
    
    public func navigateToHome() {
        navigateTo(tab: .home)
    }
    
    public func navigateToSearch() {
        navigateTo(tab: .search)
    }
    
    public func navigateToLibrary() {
        navigateTo(tab: .library)
    }
    
    public func navigateToCreate() {
        navigateTo(tab: .create)
    }
    
    public func navigateToServices() {
        navigateTo(tab: .home)
    }
    
    public func navigateToTransfer() {
        navigateTo(tab: .create)
    }
    
    public func navigateToTaste() {
        navigateTo(tab: .create)
    }
}
