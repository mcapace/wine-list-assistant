import SwiftUI

struct ScannerErrorView: View {
    let error: ScannerError
    let onRetry: () -> Void
    let onOpenSettings: () -> Void

    @State private var iconScale: CGFloat = 0.8
    @State private var showContent = false

    var body: some View {
        ZStack {
            // Gradient background matching onboarding style
            LinearGradient(
                colors: [
                    Theme.primaryColor.opacity(0.95),
                    Color.black.opacity(0.95)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 28) {
                Spacer()

                // Elegant icon container
                ZStack {
                    Circle()
                        .fill(Theme.secondaryColor.opacity(0.15))
                        .frame(width: 120, height: 120)

                    Circle()
                        .stroke(Theme.secondaryColor.opacity(0.3), lineWidth: 2)
                        .frame(width: 120, height: 120)

                    Image(systemName: error.iconName)
                        .font(.system(size: 48, weight: .medium))
                        .foregroundColor(Theme.secondaryColor)
                }
                .scaleEffect(iconScale)
                .opacity(showContent ? 1.0 : 0.0)

                VStack(spacing: 16) {
                    Text(error.errorTitle)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text(error.errorMessage)
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 32)
                }
                .opacity(showContent ? 1.0 : 0.0)
                .offset(y: showContent ? 0 : 20)

                Spacer()

                // Action buttons
                VStack(spacing: 12) {
                    if error == .cameraNotAuthorized {
                        Button(action: onOpenSettings) {
                            HStack(spacing: 8) {
                                Image(systemName: "gear")
                                    .font(.system(size: 18, weight: .semibold))
                                Text("Open Settings")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                            .foregroundColor(Theme.primaryColor)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Theme.secondaryColor)
                            .cornerRadius(12)
                        }
                    }

                    Button(action: onRetry) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 18, weight: .semibold))
                            Text(error == .cameraNotAuthorized ? "Try Again" : "Retry")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(error == .cameraNotAuthorized ? Color.white.opacity(0.2) : Theme.primaryColor)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Theme.secondaryColor.opacity(0.5), lineWidth: error == .cameraNotAuthorized ? 0 : 1)
                        )
                    }
                }
                .padding(.horizontal, 32)
                .opacity(showContent ? 1.0 : 0.0)

                Spacer()
                    .frame(height: 60)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                iconScale = 1.0
                showContent = true
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
