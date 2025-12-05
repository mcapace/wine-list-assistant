import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentPage = 0

    let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Scan Any Wine List",
            subtitle: "Point your camera at a restaurant wine list and see Wine Spectator scores instantly.",
            imageName: "camera.viewfinder",
            color: Theme.primary
        ),
        OnboardingPage(
            title: "Expert Scores, Not Crowds",
            subtitle: "Unlike other apps, our scores come from professional blind tastings by experienced critics.",
            imageName: "star.fill",
            color: .yellow
        ),
        OnboardingPage(
            title: "Find the Best Value",
            subtitle: "Filter by score, drink window, and value to find the perfect bottle for your budget.",
            imageName: "tag.fill",
            color: .green
        ),
        OnboardingPage(
            title: "Save Your Favorites",
            subtitle: "Build your personal wine list and never forget a great bottle.",
            imageName: "heart.fill",
            color: .red
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
}

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(page.color.opacity(0.15))
                    .frame(width: 160, height: 160)

                Image(systemName: page.imageName)
                    .font(.system(size: 70))
                    .foregroundColor(page.color)
            }

            // Text
            VStack(spacing: Theme.Spacing.md) {
                Text(page.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

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
