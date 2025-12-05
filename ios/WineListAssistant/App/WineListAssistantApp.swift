import SwiftUI

@main
struct WineListAssistantApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var subscriptionService = SubscriptionService.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(subscriptionService)
                .task {
                    await subscriptionService.loadProducts()
                    await subscriptionService.updateSubscriptionStatus()
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
        isOnboardingComplete = true
        UserDefaults.standard.set(true, forKey: "onboarding_complete")
    }
}
