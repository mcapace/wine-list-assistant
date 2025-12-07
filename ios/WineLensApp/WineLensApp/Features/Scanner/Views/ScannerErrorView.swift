import SwiftUI

struct ScannerErrorView: View {
    let error: ScannerError
    let onRetry: () -> Void
    let onOpenSettings: () -> Void

    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.85)

            VStack(spacing: 24) {
                // Error icon
                Image(systemName: error.iconName)
                    .font(.system(size: 60))
                    .foregroundColor(error.iconColor)

                // Title
                Text(error.errorTitle)
                    .font(.title2.bold())
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                // Description
                Text(error.errorMessage)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                // Action buttons
                VStack(spacing: 12) {
                    if error == .cameraNotAuthorized {
                        Button(action: onOpenSettings) {
                            Text("Open Settings")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Theme.primaryColor)
                                .cornerRadius(12)
                        }
                    }

                    Button(action: onRetry) {
                        Text(error == .cameraNotAuthorized ? "Try Again" : "Retry")
                            .font(.headline)
                            .foregroundColor(error == .cameraNotAuthorized ? .white : .white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(error == .cameraNotAuthorized ? Color.white.opacity(0.2) : Theme.primaryColor)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.top, 8)
            }
        }
    }
}

// MARK: - Scanner Error Extension

extension ScannerError {
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

#Preview {
    ScannerErrorView(
        error: .cameraNotAuthorized,
        onRetry: {},
        onOpenSettings: {}
    )
}
