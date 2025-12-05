import SwiftUI

struct ScoreBadge: View {
    let score: Int?
    let confidence: Double
    let vintage: Int?
    let size: BadgeSize

    enum BadgeSize {
        case small
        case medium
        case large

        var fontSize: CGFloat {
            switch self {
            case .small: return 12
            case .medium: return 16
            case .large: return 20
            }
        }

        var padding: EdgeInsets {
            switch self {
            case .small: return EdgeInsets(top: 2, leading: 6, bottom: 2, trailing: 6)
            case .medium: return EdgeInsets(top: 4, leading: 10, bottom: 4, trailing: 10)
            case .large: return EdgeInsets(top: 6, leading: 14, bottom: 6, trailing: 14)
            }
        }

        var cornerRadius: CGFloat {
            switch self {
            case .small: return 4
            case .medium: return 8
            case .large: return 10
            }
        }
    }

    init(score: Int?, confidence: Double = 1.0, vintage: Int? = nil, size: BadgeSize = .medium) {
        self.score = score
        self.confidence = confidence
        self.vintage = vintage
        self.size = size
    }

    private var scoreColor: Color {
        guard let score = score else { return .gray }
        return Theme.scoreColor(for: score)
    }

    private var displayText: String {
        guard let score = score else { return "?" }
        if let vintage = vintage {
            return "\(score) '\(vintage % 100)"
        }
        return "\(score)"
    }

    private var hasLowConfidence: Bool {
        confidence < 0.85
    }

    var body: some View {
        HStack(spacing: 2) {
            Text(displayText)
                .font(.system(size: size.fontSize, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            if hasLowConfidence {
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: size.fontSize * 0.6))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(size.padding)
        .background(
            RoundedRectangle(cornerRadius: size.cornerRadius)
                .fill(scoreColor)
        )
        .badgeShadow()
    }
}

// MARK: - Large Score Display (for detail view)

struct LargeScoreDisplay: View {
    let score: Int
    let reviewerInitials: String?

    private var scoreColor: Color {
        Theme.scoreColor(for: score)
    }

    private var category: ScoreCategory {
        ScoreCategory(score: score)
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.xs) {
            Text("\(score)")
                .font(Theme.Typography.scoreDetail)
                .foregroundColor(scoreColor)

            Text(category.displayName)
                .font(Theme.Typography.caption)
                .foregroundColor(.secondary)

            if let initials = reviewerInitials {
                Text("— \(initials)")
                    .font(Theme.Typography.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(Theme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.large)
                .fill(Theme.scoreBackgroundColor(for: score))
        )
    }
}

// MARK: - Previews

#Preview("Score Badges") {
    VStack(spacing: 20) {
        HStack(spacing: 16) {
            ScoreBadge(score: 97, size: .small)
            ScoreBadge(score: 92, size: .medium)
            ScoreBadge(score: 87, size: .large)
        }

        HStack(spacing: 16) {
            ScoreBadge(score: 82)
            ScoreBadge(score: 75)
            ScoreBadge(score: nil)
        }

        HStack(spacing: 16) {
            ScoreBadge(score: 95, vintage: 2019)
            ScoreBadge(score: 90, confidence: 0.75, vintage: 2018)
        }

        LargeScoreDisplay(score: 97, reviewerInitials: "JL")
    }
    .padding()
}
