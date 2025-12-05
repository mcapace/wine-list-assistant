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
                        HapticService.shared.buttonTap()
                        withAnimation {
                            currentPage += 1
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Button("Skip") {
                        HapticService.shared.buttonTap()
                        appState.completeOnboarding()
                    }
                    .foregroundColor(.secondary)
                } else {
                    Button("Get Started") {
                        HapticService.shared.success()
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
                // Logo page - show WineLens Logo image with fallback
                VStack(spacing: Theme.Spacing.xl) {
                    // WineLens Logo image with fallback
                    Group {
                        if UIImage(named: "WineLensLogo") != nil {
                            Image("WineLensLogo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: 300, maxHeight: 300)
                        } else if UIImage(named: "WineLensText") != nil {
                            // Fallback to WineLensText if logo not found
                            Image("WineLensText")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: 280, maxHeight: 120)
                        } else {
                            // Final fallback if no images found
                            VStack(spacing: 8) {
                                Image(systemName: "wineglass.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(Theme.primaryColor)
                                Text("WINE LENS")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundColor(Theme.secondaryColor)
                                    .tracking(4)
                            }
                            .frame(maxWidth: 280, maxHeight: 120)
                        }
                    }
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                    
                    // Wine Spectator branding
                    Text("Wine Spectator")
                        .font(.system(size: 24, weight: .bold, design: .serif))
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, Theme.Spacing.xl)
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
