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
    @State private var hasAppeared = false

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            // Only create ScannerView after main view has appeared to prevent freeze
            if hasAppeared {
                ScannerView()
                    .tabItem {
                        Label("Scan", systemImage: "camera.viewfinder")
                    }
                    .tag(AppState.Tab.scanner)
            } else {
                // Placeholder during initial load
                Color.black
                    .tabItem {
                        Label("Scan", systemImage: "camera.viewfinder")
                    }
                    .tag(AppState.Tab.scanner)
            }

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
            // Delay ScannerView creation to ensure smooth transition
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                hasAppeared = true
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
        .environmentObject(SubscriptionService.shared)
}
