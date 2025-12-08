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
    @State private var scannerReady = false

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            // Always create ScannerView - don't use conditional that might prevent instantiation
            // Use background instead of opacity to ensure view is actually rendered
            ZStack {
                if scannerReady {
                    ScannerView()
                        .transition(.opacity)
                } else {
                    Color.black
                        .ignoresSafeArea()
                }
            }
            .id("scanner") // Force view recreation
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
            print("📱 MainTabView.onAppear - selectedTab=\(appState.selectedTab), scannerReady=\(scannerReady)")
            #endif

            // Make scanner visible after a brief delay to ensure transition completes
            Task { @MainActor in
                // Wait for transition to complete
                try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds

                #if DEBUG
                print("📱 MainTabView: After 0.3s delay, making scanner visible")
                #endif

                withAnimation {
                    scannerReady = true
                }
            }
        }
        .onChange(of: appState.selectedTab) { oldValue, newValue in
            #if DEBUG
            print("📱 MainTabView: Tab changed from \(oldValue) to \(newValue)")
            #endif

            // Make scanner visible when user switches to scanner tab
            if newValue == .scanner && !scannerReady {
                withAnimation {
                    scannerReady = true
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
