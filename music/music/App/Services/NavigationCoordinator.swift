import SwiftUI
import Combine

/// App tabs — migrator chrome (Home / Search / Migrations / Move).
public enum AppTab: Int, CaseIterable, Identifiable {
    case home = 0
    case search = 1
    case library = 2
    case create = 3
    
    // Aliases for compatibility
    public static let services = AppTab.home
    public static let transfer = AppTab.create
    public static let taste = AppTab.create
    public static let move = AppTab.create
    
    public var id: Int { rawValue }
    
    public var title: String {
        switch self {
        case .home: return MigratorChrome.homeTabTitle
        case .search: return MigratorChrome.searchTabTitle
        case .library: return MigratorChrome.migrationsTabTitle
        case .create: return MigratorChrome.moveTabTitle
        }
    }
}

/// Central Tab and Navigation Orchestrator for 1-Tap Metric Linking
@MainActor
public final class NavigationCoordinator: ObservableObject {
    public static let shared = NavigationCoordinator()
    
    @Published public var selectedTab: Int = AppTab.home.rawValue
    @Published public var showingPersonalLibrarySheet: Bool = false
    @Published public var showingConnectSheet: Bool = false
    @Published public var showingTasteSheet: Bool = false
    /// Global Yandex Device Flow sheet (Move / Connect / coordinator).
    @Published public var showingYandexConnectSheet: Bool = false
    /// Consumed by Search tab when jumping from Home search.
    @Published public var pendingSearchQuery: String?
    
    private init() {}
    
    public func openPersonalLibrary() {
        HapticManager.lightImpact()
        showingPersonalLibrarySheet = true
    }
    
    public func openYandexConnect() {
        HapticManager.lightImpact()
        showingYandexConnectSheet = true
    }
    
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
    
    public func navigateToSearch(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        pendingSearchQuery = trimmed.isEmpty ? nil : trimmed
        navigateTo(tab: .search)
    }
    
    public func consumePendingSearchQuery() -> String? {
        let value = pendingSearchQuery
        pendingSearchQuery = nil
        return value
    }
    
    public func navigateToLibrary() {
        navigateTo(tab: .library)
    }
    
    public func navigateToCreate() {
        navigateTo(tab: .create)
    }
    
    public func navigateToMove() {
        navigateTo(tab: .create)
    }
    
    public func navigateToServices() {
        HapticManager.lightImpact()
        showingConnectSheet = true
    }
    
    public func navigateToConnect() {
        navigateToServices()
    }
    
    public func navigateToTransfer() {
        navigateTo(tab: .create)
    }
    
    public func navigateToTaste() {
        HapticManager.lightImpact()
        showingTasteSheet = true
    }
    
    /// Apply a parsed `soundshift://` deep link (cold start or while running).
    public func apply(_ link: AppDeepLink) {
        switch link {
        case .spotifyCallback:
            return
        case .home:
            showingConnectSheet = false
            showingTasteSheet = false
            showingPersonalLibrarySheet = false
            navigateTo(tab: .home)
        case .search(let query):
            showingConnectSheet = false
            showingTasteSheet = false
            if let query, !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                navigateToSearch(query: query)
            } else {
                navigateToSearch()
            }
        case .library:
            showingConnectSheet = false
            showingTasteSheet = false
            navigateTo(tab: .library)
            openPersonalLibrary()
        case .connect:
            showingTasteSheet = false
            showingPersonalLibrarySheet = false
            navigateToConnect()
        case .move:
            showingConnectSheet = false
            showingTasteSheet = false
            showingPersonalLibrarySheet = false
            navigateToMove()
        case .taste:
            showingConnectSheet = false
            showingPersonalLibrarySheet = false
            navigateToTaste()
        }
    }
}
