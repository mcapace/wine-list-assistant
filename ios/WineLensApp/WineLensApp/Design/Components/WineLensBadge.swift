import SwiftUI

/// Reusable Wine Lens branding badge using actual logo image assets
struct WineLensBadge: View {
    enum Style {
        case light      // For dark backgrounds (scanner view)
        case dark       // For light backgrounds (settings, my wines)
        case onboarding // Larger version for onboarding
    }

    let style: Style

    init(style: Style = .dark) {
        self.style = style
    }

    var body: some View {
        Group {
            switch style {
            case .light:
                lightStyleBadge
            case .dark:
                darkStyleBadge
            case .onboarding:
                onboardingStyleBadge
            }
        }
    }

    // MARK: - Light Style (for dark backgrounds like scanner) - MASSIVE PREMIUM SIZE

    private var lightStyleBadge: some View {
        HStack(spacing: 12) {
            // WineLens logo image - MASSIVE for maximum impact
            if let _ = UIImage(named: "WineLensText") {
                Image("WineLensText")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 56) // Increased to 56pt - truly prominent
            } else {
                // Fallback to text if image not available
                HStack(spacing: 8) {
                    Image(systemName: "wineglass.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(Theme.secondaryColor)

                    Text("WINE")
                        .font(.system(size: 28, weight: .bold, design: .default))
                        .foregroundColor(.white)
                    +
                    Text("LENS")
                        .font(.system(size: 28, weight: .bold, design: .default))
                        .foregroundColor(Theme.secondaryColor)
                }
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 16)
        .background(
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.9),
                            Color.black.opacity(0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    Capsule()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Theme.secondaryColor.opacity(0.7),
                                    Theme.secondaryColor.opacity(0.4)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
        )
        .shadow(color: .black.opacity(0.6), radius: 16, x: 0, y: 8)
        .shadow(color: Theme.secondaryColor.opacity(0.3), radius: 12, x: 0, y: 6)
    }

    // MARK: - Dark Style (for light backgrounds)

    private var darkStyleBadge: some View {
        HStack(spacing: 4) {
            // WineLens logo image
            if let _ = UIImage(named: "WineLensText") {
                Image("WineLensText")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 18)
            } else {
                // Fallback to text if image not available
                HStack(spacing: 4) {
                    Image(systemName: "wineglass.fill")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Theme.secondaryColor)

                    Text("WINE")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Theme.primaryColor)
                    +
                    Text("LENS")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Theme.secondaryColor)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Theme.secondaryColor.opacity(0.12))
        )
    }

    // MARK: - Onboarding Style (MASSIVE with animations)

    private var onboardingStyleBadge: some View {
        OnboardingLogoView()
    }
}

// MARK: - Animated Onboarding Logo View

struct OnboardingLogoView: View {
    @State private var wineSpectatorScale: CGFloat = 0.5
    @State private var wineSpectatorOpacity: Double = 0
    @State private var wineLensScale: CGFloat = 0.5
    @State private var wineLensOpacity: Double = 0
    @State private var glowIntensity: Double = 0.3
    @State private var isGlowing = false
    
