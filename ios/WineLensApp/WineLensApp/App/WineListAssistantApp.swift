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
        #if DEBUG
        print("🏠 AppState init: isOnboardingComplete=\(isOnboardingComplete)")
        #endif
    }

    func completeOnboarding() {
        #if DEBUG
        print("🏠 AppState.completeOnboarding() called")
        #endif

        // Save to UserDefaults first (synchronous, fast)
        UserDefaults.standard.set(true, forKey: "onboarding_complete")

        // Update UI immediately with animation (MainActor ensures we're on main thread)
        withAnimation(.easeInOut(duration: 0.25)) {
            isOnboardingComplete = true
        }

        #if DEBUG
        print("🏠 AppState.completeOnboarding() - isOnboardingComplete now: \(isOnboardingComplete)")
        #endif
    }

    /// Resets the app to initial state (for testing purposes)
    func resetApp() {
        // Clear onboarding state
        UserDefaults.standard.removeObject(forKey: Constants.StorageKeys.onboardingComplete)

        // Clear scan count
        UserDefaults.standard.removeObject(forKey: Constants.StorageKeys.scansThisMonth)
        UserDefaults.standard.removeObject(forKey: Constants.StorageKeys.scansMonthStart)

        // Clear other preferences
        UserDefaults.standard.removeObject(forKey: Constants.StorageKeys.userPreferences)

        // Sync UserDefaults
        UserDefaults.standard.synchronize()

        // Update UI with animation
        withAnimation(.easeInOut(duration: 0.25)) {
            isOnboardingComplete = false
            selectedTab = .scanner
        }
    }
}
