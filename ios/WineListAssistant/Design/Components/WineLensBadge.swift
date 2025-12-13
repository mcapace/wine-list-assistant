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

    // MARK: - Light Style (for dark backgrounds like scanner)

    private var lightStyleBadge: some View {
        HStack(spacing: 8) {
            // WineLens logo image
            Image("WineLensText")
                .resizable()
                .scaledToFit()
                .frame(height: 24)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.7))
                .overlay(
                    Capsule()
                        .stroke(Theme.secondaryColor.opacity(0.4), lineWidth: 1)
                )
        )
    }

    // MARK: - Dark Style (for light backgrounds)

    private var darkStyleBadge: some View {
        HStack(spacing: 4) {
            // WineLens logo image
            Image("WineLensText")
                .resizable()
                .scaledToFit()
                .frame(height: 18)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Theme.secondaryColor.opacity(0.12))
        )
    }

    // MARK: - Onboarding Style (larger)

    private var onboardingStyleBadge: some View {
        VStack(spacing: 16) {
            // Wine Spectator logo
            WineSpectatorLogo(variant: .black, height: 36)

            // WineLens logo image
            Image("WineLensText")
                .resizable()
                .scaledToFit()
                .frame(height: 40)
        }
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
        Image(variant == .black ? "WSLogoBlack" : "WSLogoWhite")
            .resizable()
            .scaledToFit()
            .frame(height: height)
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
