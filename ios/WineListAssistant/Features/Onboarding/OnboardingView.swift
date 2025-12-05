import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentPage = 0

    let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Wine Spectator\nWine Lens",
            subtitle: "The smartest way to navigate any wine list. Powered by 40+ years of expert reviews.",
            imageName: "winelens.logo",
            color: Theme.primaryColor,
            isLogo: true
        ),
        OnboardingPage(
            title: "Scan Any Wine List",
            subtitle: "Point your camera at a restaurant wine list and see Wine Spectator scores instantly.",
            imageName: "camera.viewfinder",
            color: Theme.primary,
            isLogo: false
        ),
        OnboardingPage(
            title: "Expert Scores, Not Crowds",
            subtitle: "Unlike other apps, our scores come from professional blind tastings by experienced critics.",
            imageName: "star.fill",
            color: .yellow,
            isLogo: false
        ),
        OnboardingPage(
            title: "Find the Best Value",
            subtitle: "Filter by score, drink window, and value to find the perfect bottle for your budget.",
            imageName: "tag.fill",
            color: .green,
            isLogo: false
        ),
        OnboardingPage(
            title: "Save Your Favorites",
            subtitle: "Build your personal wine list and never forget a great bottle.",
            imageName: "heart.fill",
            color: .red,
            isLogo: false
        )
    ]

    var body: some View {
        VStack {
            // Page content
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    OnboardingPageView(page: pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            // Bottom buttons
            VStack(spacing: Theme.Spacing.md) {
                if currentPage < pages.count - 1 {
                    Button("Next") {
                        withAnimation {
                            currentPage += 1
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Button("Skip") {
                        appState.completeOnboarding()
                    }
                    .foregroundColor(.secondary)
                } else {
                    Button("Get Started") {
                        appState.completeOnboarding()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
            .padding(.horizontal, Theme.Spacing.xl)
            .padding(.bottom, Theme.Spacing.xl)
        }
    }
}

struct OnboardingPage {
    let title: String
    let subtitle: String
    let imageName: String
    let color: Color
    let isLogo: Bool
}

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()

            if page.isLogo {
                // Logo page - show app icon/logo
                VStack(spacing: Theme.Spacing.lg) {
                    // App logo placeholder - will use actual image from assets
                    ZStack {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Theme.cardBackground)
                            .frame(width: 140, height: 140)

                        // Wine bottle + lens icon representation
                        HStack(spacing: 4) {
                            Image(systemName: "wineglass.fill")
                                .font(.system(size: 50))
                                .foregroundColor(Theme.primaryColor)

                            Image(systemName: "camera.aperture")
                                .font(.system(size: 40))
                                .foregroundColor(Theme.secondaryColor)
                        }
                    }
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)

                    // Wine Spectator text logo
                    VStack(spacing: 4) {
                        Text("Wine Spectator")
                            .font(.system(size: 28, weight: .bold, design: .serif))
                            .foregroundColor(.primary)
                        Text("WINE LENS")
                            .font(.system(size: 18, weight: .semibold, design: .default))
                            .tracking(4)
                            .foregroundColor(Theme.secondaryColor)
                    }
                }
            } else {
                // Standard icon page
                ZStack {
                    Circle()
                        .fill(page.color.opacity(0.15))
                        .frame(width: 160, height: 160)

                    Image(systemName: page.imageName)
                        .font(.system(size: 70))
                        .foregroundColor(page.color)
                }
            }

            // Text
            VStack(spacing: Theme.Spacing.md) {
                if !page.isLogo {
                    Text(page.title)
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                }

                Text(page.subtitle)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.xl)
            }

            Spacer()
            Spacer()
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppState())
}
