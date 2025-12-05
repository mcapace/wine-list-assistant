import UIKit

final class HapticService {
    static let shared = HapticService()
    
    private init() {}
    
    // MARK: - Impact Feedback
    
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    func impact(intensity: CGFloat) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred(intensity: intensity)
    }
    
    // MARK: - Notification Feedback
    
    func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
    
    func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
    
    // MARK: - Selection Feedback
    
    func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
    
    // MARK: - Convenience Methods
    
    func wineMatched() {
        success()
    }
    
    func wineNotFound() {
        warning()
    }
    
    func buttonTap() {
        impact(.light)
    }
    
    func filterChanged() {
        selection()
    }
    
    func scoreRevealed() {
        impact(.medium)
    }
}

