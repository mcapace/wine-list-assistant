import SwiftUI

enum Theme {
    // MARK: - Colors

    static let primaryColor = Color("PrimaryColor", bundle: nil)
    static let secondaryColor = Color("SecondaryColor", bundle: nil)
    static let accentColor = Color("AccentColor", bundle: nil)

    // Fallback colors if assets not available
    static let primary = Color(red: 0.5, green: 0.1, blue: 0.15)  // Wine red
    static let secondary = Color(red: 0.85, green: 0.75, blue: 0.55)  // Gold
    static let accent = Color(red: 0.2, green: 0.5, blue: 0.3)  // Green for "good"

    // MARK: - Score Colors

    static func scoreColor(for score: Int) -> Color {
        switch score {
        case 95...100:
            return .purple
        case 90...94:
            return .green
        case 85...89:
            return .yellow
        case 80...84:
            return .orange
        default:
            return .red
        }
    }

    static func scoreBackgroundColor(for score: Int) -> Color {
        scoreColor(for: score).opacity(0.15)
    }

    // MARK: - Drink Window Colors

    static func drinkWindowColor(for status: DrinkWindowStatus) -> Color {
        switch status {
        case .tooYoung:
            return .blue
        case .ready:
            return .green
        case .peaking:
            return .purple
        case .pastPrime:
            return .orange
        }
    }

    // MARK: - Typography

    enum Typography {
        static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
        static let title = Font.system(size: 28, weight: .bold, design: .rounded)
        static let title2 = Font.system(size: 22, weight: .semibold, design: .rounded)
        static let title3 = Font.system(size: 20, weight: .semibold, design: .default)
        static let headline = Font.system(size: 17, weight: .semibold, design: .default)
        static let body = Font.system(size: 17, weight: .regular, design: .default)
        static let callout = Font.system(size: 16, weight: .regular, design: .default)
        static let subheadline = Font.system(size: 15, weight: .regular, design: .default)
        static let footnote = Font.system(size: 13, weight: .regular, design: .default)
        static let caption = Font.system(size: 12, weight: .regular, design: .default)
        static let caption2 = Font.system(size: 11, weight: .regular, design: .default)

        // Score badge font
        static let scoreBadge = Font.system(size: 16, weight: .bold, design: .rounded)
        static let scoreDetail = Font.system(size: 48, weight: .bold, design: .rounded)
    }

    // MARK: - Spacing

    enum Spacing {
        static let xxs: CGFloat = 2
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    // MARK: - Corner Radius

    enum CornerRadius {
        static let small: CGFloat = 4
        static let medium: CGFloat = 8
        static let large: CGFloat = 12
        static let xl: CGFloat = 16
        static let pill: CGFloat = 999
    }

    // MARK: - Shadows

    static let cardShadow = ShadowStyle(
        color: .black.opacity(0.1),
        radius: 8,
        x: 0,
        y: 4
    )

    static let badgeShadow = ShadowStyle(
        color: .black.opacity(0.25),
        radius: 4,
        x: 0,
        y: 2
    )

    struct ShadowStyle {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }
}

// MARK: - View Extensions

extension View {
    func cardStyle() -> some View {
        self
            .background(Color(.systemBackground))
            .cornerRadius(Theme.CornerRadius.large)
            .shadow(
                color: Theme.cardShadow.color,
                radius: Theme.cardShadow.radius,
                x: Theme.cardShadow.x,
                y: Theme.cardShadow.y
            )
    }

    func badgeShadow() -> some View {
        self.shadow(
            color: Theme.badgeShadow.color,
            radius: Theme.badgeShadow.radius,
            x: Theme.badgeShadow.x,
            y: Theme.badgeShadow.y
        )
    }
}
