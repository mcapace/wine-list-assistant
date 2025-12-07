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
            imageName: "camera.aperture",
            color: Theme.primaryColor,
            isLogo: false
        ),
        OnboardingPage(
            title: "Expert Scores, Not Crowds",
            subtitle: "Unlike other apps, our scores come from professional blind tastings by experienced critics.",
            imageName: "sparkles",
            color: Theme.secondaryColor,
            isLogo: false
        ),
        OnboardingPage(
            title: "Find the Best Value",
            subtitle: "Filter by score, drink window, and value to find the perfect bottle for your budget.",
            imageName: "chart.line.uptrend.xyaxis",
            color: .green,
            isLogo: false
        ),
        OnboardingPage(
            title: "Save Your Favorites",
            subtitle: "Build your personal wine list and never forget a great bottle.",
            imageName: "bookmark.fill",
            color: Theme.primaryColor,
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
                    Button(action: {
                        withAnimation {
                            currentPage += 1
                        }
                    }) {
                        Text("Next")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Theme.primaryColor)
                            .cornerRadius(12)
                    }

                    Button(action: {
                        appState.completeOnboarding()
                    }) {
                        Text("Skip")
                            .foregroundColor(.secondary)
                    }
                } else {
                    Button(action: {
                        appState.completeOnboarding()
                    }) {
                        Text("Get Started")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Theme.primaryColor)
                            .cornerRadius(12)
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.xl)
            .padding(.bottom, Theme.Spacing.xl + 20)
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
    @State private var showContent = false

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()

            if page.isLogo {
                // Logo page - use WineLensBadge component with actual logos and enhanced animations
                VStack(spacing: 0) {
                    WineLensBadge(style: .onboarding)
                        .opacity(showContent ? 1.0 : 0.0)
                        .scaleEffect(showContent ? 1.0 : 0.8)
                        .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2), value: showContent)
                    
                    // Subtitle with fade-in animation
                    Text(page.subtitle)
                        .font(.system(size: 18, weight: .medium, design: .default))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                        .padding(.horizontal, Theme.Spacing.xl)
                        .padding(.top, 40)
                        .opacity(showContent ? 1.0 : 0.0)
                        .offset(y: showContent ? 0 : 20)
                        .animation(.easeOut(duration: 0.8).delay(0.6), value: showContent)
                }
                .onAppear {
                    showContent = true
                }
            } else {
                // Standard icon page - elevated design with gradients and shadows
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    page.color.opacity(0.25),
                                    page.color.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 200, height: 200)
                        .blur(radius: 20)
                    
                    // Main circle with gradient
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    page.color.opacity(0.2),
                                    page.color.opacity(0.08)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 180, height: 180)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            page.color.opacity(0.4),
                                            page.color.opacity(0.2)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                        .shadow(color: page.color.opacity(0.3), radius: 20, x: 0, y: 10)
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)

                    // Icon with enhanced styling
                    Image(systemName: page.imageName)
                        .font(.system(size: 80, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [page.color, page.color.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: page.color.opacity(0.3), radius: 8, x: 0, y: 4)
                }
            }

            // Text - elevated typography (only for non-logo pages)
            if !page.isLogo {
                VStack(spacing: Theme.Spacing.md) {
                    Text(page.title)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)

                    Text(page.subtitle)
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, Theme.Spacing.xl)
                }
                .padding(.top, Theme.Spacing.lg)
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
