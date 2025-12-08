import SwiftUI
import Combine

@main
struct WineLensApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var subscriptionService = SubscriptionService.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(subscriptionService)
                .task {
                    // Load subscription data asynchronously with proper cancellation handling
                    async let productsTask = subscriptionService.loadProducts()
                    async let statusTask = subscriptionService.updateSubscriptionStatus()
                    
                    // Wait for both tasks to complete (or be cancelled)
                    await productsTask
                    await statusTask
                }
        }
    }
}

@MainActor
final class AppState: ObservableObject {
    @Published var isOnboardingComplete: Bool
    @Published var selectedTab: Tab = .scanner

    enum Tab {
        case scanner
        case myWines
        case settings
    }

    init() {
        self.isOnboardingComplete = UserDefaults.standard.bool(forKey: "onboarding_complete")
    }

    func completeOnboarding() {
        // Save to UserDefaults first (synchronous, fast)
        UserDefaults.standard.set(true, forKey: "onboarding_complete")
        
        // Update UI immediately with animation (MainActor ensures we're on main thread)
        withAnimation(.easeInOut(duration: 0.25)) {
            isOnboardingComplete = true
        }
    }
}
