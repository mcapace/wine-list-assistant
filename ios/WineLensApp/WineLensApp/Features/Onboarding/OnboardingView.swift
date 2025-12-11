import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentPage = 0

    let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Wine Spectator\nWine Lens",
            subtitle: "The smartest way to navigate any wine list. Powered by 40+ years of expert reviews.",
            imageName: "winelens.logo",
            animationName: "Wine_Spectator_Wine_Lens",
            color: Theme.primaryColor,
            isLogo: true
        ),
        OnboardingPage(
            title: "Scan Any Wine List",
            subtitle: "Point your camera at a restaurant wine list and see Wine Spectator scores instantly.",
            imageName: "camera.viewfinder",
            animationName: "Scan_Any_Wine_List",
            color: Theme.primaryColor,
            isLogo: false
        ),
        OnboardingPage(
            title: "Expert Scores, Not Crowds",
            subtitle: "Unlike other apps, our scores come from professional blind tastings by experienced critics.",
            imageName: "star.circle.fill",
            animationName: "Expert_Scores_Not_Crowd",
            color: Theme.secondaryColor,
            isLogo: false
        ),
        OnboardingPage(
            title: "Find the Best Value",
            subtitle: "Filter by score, drink window, and value to find the perfect bottle for your budget.",
            imageName: "tag.circle.fill",
            animationName: "Find_The_Best_Value",
            color: .green,
            isLogo: false
        ),
        OnboardingPage(
            title: "Save Your Favorites",
            subtitle: "Build your personal wine list and never forget a great bottle.",
            imageName: "heart.circle.fill",
            animationName: "Save_Your_Favorites",
            color: Theme.primaryColor,
            isLogo: false
        )
    ]

    var body: some View {
        VStack {
            // Page content - use drawingGroup for better performance
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    OnboardingPageView(page: pages[index])
                        .tag(index)
                        .id(index) // Force view recreation on page change
                        // Note: Don't use .drawingGroup() here - it breaks UIViewRepresentable (LottieView)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .animation(.easeInOut(duration: 0.3), value: currentPage)

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
    let animationName: String? // Lottie animation name (without .json extension)
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
                // Logo page - use Lottie animation if available, otherwise use WineLensBadge
                VStack(spacing: 0) {
                    if let animationName = page.animationName {
                        OnboardingLottieView(
                            animationName: animationName,
                            showContent: showContent
                        )
                        .padding(.bottom, 20)
                    } else {
                        WineLensBadge(style: .onboarding)
                            .opacity(showContent ? 1.0 : 0.0)
                            .scaleEffect(showContent ? 1.0 : 0.9)
                            .animation(.easeOut(duration: 0.4).delay(0.1), value: showContent)
                            .drawingGroup() // Optimize rendering
                    }
                    
                    // Subtitle with simplified fade-in animation
                    Text(page.subtitle)
                        .font(.system(size: 18, weight: .medium, design: .default))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                        .padding(.horizontal, Theme.Spacing.xl)
                        .padding(.top, 40)
                        .opacity(showContent ? 1.0 : 0.0)
                        .offset(y: showContent ? 0 : 10)
                        .animation(.easeOut(duration: 0.4).delay(0.3), value: showContent)
                }
            } else {
                // Use Lottie animation if available, otherwise fall back to SF Symbol
                if let animationName = page.animationName {
                    OnboardingLottieView(
                        animationName: animationName,
                        showContent: showContent
                    )
                } else {
                    ElegantIconView(
                        iconName: page.imageName,
                        color: page.color,
                        showContent: showContent
                    )
                }
            }

            // Text - simplified animations for better performance
            if !page.isLogo {
                VStack(spacing: Theme.Spacing.md) {
                    Text(page.title)
                        .font(.system(size: 34, weight: .bold, design: .default))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .opacity(showContent ? 1.0 : 0.0)
                        .offset(y: showContent ? 0 : 10)
                        .animation(.easeOut(duration: 0.4).delay(0.2), value: showContent)

                    Text(page.subtitle)
                        .font(.system(size: 18, weight: .regular, design: .default))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                        .padding(.horizontal, Theme.Spacing.xl)
                        .opacity(showContent ? 1.0 : 0.0)
                        .offset(y: showContent ? 0 : 10)
                        .animation(.easeOut(duration: 0.4).delay(0.3), value: showContent)
                }
                .padding(.top, Theme.Spacing.xl)
            }

            Spacer()
            Spacer()
        }
        .onAppear {
            // Simplified animation trigger - avoid nested animations
            showContent = true
        }
        .onDisappear {
            // Reset when page disappears so it animates in again if user swipes back
            showContent = false
        }
    }
}

// MARK: - Onboarding Lottie Animation View

struct OnboardingLottieView: View {
    let animationName: String
    let showContent: Bool
    
    @State private var animationScale: CGFloat = 0.8
    
    var body: some View {
        LottieView(
            animationName: animationName,
            loopMode: .loop,
            animationSpeed: 1.0
        )
        .frame(width: 280, height: 280)
        .scaleEffect(animationScale)
        .opacity(showContent ? 1.0 : 0.0)
        .onAppear {
            if showContent {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                    animationScale = 1.0
                }
            }
        }
        .onChange(of: showContent) { newValue in
            if newValue {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    animationScale = 1.0
                }
            }
        }
    }
}

// MARK: - Elegant Icon View (Vivino-inspired)

struct ElegantIconView: View {
    let iconName: String
    let color: Color
    let showContent: Bool
    
    @State private var iconScale: CGFloat = 0.7
    
    var body: some View {
        ZStack {
            // Simplified container - remove heavy gradients for better performance
            RoundedRectangle(cornerRadius: 32)
                .fill(Color(.systemBackground))
                .frame(width: 140, height: 140)
                .overlay(
                    RoundedRectangle(cornerRadius: 32)
                        .stroke(color.opacity(0.2), lineWidth: 1.5)
                )
                .shadow(color: color.opacity(0.1), radius: 12, x: 0, y: 4)

            // Icon - simplified styling
            Image(systemName: iconName)
                .font(.system(size: 60, weight: .medium))
                .foregroundColor(color)
        }
        .scaleEffect(iconScale)
        .opacity(showContent ? 1.0 : 0.0)
        .onAppear {
            // Simplified entrance animation - no infinite loops
            if showContent {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1)) {
                    iconScale = 1.0
                }
            }
        }
        .onChange(of: showContent) { newValue in
            if newValue {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    iconScale = 1.0
                }
            }
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppState())
}
