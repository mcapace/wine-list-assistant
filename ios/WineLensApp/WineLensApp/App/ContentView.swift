import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var subscriptionService: SubscriptionService

    var body: some View {
        Group {
            if !appState.isOnboardingComplete {
                OnboardingView()
                    .onAppear {
                        #if DEBUG
                        print("📱 ContentView: Showing OnboardingView")
                        #endif
                    }
            } else {
                MainTabView()
                    .transition(.opacity)
                    .onAppear {
                        #if DEBUG
                        print("📱 ContentView: Showing MainTabView (transition complete)")
                        #endif
                    }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appState.isOnboardingComplete)
    }
}

struct MainTabView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            // ALWAYS create and show ScannerView immediately
            // This ensures StateObject (viewModel) is initialized and body is evaluated
            ScannerView()
                .id("scanner")
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
            #if DEBUG
            print("📱 MainTabView.onAppear - selectedTab=\(appState.selectedTab)")
            print("📱 MainTabView: ScannerView should be rendering now")
            #endif
        }
        .onChange(of: appState.selectedTab) { oldValue, newValue in
            #if DEBUG
            print("📱 MainTabView: Tab changed from \(oldValue) to \(newValue)")
            #endif
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
        .environmentObject(SubscriptionService.shared)
}
