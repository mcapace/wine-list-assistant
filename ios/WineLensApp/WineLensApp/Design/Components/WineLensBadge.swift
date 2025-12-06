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
            if let _ = UIImage(named: "WineLensText") {
                Image("WineLensText")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 24)
            } else {
                // Fallback to text if image not available
                HStack(spacing: 4) {
                    Image(systemName: "wineglass.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.secondaryColor)

                    Text("WINE")
                        .font(.system(size: 13, weight: .bold, design: .default))
                        .foregroundColor(.white)
                    +
                    Text("LENS")
                        .font(.system(size: 13, weight: .bold, design: .default))
                        .foregroundColor(Theme.secondaryColor)
                }
            }
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

    // MARK: - Onboarding Style (larger)

    private var onboardingStyleBadge: some View {
        VStack(spacing: 24) {
            // Wine Spectator logo - much larger
            if let _ = UIImage(named: "WSLogoBlack") {
                Image("WSLogoBlack")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 60)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            } else {
                // Fallback to text if image not available
                Text("Wine Spectator")
                    .font(.system(size: 42, weight: .bold, design: .serif))
                    .foregroundColor(.primary)
            }

            // Wine Lens logo - much larger
            if let _ = UIImage(named: "WineLensText") {
                Image("WineLensText")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 80)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            } else {
                // Fallback to text if image not available
                HStack(spacing: 12) {
                    Image(systemName: "wineglass.fill")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(Theme.secondaryColor)

                    Text("WINE")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.primary)
                    +
                    Text("LENS")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(Theme.secondaryColor)
                }
            }
        }
        .padding(.vertical, 20)
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

