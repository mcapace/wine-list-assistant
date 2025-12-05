import SwiftUI

/// Reusable Wine Lens branding badge that uses the logo image when available
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
        HStack(spacing: 4) {
            // Try to use image, fall back to text
            if let _ = UIImage(named: "WineLensText") {
                Image("WineLensText")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 14)
            } else {
                Text("WINE LENS")
                    .font(.system(size: 12, weight: .bold))
                    .tracking(2)
                    .foregroundColor(Theme.secondaryColor)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.5))
                .overlay(
                    Capsule()
                        .stroke(Theme.secondaryColor.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - Dark Style (for light backgrounds)

    private var darkStyleBadge: some View {
        HStack(spacing: 4) {
            if let _ = UIImage(named: "WineLensText") {
                Image("WineLensText")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 12)
            } else {
                Text("WINE LENS")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1)
                    .foregroundColor(Theme.secondaryColor)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(Theme.secondaryColor.opacity(0.15))
        )
    }

    // MARK: - Onboarding Style (larger)

    private var onboardingStyleBadge: some View {
        VStack(spacing: 4) {
            Text("Wine Spectator")
                .font(.system(size: 28, weight: .bold, design: .serif))
                .foregroundColor(.primary)

            if let _ = UIImage(named: "WineLensText") {
                Image("WineLensText")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 20)
            } else {
                Text("WINE LENS")
                    .font(.system(size: 18, weight: .semibold))
                    .tracking(4)
                    .foregroundColor(Theme.secondaryColor)
            }
        }
    }
}

/// Wine Spectator logo component
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
        let imageName = variant == .black ? "WS Logo Black" : "WS Logo White"

        if let _ = UIImage(named: imageName) {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(height: height)
        } else {
            // Fallback to text
            Text("Wine Spectator")
                .font(.system(size: height * 0.7, weight: .bold, design: .serif))
                .foregroundColor(variant == .black ? .black : .white)
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
