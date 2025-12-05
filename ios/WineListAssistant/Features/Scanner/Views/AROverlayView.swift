import SwiftUI

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

    var body: some View {
        ZStack(alignment: .top) {
            // Main score badge
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
            
            // Value and drink window indicators below the badge
            VStack(spacing: 4) {
                Spacer()
                    .frame(height: 28) // Space for badge
                
                // Show value indicator if it's a best value
                if wine.isMatched, wine.isBestValue {
                    ValueIndicatorOverlay(wine: wine)
                }
                
                // Show drink window indicator if available
                if wine.isMatched, let matchedWine = wine.matchedWine {
                    DrinkWindowIndicatorOverlay(status: matchedWine.drinkWindowStatus)
                }
            }
        }
        .position(position)
        .scaleEffect(isAppearing ? (isPressed ? 0.9 : 1.0) : 0.5)
        .opacity(isAppearing ? 1.0 : 0.0)
        .onTapGesture {
            if wine.isMatched {
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
            // Haptic feedback when score appears
            if wine.isMatched {
                HapticService.shared.scoreRevealed()
            }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isAppearing = true
            }
        }
        .onDisappear {
            isAppearing = false
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
