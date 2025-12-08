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
            color: Theme.primaryColor,
            isLogo: false
        ),
        OnboardingPage(
            title: "Expert Scores, Not Crowds",
            subtitle: "Unlike other apps, our scores come from professional blind tastings by experienced critics.",
            imageName: "star.circle.fill",
            color: Theme.secondaryColor,
            isLogo: false
        ),
        OnboardingPage(
            title: "Find the Best Value",
            subtitle: "Filter by score, drink window, and value to find the perfect bottle for your budget.",
            imageName: "tag.circle.fill",
            color: .green,
            isLogo: false
        ),
        OnboardingPage(
            title: "Save Your Favorites",
            subtitle: "Build your personal wine list and never forget a great bottle.",
            imageName: "heart.circle.fill",
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
                        .id(index) // Force view recreation on page change
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
            } else {
                // Elegant icon page - Vivino-inspired clean design
                ElegantIconView(
                    iconName: page.imageName,
                    color: page.color,
                    showContent: showContent
                )
            }

            // Text - elegant typography with smooth animations (only for non-logo pages)
            if !page.isLogo {
                VStack(spacing: Theme.Spacing.md) {
                    Text(page.title)
                        .font(.system(size: 34, weight: .bold, design: .default))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .opacity(showContent ? 1.0 : 0.0)
                        .offset(y: showContent ? 0 : 15)
                        .animation(.easeOut(duration: 0.6).delay(0.3), value: showContent)

                    Text(page.subtitle)
                        .font(.system(size: 18, weight: .regular, design: .default))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                        .padding(.horizontal, Theme.Spacing.xl)
                        .opacity(showContent ? 1.0 : 0.0)
                        .offset(y: showContent ? 0 : 15)
                        .animation(.easeOut(duration: 0.6).delay(0.5), value: showContent)
                }
                .padding(.top, Theme.Spacing.xl)
            }

            Spacer()
            Spacer()
        }
        .onAppear {
            // Always set showContent to true when the page appears
            // This ensures both logo and non-logo pages animate in
            withAnimation {
                showContent = true
            }
        }
        .onDisappear {
            // Reset when page disappears so it animates in again if user swipes back
            showContent = false
        }
    }
}

// MARK: - Elegant Icon View (Vivino-inspired)

struct ElegantIconView: View {
    let iconName: String
    let color: Color
    let showContent: Bool
    
    @State private var iconScale: CGFloat = 0.7
    @State private var glowPulse: Double = 0.3
    
    var body: some View {
        ZStack {
            // Subtle outer glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            color.opacity(0.15),
                            color.opacity(0.05),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 50,
                        endRadius: 100
                    )
                )
                .frame(width: 180, height: 180)
                .blur(radius: 15)
                .opacity(glowPulse)
            
            // Elegant container with subtle border
            RoundedRectangle(cornerRadius: 32)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(.systemBackground),
                            Color(.systemBackground).opacity(0.95)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 140, height: 140)
                .overlay(
                    RoundedRectangle(cornerRadius: 32)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    color.opacity(0.3),
                                    color.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: color.opacity(0.15), radius: 20, x: 0, y: 8)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)

            // Icon with elegant styling
            Image(systemName: iconName)
                .font(.system(size: 60, weight: .light))
                .foregroundStyle(
                    LinearGradient(
                        colors: [color, color.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: color.opacity(0.2), radius: 4, x: 0, y: 2)
        }
        .scaleEffect(iconScale)
        .opacity(showContent ? 1.0 : 0.0)
        .onAppear {
            // Smooth entrance animation
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.2)) {
                iconScale = 1.0
            }
            
            // Subtle pulse animation
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                glowPulse = 0.6
            }
        }
        .onChange(of: showContent) { newValue in
            if newValue {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
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
