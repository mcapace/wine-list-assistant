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

#Preview {
    ScannerErrorView(
        error: .cameraNotAuthorized,
        onRetry: {},
        onOpenSettings: {}
    )
}
