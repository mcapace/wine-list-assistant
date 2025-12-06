import SwiftUI

/// Reusable Wine Lens branding badge with styled text logo
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
        HStack(spacing: 6) {
            // Wine glass icon
            Image(systemName: "wineglass.fill")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Theme.secondaryColor)

            // Styled text logo
            Text("WINE")
                .font(.system(size: 13, weight: .bold, design: .default))
                .foregroundColor(.white)
            +
            Text("LENS")
                .font(.system(size: 13, weight: .bold, design: .default))
                .foregroundColor(Theme.secondaryColor)
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
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Theme.secondaryColor.opacity(0.12))
        )
    }

    // MARK: - Onboarding Style (larger)

    private var onboardingStyleBadge: some View {
        VStack(spacing: 8) {
            // Wine Spectator branding
            Text("Wine Spectator")
                .font(.system(size: 28, weight: .bold, design: .serif))
                .foregroundColor(.primary)

            // Wine Lens with icon
            HStack(spacing: 8) {
                Image(systemName: "wineglass.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Theme.secondaryColor)

                Text("WINE")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                +
                Text("LENS")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Theme.secondaryColor)
            }
        }
    }
}

/// Wine Spectator logo component - styled text version
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
        HStack(spacing: 4) {
            // Decorative wine glass icon
            Image(systemName: "wineglass")
                .font(.system(size: height * 0.6, weight: .light))
                .foregroundColor(variant == .black ? Theme.primaryColor : .white)

            Text("Wine Spectator")
                .font(.system(size: height * 0.7, weight: .bold, design: .serif))
                .foregroundColor(variant == .black ? Theme.primaryColor : .white)
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
