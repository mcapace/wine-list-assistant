import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var subscriptionService: SubscriptionService
    @EnvironmentObject var appState: AppState
    @StateObject private var authService = AuthenticationService.shared
    @State private var showSubscription = false
    @State private var showSignIn = false
    @State private var showSignOut = false

    var body: some View {
        NavigationView {
            List {
                // Account Section
                Section("Account") {
                    if authService.isAuthenticated, let user = authService.currentUser {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(user.displayName)
                                    .font(.headline)
                                Text(user.email)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button("Sign Out") {
                                showSignOut = true
                            }
                            .foregroundColor(.red)
                        }
                    } else {
                        Button("Sign In") {
                            showSignIn = true
                        }
                    }
                }

                // Subscription Section
                Section("Subscription") {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(subscriptionStatusTitle)
                                .font(.headline)
                            Text(subscriptionStatusSubtitle)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if !subscriptionService.subscriptionStatus.isActive {
                            Button("Upgrade") {
                                showSubscription = true
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }

                    if !subscriptionService.subscriptionStatus.isActive {
                        HStack {
                            Text("Free scans remaining")
                            Spacer()
                            Text("\(subscriptionService.remainingFreeScans()) of \(AppConfiguration.freeScansPerMonth)")
                                .foregroundColor(.secondary)
                        }
                    }

                    Button("Restore Purchases") {
                        Task {
                            try? await subscriptionService.restorePurchases()
                        }
                    }
                }

                // App Section
                Section("App") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("\(AppConfiguration.appVersion) (\(AppConfiguration.buildNumber))")
                            .foregroundColor(.secondary)
                    }
                    
                    #if DEBUG
                    // Development: Reset scan count
                    Button(action: {
                        subscriptionService.resetScanCount()
                    }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Reset Scan Count (Dev)")
                        }
                        .foregroundColor(.orange)
                    }
                    #endif

                    Link(destination: URL(string: "https://www.winespectator.com/privacy")!) {
                        HStack {
                            Text("Privacy Policy")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                        }
                    }

                    Link(destination: URL(string: "https://www.winespectator.com/terms")!) {
                        HStack {
                            Text("Terms of Service")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                        }
                    }

                    Link(destination: URL(string: "mailto:support@winespectator.com")!) {
                        HStack {
                            Text("Contact Support")
                            Spacer()
                            Image(systemName: "envelope")
                                .font(.caption)
                        }
                    }
                }

                // About Section
                Section("About") {
                    VStack(spacing: 16) {
                        // Wine Spectator logo
                        WineSpectatorLogo(variant: .black, height: 28)
                        
                        // WineLens badge
                        WineLensBadge(style: .dark)
                        
                        Text("Powered by Wine Spectator's database of 450,000+ expert wine reviews.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showSubscription) {
                SubscriptionView()
            }
            .sheet(isPresented: $showSignIn) {
                SignInView()
            }
            .confirmationDialog("Sign Out", isPresented: $showSignOut, titleVisibility: .visible) {
                Button("Sign Out", role: .destructive) {
                    Task {
                        await authService.signOut()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }

    private var subscriptionStatusTitle: String {
        switch subscriptionService.subscriptionStatus {
        case .unknown:
            return "Loading..."
        case .notSubscribed:
            return "Free Plan"
        case .subscribed:
            return "Premium"
        case .expired:
            return "Expired"
        }
    }

    private var subscriptionStatusSubtitle: String {
        switch subscriptionService.subscriptionStatus {
        case .unknown:
            return ""
        case .notSubscribed:
            return "Limited to \(AppConfiguration.freeScansPerMonth) scans/month"
        case .subscribed(let expiration, _):
            if let date = expiration {
                return "Renews \(date.formatted(date: .abbreviated, time: .omitted))"
            }
            return "Active"
        case .expired:
            return "Please renew your subscription"
        }
    }
}

// MARK: - Sign In View (Placeholder)

struct SignInView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false

    var body: some View {
        NavigationView {
            VStack(spacing: Theme.Spacing.xl) {
                // Logo - use WineLensBadge component
                VStack(spacing: 12) {
                    WineSpectatorLogo(variant: .black, height: 32)
                    WineLensBadge(style: .dark)
                }

                // Sign in with Apple
                SignInWithAppleButton()
                    .frame(height: 50)
                    .padding(.horizontal)

                Divider()
                    .padding(.horizontal)

                // Email/Password
                VStack(spacing: Theme.Spacing.md) {
                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)

                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.password)

                    Button(action: signIn) {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("Sign In")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    .disabled(email.isEmpty || password.isEmpty || isLoading)
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top, Theme.Spacing.xxl)
            .navigationTitle("Sign In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func signIn() {
        isLoading = true
        Task {
            do {
                try await AuthenticationService.shared.signIn(email: email, password: password)
                dismiss()
            } catch {
                print("Sign in failed: \(error)")
            }
            isLoading = false
        }
    }
}

// Placeholder for Sign in with Apple button
struct SignInWithAppleButton: View {
    var body: some View {
        Button(action: {}) {
            HStack {
                Image(systemName: "apple.logo")
                Text("Sign in with Apple")
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.black)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(SubscriptionService.shared)
        .environmentObject(AppState())
}
