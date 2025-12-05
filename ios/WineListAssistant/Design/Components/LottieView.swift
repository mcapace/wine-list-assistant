import SwiftUI

// MARK: - Lottie Animation Wrapper
// Note: Requires Lottie package to be added via Swift Package Manager
// Package URL: https://github.com/airbnb/lottie-spm

#if canImport(Lottie)
import Lottie

struct LottieAnimationView: UIViewRepresentable {
    let filename: String
    let loopMode: LottieLoopMode
    let animationSpeed: CGFloat
    
    init(filename: String, loopMode: LottieLoopMode = .loop, animationSpeed: CGFloat = 1.0) {
        self.filename = filename
        self.loopMode = loopMode
        self.animationSpeed = animationSpeed
    }
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let animationView = LottieAnimationView()
        
        // Try to load from main bundle first
        if let path = Bundle.main.path(forResource: filename, ofType: "json", inDirectory: "Animations") {
            animationView.animation = LottieAnimation.filepath(path)
        } else if let animation = LottieAnimation.named(filename) {
            animationView.animation = animation
        }
        
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = loopMode
        animationView.animationSpeed = animationSpeed
        animationView.play()
        
        animationView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(animationView)
        
        NSLayoutConstraint.activate([
            animationView.widthAnchor.constraint(equalTo: view.widthAnchor),
            animationView.heightAnchor.constraint(equalTo: view.heightAnchor)
        ])
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Animation updates handled automatically
    }
}
#else
// Fallback if Lottie is not available
struct LottieAnimationView: View {
    let filename: String
    let loopMode: String
    let animationSpeed: CGFloat
    
    var body: some View {
        Image(systemName: "sparkles")
            .foregroundColor(.secondary)
    }
}
#endif

// MARK: - Predefined Animation Views

struct ScanPulseAnimation: View {
    var body: some View {
        LottieAnimationView(filename: "Scan_Pulse", loopMode: .loop, animationSpeed: 1.0)
    }
}

struct ScoreRevealAnimation: View {
    var body: some View {
        LottieAnimationView(filename: "Score_Reveal", loopMode: .playOnce, animationSpeed: 1.0)
    }
}

struct WineGlassFillAnimation: View {
    var body: some View {
        LottieAnimationView(filename: "Wine_Glass_Fill", loopMode: .loop, animationSpeed: 0.8)
    }
}

struct CardSlideUpAnimation: View {
    var body: some View {
        LottieAnimationView(filename: "Card_Slide_Up", loopMode: .playOnce, animationSpeed: 1.0)
    }
}

