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
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        SettingsHeader()

                        // Subscription Card
                        SubscriptionCard(
                            subscriptionService: subscriptionService,
                            onUpgrade: { showSubscription = true }
                        )

                        // Account Section
                        SettingsSection(title: "Account", icon: "person.circle.fill") {
                            if authService.isAuthenticated, let user = authService.currentUser {
                                AccountRow(user: user, onSignOut: { showSignOut = true })
                            } else {
                                SignInRow(onSignIn: { showSignIn = true })
                            }
                        }

                        // App Section
                        SettingsSection(title: "App", icon: "app.fill") {
                            SettingsRow(
                                icon: "info.circle",
                                title: "Version",
                                value: "\(AppConfiguration.appVersion) (\(AppConfiguration.buildNumber))"
                            )

                            Divider().padding(.leading, 44)

                            SettingsLinkRow(
                                icon: "lock.shield",
                                title: "Privacy Policy",
                                url: "https://www.winespectator.com/privacy"
                            )

                            Divider().padding(.leading, 44)

                            SettingsLinkRow(
                                icon: "doc.text",
                                title: "Terms of Service",
                                url: "https://www.winespectator.com/terms"
                            )

                            Divider().padding(.leading, 44)

                            SettingsLinkRow(
                                icon: "envelope",
                                title: "Contact Support",
                                url: "mailto:support@winespectator.com"
                            )
                        }

                        // About Section
                        AboutSection()

                        Spacer(minLength: 40)
                    }
                    .padding()
                }
            }
            .navigationBarHidden(true)
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
}

// MARK: - Settings Header

struct SettingsHeader: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Settings")
                    .font(.system(size: 28, weight: .bold))
                Text("Manage your account")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Wine Lens badge
            Text("WINE LENS")
                .font(.system(size: 10, weight: .bold))
                .tracking(1)
                .foregroundColor(Theme.secondaryColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(Theme.secondaryColor.opacity(0.15))
                )
        }
        .padding(.bottom, 8)
    }
}

// MARK: - Subscription Card

struct SubscriptionCard: View {
    @ObservedObject var subscriptionService: SubscriptionService
    let onUpgrade: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: subscriptionIcon)
                            .font(.system(size: 18))
                            .foregroundColor(subscriptionColor)

                        Text(subscriptionStatusTitle)
                            .font(.headline)
                    }

                    Text(subscriptionStatusSubtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if !subscriptionService.subscriptionStatus.isActive {
                    Button(action: onUpgrade) {
                        Text("Upgrade")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                LinearGradient(
                                    colors: [Theme.primaryColor, Theme.primaryColor.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(20)
                    }
                } else {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 28))
                        .foregroundColor(Theme.secondaryColor)
                }
            }

            if !subscriptionService.subscriptionStatus.isActive {
                // Free scans progress
                VStack(spacing: 8) {
                    HStack {
                        Text("Free scans this month")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(subscriptionService.remainingFreeScans()) of \(AppConfiguration.freeScansPerMonth)")
                            .font(.caption)
                            .fontWeight(.medium)
                    }

                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(.systemGray5))
                                .frame(height: 8)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [Theme.primaryColor, Theme.secondaryColor],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * progressValue, height: 8)
                        }
                    }
                    .frame(height: 8)
                }

                Button("Restore Purchases") {
                    Task {
                        try? await subscriptionService.restorePurchases()
                    }
                }
                .font(.caption)
                .foregroundColor(Theme.primaryColor)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
    }

    private var progressValue: CGFloat {
        let remaining = CGFloat(subscriptionService.remainingFreeScans())
        let total = CGFloat(AppConfiguration.freeScansPerMonth)
        return remaining / total
    }

    private var subscriptionIcon: String {
        switch subscriptionService.subscriptionStatus {
        case .unknown: return "hourglass"
        case .notSubscribed: return "gift"
        case .subscribed: return "crown.fill"
        case .expired: return "exclamationmark.triangle"
        }
    }

    private var subscriptionColor: Color {
        switch subscriptionService.subscriptionStatus {
        case .unknown: return .secondary
        case .notSubscribed: return Theme.primaryColor
        case .subscribed: return Theme.secondaryColor
        case .expired: return .red
        }
    }

    private var subscriptionStatusTitle: String {
        switch subscriptionService.subscriptionStatus {
        case .unknown: return "Loading..."
        case .notSubscribed: return "Free Plan"
        case .subscribed: return "Premium"
        case .expired: return "Expired"
        }
    }

    private var subscriptionStatusSubtitle: String {
        switch subscriptionService.subscriptionStatus {
        case .unknown: return ""
        case .notSubscribed: return "Limited to \(AppConfiguration.freeScansPerMonth) scans/month"
        case .subscribed(let expiration, _):
            if let date = expiration {
                return "Renews \(date.formatted(date: .abbreviated, time: .omitted))"
            }
            return "Active"
        case .expired: return "Please renew your subscription"
        }
    }
}

