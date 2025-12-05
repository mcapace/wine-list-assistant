import SwiftUI
import Lottie

/// SwiftUI wrapper for Lottie animations
struct LottieView: UIViewRepresentable {
    let animationName: String
    let loopMode: LottieLoopMode
    let animationSpeed: CGFloat
    let contentMode: UIView.ContentMode

    init(
        animationName: String,
        loopMode: LottieLoopMode = .loop,
        animationSpeed: CGFloat = 1.0,
        contentMode: UIView.ContentMode = .scaleAspectFit
    ) {
        self.animationName = animationName
        self.loopMode = loopMode
        self.animationSpeed = animationSpeed
        self.contentMode = contentMode
    }

    func makeUIView(context: Context) -> LottieAnimationView {
        let animationView = LottieAnimationView(name: animationName)
        animationView.loopMode = loopMode
        animationView.animationSpeed = animationSpeed
        animationView.contentMode = contentMode
        animationView.play()
        return animationView
    }

    func updateUIView(_ uiView: LottieAnimationView, context: Context) {
        // No updates needed
    }
}

/// Animated Lottie view with controls
struct AnimatedLottieView: View {
    let animationName: String
    let loopMode: LottieLoopMode
    let size: CGSize?

    init(
        _ animationName: String,
        loopMode: LottieLoopMode = .loop,
        size: CGSize? = nil
    ) {
        self.animationName = animationName
        self.loopMode = loopMode
        self.size = size
    }

    var body: some View {
        LottieView(animationName: animationName, loopMode: loopMode)
            .frame(width: size?.width, height: size?.height)
    }
}

// MARK: - App-specific Animation Views

/// Scanning pulse animation for the scanner view
struct ScanPulseAnimation: View {
    var body: some View {
        LottieView(animationName: "Scan_Pulse", loopMode: .loop, animationSpeed: 0.8)
            .frame(width: 200, height: 200)
    }
}

/// Score reveal animation when a wine score is displayed
struct ScoreRevealAnimation: View {
    var body: some View {
        LottieView(animationName: "Score_Reveal", loopMode: .playOnce, animationSpeed: 1.2)
            .frame(width: 120, height: 120)
    }
}

/// Wine glass fill animation for loading states
struct WineGlassFillAnimation: View {
    let size: CGFloat

    init(size: CGFloat = 100) {
        self.size = size
    }

    var body: some View {
        LottieView(animationName: "Wine_Glass_Fill", loopMode: .loop, animationSpeed: 1.0)
            .frame(width: size, height: size)
    }
}

/// Card slide up animation
struct CardSlideUpAnimation: View {
    var body: some View {
        LottieView(animationName: "Card_Slide_Up", loopMode: .playOnce, animationSpeed: 1.0)
            .frame(width: 200, height: 150)
    }
}

// MARK: - Loading View with Animation

struct AnimatedLoadingView: View {
    let message: String

    init(message: String = "Loading...") {
        self.message = message
    }

    var body: some View {
        VStack(spacing: 16) {
            WineGlassFillAnimation(size: 80)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 40) {
        WineGlassFillAnimation()
        ScanPulseAnimation()
    }
}
