import SwiftUI
import Combine

/// App Tab Identifiers
public enum AppTab: Int, CaseIterable, Identifiable {
    case services = 0
    case library = 1
    case transfer = 2
    case taste = 3
    
    public var id: Int { rawValue }
    
    public var title: String {
        switch self {
        case .services: return "Services"
        case .library: return "Library"
        case .transfer: return "Transfer"
        case .taste: return "Taste"
        }
    }
}

/// Central Tab and Navigation Orchestrator for 1-Tap Metric Linking
@MainActor
public final class NavigationCoordinator: ObservableObject {
    public static let shared = NavigationCoordinator()
    
    @Published public var selectedTab: Int = AppTab.services.rawValue
    
    private init() {}
    
    public func navigateTo(tab: AppTab) {
        HapticManager.lightImpact()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            self.selectedTab = tab.rawValue
        }
    }
    
    public func navigateToLibrary() {
        navigateTo(tab: .library)
    }
    
    public func navigateToServices() {
        navigateTo(tab: .services)
    }
    
    public func navigateToTransfer() {
        navigateTo(tab: .transfer)
    }
    
    public func navigateToTaste() {
        navigateTo(tab: .taste)
    }
}

