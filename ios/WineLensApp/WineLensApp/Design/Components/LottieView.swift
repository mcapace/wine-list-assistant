import SwiftUI
import Lottie

/// SwiftUI wrapper for Lottie animations with proper bundle loading
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

    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .clear

        // Try to load animation from bundle
        if let animation = LottieAnimation.named(animationName, bundle: .main) {
            let animationView = LottieAnimationView(animation: animation)
            animationView.loopMode = loopMode
            animationView.animationSpeed = animationSpeed
            animationView.contentMode = contentMode
            animationView.backgroundBehavior = .pauseAndRestore
            animationView.translatesAutoresizingMaskIntoConstraints = false

            containerView.addSubview(animationView)
            NSLayoutConstraint.activate([
                animationView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                animationView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                animationView.topAnchor.constraint(equalTo: containerView.topAnchor),
                animationView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
            ])

            animationView.play()
        }

        return containerView
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // Find and restart animation if needed
        if let animationView = uiView.subviews.first as? LottieAnimationView {
            if !animationView.isAnimationPlaying {
                animationView.play()
            }
        }
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

/// Scanning pulse animation for the scanner view with native fallback
struct ScanPulseAnimation: View {
    @State private var isPulsing = false

    var body: some View {
        ZStack {
            // Native SwiftUI fallback animation (always works)
            Circle()
                .stroke(Theme.secondaryColor.opacity(0.3), lineWidth: 2)
                .scaleEffect(isPulsing ? 1.3 : 0.8)
                .opacity(isPulsing ? 0 : 0.8)

            Circle()
                .stroke(Theme.secondaryColor.opacity(0.2), lineWidth: 1)
                .scaleEffect(isPulsing ? 1.5 : 0.9)
                .opacity(isPulsing ? 0 : 0.6)

            // Lottie animation overlay (if available)
            LottieView(animationName: "Scan_Pulse", loopMode: .loop, animationSpeed: 0.8)
        }
        .frame(width: 200, height: 200)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                isPulsing = true
            }
        }
    }
}

/// Score reveal animation when a wine score is displayed with native fallback
struct ScoreRevealAnimation: View {
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            // Native fallback - expanding circle
            Circle()
                .fill(Theme.secondaryColor.opacity(0.2))
                .scaleEffect(scale)
                .opacity(opacity)

            // Lottie overlay
            LottieView(animationName: "Score_Reveal", loopMode: .playOnce, animationSpeed: 1.2)
        }
        .frame(width: 120, height: 120)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}

/// Wine glass fill animation for loading states with native fallback
struct WineGlassFillAnimation: View {
    let size: CGFloat
    @State private var fillLevel: CGFloat = 0

    init(size: CGFloat = 100) {
        self.size = size
    }

    var body: some View {
        ZStack {
            // Native fallback - wine glass with fill animation
            Image(systemName: "wineglass")
                .font(.system(size: size * 0.6, weight: .light))
                .foregroundColor(Theme.secondaryColor.opacity(0.3))

            Image(systemName: "wineglass.fill")
                .font(.system(size: size * 0.6, weight: .light))
                .foregroundColor(Theme.secondaryColor)
                .mask(
                    Rectangle()
                        .frame(height: size * fillLevel)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                )

            // Lottie overlay
            LottieView(animationName: "Wine_Glass_Fill", loopMode: .loop, animationSpeed: 1.0)
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                fillLevel = 1.0
            }
        }
    }
}

/// Card slide up animation with native fallback
struct CardSlideUpAnimation: View {
    @State private var offset: CGFloat = 50
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            // Native fallback
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
                .offset(y: offset)
                .opacity(opacity)

            // Lottie overlay
            LottieView(animationName: "Card_Slide_Up", loopMode: .playOnce, animationSpeed: 1.0)
        }
        .frame(width: 200, height: 150)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                offset = 0
                opacity = 1.0
            }
        }
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
