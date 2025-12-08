import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var subscriptionService: SubscriptionService

    var body: some View {
        Group {
            if !appState.isOnboardingComplete {
                OnboardingView()
            } else {
                MainTabView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appState.isOnboardingComplete)
    }
}

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @State private var shouldInitializeScanner = false

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            Group {
                if shouldInitializeScanner {
                    ScannerView()
                        .id("scanner") // Force view recreation
                } else {
                    // Placeholder to prevent freeze during transition
                    Color.black
                        .ignoresSafeArea()
                }
            }
            .tabItem {
                Label("Scan", systemImage: "camera.viewfinder")
            }
            .tag(AppState.Tab.scanner)

            MyWinesView()
                .tabItem {
                    Label("My Wines", systemImage: "heart.fill")
                }
                .tag(AppState.Tab.myWines)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(AppState.Tab.settings)
        }
        .tint(Theme.primaryColor)
        .onAppear {
            // Initialize scanner after a brief delay to ensure transition completes
            Task { @MainActor in
                // Wait for transition to complete
                try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
                
                // Only initialize if we're on the scanner tab
                if appState.selectedTab == .scanner {
                    shouldInitializeScanner = true
                }
            }
        }
        .onChange(of: appState.selectedTab) { newTab in
            // Initialize scanner when user switches to scanner tab
            if newTab == .scanner && !shouldInitializeScanner {
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                    shouldInitializeScanner = true
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
        .environmentObject(SubscriptionService.shared)
}
