import SwiftUI
import UIKit

struct AROverlayView: View {
    let recognizedWines: [RecognizedWine]
    let viewSize: CGSize
    let onWineTapped: (RecognizedWine) -> Void

    var body: some View {
        ZStack {
            ForEach(recognizedWines) { wine in
                ScoreBadgeOverlay(
                    wine: wine,
                    position: convertToViewCoordinates(wine.boundingBox),
                    onTap: { onWineTapped(wine) }
                )
            }
        }
    }

    private func convertToViewCoordinates(_ normalizedBox: CGRect) -> CGPoint {
        // Vision coordinates: origin bottom-left, y increases upward
        // SwiftUI coordinates: origin top-left, y increases downward
        CGPoint(
            x: normalizedBox.midX * viewSize.width,
            y: (1 - normalizedBox.midY) * viewSize.height
        )
    }
}

struct ScoreBadgeOverlay: View {
    let wine: RecognizedWine
    let position: CGPoint
    let onTap: () -> Void

    @State private var isAppearing = false
    @State private var isPressed = false
    @State private var showScoreReveal = false
    @State private var floatOffset: CGFloat = 0

    var body: some View {
        ZStack {
            // Score reveal animation (for high scores)
            if showScoreReveal && (wine.matchedWine?.score ?? 0) >= 95 {
                ScoreRevealAnimation()
                    .opacity(0.8)
            }

            Group {
                if wine.isMatched {
                    ScoreBadge(
                        score: wine.matchedWine?.score,
                        confidence: wine.matchConfidence,
                        vintage: wine.matchedVintage
                    )
                } else {
                    // Unmatched indicator
                    UnmatchedBadge()
                }
            }
        }
        .position(
            x: position.x,
            y: position.y + floatOffset
        )
        .scaleEffect(isAppearing ? (isPressed ? 0.85 : 1.0) : 0.5)
        .opacity(isAppearing ? 1.0 : 0.0)
        .onTapGesture {
            if wine.isMatched {
                // Use UIImpactFeedbackGenerator directly to avoid indexing issues with HapticManager
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                    onTap()
                }
            }
        }
        .onAppear {
            // Smooth fade-in animation
            withAnimation(.easeInOut(duration: 0.3)) {
                isAppearing = true
            }
            
            // Gentle floating animation - more subtle and smooth
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                floatOffset = -6
            }

            // Haptic feedback when wine is found (only once on first appear)
            if wine.isMatched {
                // Note: Haptic is now handled in mergeResults to avoid duplicates
                if (wine.matchedWine?.score ?? 0) >= 95 {
                    showScoreReveal = true
                    // Hide animation after it plays
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showScoreReveal = false
                        }
                    }
                }
            }
        }
        .onDisappear {
            withAnimation(.easeInOut(duration: 0.25)) {
                isAppearing = false
            }
        }
    }
}

struct UnmatchedBadge: View {
    var body: some View {
        Text("?")
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.7))
            )
            .badgeShadow()
    }
}

// MARK: - Value Indicator Overlay

struct ValueIndicatorOverlay: View {
    let wine: RecognizedWine

    var body: some View {
        if wine.isBestValue {
            HStack(spacing: 2) {
                Image(systemName: "tag.fill")
                    .font(.caption2)
                Text("VALUE")
                    .font(.system(size: 9, weight: .bold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(Color.green)
            )
            .offset(y: 20)
        }
    }
}

// MARK: - Drink Window Indicator

struct DrinkWindowIndicatorOverlay: View {
    let status: DrinkWindowStatus

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: status.iconName)
                .font(.caption2)
            Text(status.displayText)
                .font(.system(size: 9, weight: .semibold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill(Theme.drinkWindowColor(for: status))
        )
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        AROverlayView(
            recognizedWines: [
                RecognizedWine.preview,
                RecognizedWine.previewLowConfidence,
                RecognizedWine.previewNoMatch
            ],
            viewSize: CGSize(width: 390, height: 844),
            onWineTapped: { _ in }
        )
    }
}
#endif
