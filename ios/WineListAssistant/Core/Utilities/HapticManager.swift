import UIKit

/// Centralized haptic feedback manager for the app
final class HapticManager {
    static let shared = HapticManager()

    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let selection = UISelectionFeedbackGenerator()
    private let notification = UINotificationFeedbackGenerator()

    private init() {
        // Pre-prepare generators for better responsiveness
        prepareAll()
    }

    private func prepareAll() {
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        selection.prepare()
        notification.prepare()
    }

    // MARK: - Impact Feedback

    /// Light tap feedback - for subtle interactions
    func lightImpact() {
        impactLight.impactOccurred()
        impactLight.prepare()
    }

    /// Medium tap feedback - for button presses
    func mediumImpact() {
        impactMedium.impactOccurred()
        impactMedium.prepare()
    }

    /// Heavy tap feedback - for significant actions
    func heavyImpact() {
        impactHeavy.impactOccurred()
        impactHeavy.prepare()
    }

    // MARK: - Selection Feedback

    /// Selection changed feedback - for picker/tab changes
    func selectionChanged() {
        selection.selectionChanged()
        selection.prepare()
    }

    // MARK: - Notification Feedback

    /// Success feedback - for successful operations
    func success() {
        notification.notificationOccurred(.success)
        notification.prepare()
    }

    /// Warning feedback - for warnings
    func warning() {
        notification.notificationOccurred(.warning)
        notification.prepare()
    }

    /// Error feedback - for errors
    func error() {
        notification.notificationOccurred(.error)
        notification.prepare()
    }

    // MARK: - App-Specific Haptics

    /// Wine found haptic - plays when a wine is recognized
    func wineFound() {
        mediumImpact()
    }

    /// High score haptic - plays for 95+ wines
    func highScoreWine() {
        heavyImpact()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.success()
        }
    }

    /// Save wine haptic
    func wineSaved() {
        success()
    }

    /// Filter changed haptic
    func filterChanged() {
        selectionChanged()
    }

    /// Scan started haptic
    func scanStarted() {
        lightImpact()
    }

    /// Button tap haptic
    func buttonTap() {
        lightImpact()
    }
}

// MARK: - SwiftUI View Extension

import SwiftUI

extension View {
    /// Adds haptic feedback on tap
    func hapticOnTap(_ type: HapticType = .light) -> some View {
        self.simultaneousGesture(
            TapGesture().onEnded { _ in
                switch type {
                case .light:
                    HapticManager.shared.lightImpact()
                case .medium:
                    HapticManager.shared.mediumImpact()
                case .heavy:
                    HapticManager.shared.heavyImpact()
                case .selection:
                    HapticManager.shared.selectionChanged()
                case .success:
                    HapticManager.shared.success()
                }
            }
        )
    }
}

enum HapticType {
    case light
    case medium
    case heavy
    case selection
    case success
}