// MARK: - Settings Section

struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(Theme.primaryColor)
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(.leading, 4)

            VStack(spacing: 0) {
                content
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
            )
        }
    }
}

// MARK: - Account Row

struct AccountRow: View {
    let user: User
    let onSignOut: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Theme.primaryColor.opacity(0.15))
                    .frame(width: 44, height: 44)

                Text(user.displayName.prefix(1).uppercased())
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Theme.primaryColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(user.displayName)
                    .font(.system(size: 16, weight: .medium))
                Text(user.email)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button("Sign Out") {
                onSignOut()
            }
            .font(.system(size: 14))
            .foregroundColor(.red)
        }
    }
}

// MARK: - Sign In Row

struct SignInRow: View {
    let onSignIn: () -> Void

    var body: some View {
        Button(action: onSignIn) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Theme.primaryColor.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 18))
                        .foregroundColor(Theme.primaryColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Sign In")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    Text("Sync your wines across devices")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Settings Row

struct SettingsRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Theme.primaryColor)
                .frame(width: 24)

            Text(title)
                .font(.system(size: 16))

            Spacer()

            Text(value)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Settings Link Row

struct SettingsLinkRow: View {
    let icon: String
    let title: String
    let url: String

    var body: some View {
        Link(destination: URL(string: url)!) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(Theme.primaryColor)
                    .frame(width: 24)

                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - About Section

struct AboutSection: View {
    var body: some View {
        VStack(spacing: 16) {
            // Logo
            HStack(spacing: 8) {
                Image(systemName: "wineglass.fill")
                    .font(.system(size: 32))
                    .foregroundColor(Theme.primaryColor)

                VStack(alignment: .leading, spacing: 0) {
                    Text("Wine Spectator")
                        .font(.system(size: 18, weight: .bold, design: .serif))
                    Text("WINE LENS")
                        .font(.system(size: 12, weight: .semibold))
                        .tracking(2)
                        .foregroundColor(Theme.secondaryColor)
                }
            }

            Text("Powered by Wine Spectator's database of 450,000+ expert wine reviews.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // Wine Spectator badge
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.system(size: 10))
                Text("Trusted by wine enthusiasts since 1976")
                    .font(.caption2)
            }
            .foregroundColor(Theme.secondaryColor)
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [Theme.primaryColor.opacity(0.05), Theme.secondaryColor.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }
}

// MARK: - Sign In View

struct SignInView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        // Logo
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Theme.primaryColor.opacity(0.1))
                                    .frame(width: 100, height: 100)

                                Image(systemName: "wineglass.fill")
                                    .font(.system(size: 44))
                                    .foregroundColor(Theme.primaryColor)
                            }

                            VStack(spacing: 4) {
                                Text("Wine Spectator")
                                    .font(.system(size: 22, weight: .bold, design: .serif))
                                Text("WINE LENS")
                                    .font(.system(size: 12, weight: .semibold))
                                    .tracking(3)
                                    .foregroundColor(Theme.secondaryColor)
                            }
                        }
                        .padding(.top, 20)

                        // Sign in with Apple
                        SignInWithAppleButton()
                            .frame(height: 50)
                            .padding(.horizontal)

                        // Divider
                        HStack {
                            Rectangle()
                                .fill(Color(.separator))
                                .frame(height: 1)
                            Text("or")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Rectangle()
                                .fill(Color(.separator))
                                .frame(height: 1)
                        }
                        .padding(.horizontal)

                        // Email/Password
                        VStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                TextField("your@email.com", text: $email)
                                    .textFieldStyle(.plain)
                                    .textContentType(.emailAddress)
                                    .autocapitalization(.none)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color(.systemBackground))
                                    )
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                SecureField("••••••••", text: $password)
                                    .textFieldStyle(.plain)
                                    .textContentType(.password)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color(.systemBackground))
                                    )
                            }

                            Button(action: signIn) {
                                HStack {
                                    if isLoading {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Text("Sign In")
                                            .fontWeight(.semibold)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(
                                            (email.isEmpty || password.isEmpty) ?
                                            Color(.systemGray4) :
                                            Theme.primaryColor
                                        )
                                )
                                .foregroundColor(.white)
                            }
                            .disabled(email.isEmpty || password.isEmpty || isLoading)
                        }
                        .padding(.horizontal)

                        Spacer(minLength: 40)
                    }
                }
            }
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
            HStack(spacing: 8) {
                Image(systemName: "apple.logo")
                    .font(.system(size: 18))
                Text("Sign in with Apple")
                    .font(.system(size: 17, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.black)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(SubscriptionService.shared)
        .environmentObject(AppState())
}
