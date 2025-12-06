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
        Group {
            if wine.isMatched {
                // Matched wine - show score badge
                ScoreBadge(
                    score: wine.matchedWine?.score,
                    confidence: wine.matchConfidence,
                    vintage: wine.matchedVintage
                )
            } else {
                // Unmatched text - show subtle indicator so user knows OCR is working
                UnmatchedBadge(text: wine.originalText)
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
    let text: String
    
    var body: some View {
        VStack(spacing: 2) {
            // Show first few words of detected text so user knows OCR is working
            Text(text.prefix(20) + (text.count > 20 ? "..." : ""))
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(1)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            
            // Question mark indicator
            Text("?")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(
                    Circle()
                        .fill(Color.orange.opacity(0.8))
                )
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.orange.opacity(0.5), lineWidth: 1)
                )
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