    var body: some View {
        VStack(spacing: 40) {
            // Wine Spectator logo - MASSIVE with entrance animation
            ZStack {
                // Glow effect
                if let _ = UIImage(named: "WSLogoBlack") {
                    Image("WSLogoBlack")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 120)
                        .blur(radius: 15)
                        .opacity(glowIntensity)
                        .scaleEffect(isGlowing ? 1.05 : 1.0)
                }
                
                // Main logo
                if let _ = UIImage(named: "WSLogoBlack") {
                    Image("WSLogoBlack")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 120) // Increased from 60 to 120 - MASSIVE
                        .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 6)
                        .shadow(color: Theme.secondaryColor.opacity(0.1), radius: 8, x: 0, y: 4)
                } else {
                    // Fallback to text if image not available
                    Text("Wine Spectator")
                        .font(.system(size: 64, weight: .bold, design: .serif))
                        .foregroundColor(.primary)
                }
            }
            .scaleEffect(wineSpectatorScale)
            .opacity(wineSpectatorOpacity)
            .onAppear {
                // Entrance animation for Wine Spectator logo
                withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                    wineSpectatorScale = 1.0
                    wineSpectatorOpacity = 1.0
                }
                
                // Continuous glow animation
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    isGlowing = true
                    glowIntensity = 0.6
                }
            }

            // Wine Lens logo - MASSIVE with entrance animation
            ZStack {
                // Glow effect
                if let _ = UIImage(named: "WineLensText") {
                    Image("WineLensText")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 140)
                        .blur(radius: 20)
                        .opacity(glowIntensity * 0.8)
                        .scaleEffect(isGlowing ? 1.05 : 1.0)
                }
                
                // Main logo
                if let _ = UIImage(named: "WineLensText") {
                    Image("WineLensText")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 140) // Increased from 80 to 140 - MASSIVE
                        .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 6)
                        .shadow(color: Theme.secondaryColor.opacity(0.2), radius: 10, x: 0, y: 5)
                } else {
                    // Fallback to text if image not available
                    HStack(spacing: 16) {
                        Image(systemName: "wineglass.fill")
                            .font(.system(size: 48, weight: .medium))
                            .foregroundColor(Theme.secondaryColor)

                        Text("WINE")
                            .font(.system(size: 52, weight: .bold))
                            .foregroundColor(.primary)
                        +
                        Text("LENS")
                            .font(.system(size: 52, weight: .bold))
                            .foregroundColor(Theme.secondaryColor)
                    }
                }
            }
            .scaleEffect(wineLensScale)
            .opacity(wineLensOpacity)
            .onAppear {
                // Delayed entrance animation for Wine Lens logo
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                        wineLensScale = 1.0
                        wineLensOpacity = 1.0
                    }
                }
            }
        }
        .padding(.vertical, 40)
    }
}

/// Wine Spectator logo component using actual image assets
struct WineSpectatorLogo: View {
    enum Variant {
        case black
        case white
    }

    let variant: Variant
    let height: CGFloat

    init(variant: Variant = .black, height: CGFloat = 24) {
        self.variant = variant
        self.height = height
    }

    var body: some View {
        Group {
            if variant == .black {
                if let _ = UIImage(named: "WSLogoBlack") {
                    Image("WSLogoBlack")
                        .resizable()
                        .scaledToFit()
                        .frame(height: height)
                } else {
                    // Fallback to text if image not available
                    HStack(spacing: 4) {
                        Image(systemName: "wineglass")
                            .font(.system(size: height * 0.6, weight: .light))
                            .foregroundColor(Theme.primaryColor)

                        Text("Wine Spectator")
                            .font(.system(size: height * 0.7, weight: .bold, design: .serif))
                            .foregroundColor(Theme.primaryColor)
                    }
                }
            } else {
                if let _ = UIImage(named: "WSLogoWhite") {
                    Image("WSLogoWhite")
                        .resizable()
                        .scaledToFit()
                        .frame(height: height)
                } else {
                    // Fallback to text if image not available
                    HStack(spacing: 4) {
                        Image(systemName: "wineglass")
                            .font(.system(size: height * 0.6, weight: .light))
                            .foregroundColor(.white)

                        Text("Wine Spectator")
                            .font(.system(size: height * 0.7, weight: .bold, design: .serif))
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        // Light style on dark background
        ZStack {
            Color.black
            WineLensBadge(style: .light)
        }
        .frame(height: 60)

        // Dark style on light background
        WineLensBadge(style: .dark)

        // Onboarding style
        WineLensBadge(style: .onboarding)

        // Wine Spectator logos
        HStack(spacing: 20) {
            WineSpectatorLogo(variant: .black, height: 30)
            ZStack {
                Color.black
                WineSpectatorLogo(variant: .white, height: 30)
            }
            .frame(width: 150, height: 50)
        }
    }
    .padding()
}

