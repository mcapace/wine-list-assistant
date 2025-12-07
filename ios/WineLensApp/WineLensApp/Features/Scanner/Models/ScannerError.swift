import SwiftUI

enum ScannerError: Error, Identifiable {
    case cameraNotAuthorized
    case cameraConfigurationFailed
    case processingFailed
    case scanLimitReached

    var id: String { String(describing: self) }

    var title: String {
        switch self {
        case .cameraNotAuthorized:
            return "Camera Access Required"
        case .cameraConfigurationFailed:
            return "Camera Error"
        case .processingFailed:
            return "Processing Error"
        case .scanLimitReached:
            return "Scan Limit Reached"
        }
    }

    var message: String {
        switch self {
        case .cameraNotAuthorized:
            return "Please enable camera access in Settings to scan wine lists."
        case .cameraConfigurationFailed:
            return "Unable to configure the camera. Please restart the app."
        case .processingFailed:
            return "Something went wrong. Please try again."
        case .scanLimitReached:
            return "You've used all your free scans this month. Upgrade to Premium for unlimited scanning."
        }
    }

    var errorTitle: String {
        switch self {
        case .cameraNotAuthorized:
            return "Camera Access Required"
        case .cameraConfigurationFailed:
            return "Camera Error"
        case .processingFailed:
            return "Processing Error"
        case .scanLimitReached:
            return "Scan Limit Reached"
        }
    }

    var errorMessage: String {
        switch self {
        case .cameraNotAuthorized:
            return "Wine Lens needs camera access to scan wine lists. Please enable camera access in Settings."
        case .cameraConfigurationFailed:
            return "Unable to start the camera. Please try again or restart the app."
        case .processingFailed:
            return "Unable to process the image. Please try again."
        case .scanLimitReached:
            return "You've reached your free scan limit for this month. Upgrade to Premium for unlimited scans."
        }
    }

    var iconName: String {
        switch self {
        case .cameraNotAuthorized:
            return "camera.fill"
        case .cameraConfigurationFailed:
            return "exclamationmark.camera.fill"
        case .processingFailed:
            return "doc.text.magnifyingglass"
        case .scanLimitReached:
            return "lock.fill"
        }
    }

    var iconColor: Color {
        switch self {
        case .cameraNotAuthorized, .cameraConfigurationFailed:
            return .orange
        case .processingFailed:
            return .yellow
        case .scanLimitReached:
            return Theme.secondaryColor
        }
    }
}
