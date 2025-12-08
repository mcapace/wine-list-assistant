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
    @State private var shouldInitializeScanner = false

    var body: some View {
        let _ = {
            #if DEBUG
            print("📱 MainTabView.body evaluated - shouldInitializeScanner=\(shouldInitializeScanner)")
            #endif
        }()

        TabView(selection: $appState.selectedTab) {
            Group {
                if shouldInitializeScanner {
                    let _ = {
                        #if DEBUG
                        print("📱 MainTabView: Creating ScannerView...")
                        #endif
                    }()
                    ScannerView()
                        .id("scanner") // Force view recreation
                        .onAppear {
                            #if DEBUG
                            print("📱 ScannerView.onAppear called from MainTabView")
                            #endif
                        }
                } else {
                    // Placeholder to prevent freeze during transition
                    Color.black
                        .ignoresSafeArea()
                        .onAppear {
                            #if DEBUG
                            print("📱 MainTabView: Showing black placeholder (scanner not initialized yet)")
                            #endif
                        }
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
            #if DEBUG
            print("📱 MainTabView.onAppear - selectedTab=\(appState.selectedTab), shouldInitializeScanner=\(shouldInitializeScanner)")
            #endif

            // Initialize scanner after a brief delay to ensure transition completes
            Task { @MainActor in
                // Wait for transition to complete
                try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds

                #if DEBUG
                print("📱 MainTabView: After 0.3s delay, selectedTab=\(appState.selectedTab)")
                #endif

                // Only initialize if we're on the scanner tab
                if appState.selectedTab == .scanner {
                    #if DEBUG
                    print("📱 MainTabView: Setting shouldInitializeScanner = true")
                    #endif
                    shouldInitializeScanner = true
                }
            }
        }
        .onChange(of: shouldInitializeScanner) { oldValue, newValue in
            #if DEBUG
            print("📱 MainTabView: shouldInitializeScanner changed from \(oldValue) to \(newValue)")
            #endif
        }
        .onChange(of: appState.selectedTab) { oldValue, newValue in
            #if DEBUG
            print("📱 MainTabView: Tab changed from \(oldValue) to \(newValue)")
            #endif

            // Initialize scanner when user switches to scanner tab
            if newValue == .scanner && !shouldInitializeScanner {
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
