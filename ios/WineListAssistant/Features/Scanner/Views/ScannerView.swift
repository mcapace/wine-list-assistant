import SwiftUI

struct ScannerView: View {
    @StateObject private var viewModel = ScannerViewModel()
    @EnvironmentObject var subscriptionService: SubscriptionService
    @State private var selectedWine: RecognizedWine?
    @State private var showFilters = false
    @State private var showPaywall = false
    @State private var showInstructions = false
    @AppStorage("hasSeenScannerInstructions") private var hasSeenInstructions = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Camera Preview
                CameraPreviewView(cameraService: viewModel.cameraService)
                    .ignoresSafeArea()

                // AR Overlay
                AROverlayView(
                    recognizedWines: viewModel.filteredWines,
                    viewSize: geometry.size,
                    onWineTapped: { wine in
                        selectedWine = wine
                    }
                )

                // Top Controls with branding
                VStack {
                    ScannerTopBar(
                        torchEnabled: $viewModel.torchEnabled,
                        scansRemaining: subscriptionService.remainingFreeScans(),
                        isPremium: subscriptionService.subscriptionStatus.isActive,
                        onHelpTapped: { showInstructions = true }
                    )

                    Spacer()
                }
                .padding()

                // Center instruction hint (when no wines found)
                if viewModel.recognizedWines.isEmpty && !viewModel.isProcessing {
                    ScannerHintView()
                }

                // Bottom Controls
                VStack {
                    Spacer()

                    // Scan status
                    if viewModel.isProcessing {
                        ScanningIndicator(winesFound: viewModel.recognizedWines.count)
                    }

                    FilterBar(
                        filters: $viewModel.filters,
                        isExpanded: $showFilters
                    )
                    .padding(.horizontal)
                    .padding(.bottom, geometry.safeAreaInsets.bottom + 16)
                }

                // Permission denied overlay
                if viewModel.cameraService.error == .notAuthorized {
                    CameraPermissionView()
                }

                // Paywall overlay
                if !subscriptionService.canPerformScan() {
                    ScanLimitReachedView(onSubscribe: { showPaywall = true })
                }

                // First-time instructions overlay
                if showInstructions || !hasSeenInstructions {
                    ScannerInstructionsOverlay(onDismiss: {
                        hasSeenInstructions = true
                        showInstructions = false
                    })
                }
            }
        }
        .sheet(item: $selectedWine) { wine in
            WineDetailSheet(recognizedWine: wine)
        }
        .sheet(isPresented: $showPaywall) {
            SubscriptionView()
        }
        .task {
            await viewModel.startScanning()
        }
        .onDisappear {
            viewModel.stopScanning()
        }
    }
}

// MARK: - Scanner Top Bar with Branding

struct ScannerTopBar: View {
    @Binding var torchEnabled: Bool
    let scansRemaining: Int
    let isPremium: Bool
    let onHelpTapped: () -> Void

    var body: some View {
        HStack(alignment: .center) {
            // Torch button
            Button(action: { torchEnabled.toggle() }) {
                Image(systemName: torchEnabled ? "flashlight.on.fill" : "flashlight.off.fill")
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(Color.black.opacity(0.5))
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    )
            }

            Spacer()

            // Center branding
            VStack(spacing: 2) {
                Text("WINE LENS")
                    .font(.system(size: 12, weight: .bold, design: .default))
                    .tracking(2)
                    .foregroundColor(Theme.secondaryColor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.5))
                    .overlay(
                        Capsule()
                            .stroke(Theme.secondaryColor.opacity(0.3), lineWidth: 1)
                    )
            )

            Spacer()

            // Right side - scan count or help
            HStack(spacing: 8) {
                if !isPremium {
                    HStack(spacing: 4) {
                        Image(systemName: "camera.viewfinder")
                            .font(.caption)
                        Text("\(scansRemaining)")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.5))
                    )
                }

                Button(action: onHelpTapped) {
                    Image(systemName: "questionmark.circle")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(Color.black.opacity(0.5))
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                }
            }
        }
    }
}

// MARK: - Scanner Hint View

struct ScannerHintView: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 16) {
            // Animated scan frame
            ZStack {
                // Corner brackets
                ScanFrameCorners()
                    .stroke(Theme.secondaryColor, lineWidth: 2)
                    .frame(width: 200, height: 140)

                // Scanning line animation
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Theme.secondaryColor.opacity(0), Theme.secondaryColor.opacity(0.5), Theme.secondaryColor.opacity(0)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 180, height: 2)
                    .offset(y: isAnimating ? 60 : -60)
                    .animation(
                        Animation.easeInOut(duration: 2).repeatForever(autoreverses: true),
                        value: isAnimating
                    )
            }

            Text("Point at a wine list")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.white)

            Text("Hold steady to scan wine names")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .onAppear { isAnimating = true }
    }
}

// MARK: - Scan Frame Shape

struct ScanFrameCorners: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let cornerLength: CGFloat = 20

        // Top left
        path.move(to: CGPoint(x: 0, y: cornerLength))
        path.addLine(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: cornerLength, y: 0))

        // Top right
        path.move(to: CGPoint(x: rect.width - cornerLength, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: cornerLength))

        // Bottom right
        path.move(to: CGPoint(x: rect.width, y: rect.height - cornerLength))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: rect.width - cornerLength, y: rect.height))

        // Bottom left
        path.move(to: CGPoint(x: cornerLength, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height - cornerLength))

        return path
    }
}

// MARK: - Instructions Overlay

struct ScannerInstructionsOverlay: View {
    let onDismiss: () -> Void
    @State private var currentStep = 0

    let steps = [
        InstructionStep(
            icon: "camera.viewfinder",
            title: "Point & Scan",
            description: "Hold your phone over any wine list. The camera will automatically detect wine names."
        ),
        InstructionStep(
            icon: "sparkles",
            title: "See Scores Instantly",
            description: "Wine Spectator scores appear right on the list. Gold badges mean 95+ points!"
        ),
        InstructionStep(
            icon: "hand.tap",
            title: "Tap for Details",
            description: "Tap any wine to see tasting notes, drink window, and price information."
        ),
        InstructionStep(
            icon: "slider.horizontal.3",
            title: "Filter Results",
            description: "Use filters to show only 90+ wines, best values, or wines ready to drink now."
        )
    ]

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.85)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                // Close button
                HStack {
                    Spacer()
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.horizontal)

                Spacer()

                // Current instruction
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(Theme.primaryColor.opacity(0.2))
                            .frame(width: 100, height: 100)

                        Image(systemName: steps[currentStep].icon)
                            .font(.system(size: 44))
                            .foregroundColor(Theme.secondaryColor)
                    }

                    Text(steps[currentStep].title)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)

                    Text(steps[currentStep].description)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                Spacer()

                // Page indicator
                HStack(spacing: 8) {
                    ForEach(0..<steps.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentStep ? Theme.secondaryColor : Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }

                // Buttons
                HStack(spacing: 16) {
                    if currentStep > 0 {
                        Button(action: { withAnimation { currentStep -= 1 } }) {
                            Text("Back")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(12)
                        }
                    }

                    Button(action: {
                        if currentStep < steps.count - 1 {
                            withAnimation { currentStep += 1 }
                        } else {
                            onDismiss()
                        }
                    }) {
                        Text(currentStep < steps.count - 1 ? "Next" : "Start Scanning")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Theme.secondaryColor)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

struct InstructionStep {
    let icon: String
    let title: String
    let description: String
}

// MARK: - Top Control Bar

struct TopControlBar: View {
    @Binding var torchEnabled: Bool
    let scansRemaining: Int
    let isPremium: Bool

    var body: some View {
        HStack {
            // Torch button
            Button(action: { torchEnabled.toggle() }) {
                Image(systemName: torchEnabled ? "flashlight.on.fill" : "flashlight.off.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
            }

            Spacer()

            // Scan counter (free users only)
            if !isPremium {
                HStack(spacing: 4) {
                    Image(systemName: "camera.viewfinder")
                    Text("\(scansRemaining) left")
                }
                .font(.caption)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.5))
                .clipShape(Capsule())
            }
        }
    }
}

// MARK: - Filter Bar

struct FilterBar: View {
    @Binding var filters: FilterSet
    @Binding var isExpanded: Bool

    var body: some View {
        VStack(spacing: 12) {
            // Quick filters
            HStack(spacing: 10) {
                ForEach(WineFilter.quickFilters) { filter in
                    FilterButton(
                        filter: filter,
                        isActive: filters.contains(filter),
                        action: { filters.toggle(filter) }
                    )
                }

                Spacer()

                // Expand button
                Button(action: { withAnimation { isExpanded.toggle() } }) {
                    Image(systemName: isExpanded ? "chevron.down" : "slider.horizontal.3")
                        .font(.body)
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Circle())
                }
            }

            // Expanded filters
            if isExpanded {
                ExpandedFiltersView(filters: $filters)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }
}

struct FilterButton: View {
    let filter: WineFilter
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: filter.iconName)
                    .font(.caption)
                Text(filter.displayName)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(isActive ? .black : .white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isActive ? Color.white : Color.black.opacity(0.6))
            )
        }
    }
}

struct ExpandedFiltersView: View {
    @Binding var filters: FilterSet

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Score filters
            HStack {
                Text("Min Score:")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))

                ForEach(WineFilter.scoreFilters) { filter in
                    FilterChip(
                        title: filter.displayName,
                        isActive: filters.contains(filter),
                        action: { filters.toggle(filter) }
                    )
                }
            }

            // Type filters
            HStack {
                Text("Type:")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))

                ForEach(WineFilter.typeFilters) { filter in
                    FilterChip(
                        title: filter.displayName,
                        isActive: filters.contains(filter),
                        action: { filters.toggle(filter) }
                    )
                }
            }

            // Clear button
            if !filters.isEmpty {
                Button(action: { filters.clear() }) {
                    Text("Clear All")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.7))
        .cornerRadius(Theme.CornerRadius.large)
    }
}

struct FilterChip: View {
    let title: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .foregroundColor(isActive ? .black : .white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(isActive ? Color.white : Color.white.opacity(0.2))
                )
        }
    }
}

// MARK: - Scanning Indicator

struct ScanningIndicator: View {
    let winesFound: Int

    var body: some View {
        HStack(spacing: 8) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))

            if winesFound > 0 {
                Text("\(winesFound) wines found")
            } else {
                Text("Scanning...")
            }
        }
        .font(.subheadline)
        .foregroundColor(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.7))
        .clipShape(Capsule())
    }
}

// MARK: - Permission & Paywall Views

struct CameraPermissionView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill")
                .font(.system(size: 60))
                .foregroundColor(.white)

            Text("Camera Access Required")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text("To scan wine lists, please allow camera access in Settings.")
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)

            Button(action: openSettings) {
                Text("Open Settings")
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .cornerRadius(Theme.CornerRadius.medium)
            }
            .padding(.horizontal, 40)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.9))
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

struct ScanLimitReachedView: View {
    let onSubscribe: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.yellow)

            Text("Free Scans Used")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text("You've used all \(AppConfiguration.freeScansPerMonth) free scans this month. Upgrade to Premium for unlimited scanning.")
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)

            Button(action: onSubscribe) {
                Text("Upgrade to Premium")
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .cornerRadius(Theme.CornerRadius.medium)
            }
            .padding(.horizontal, 40)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.9))
    }
}

// MARK: - Preview

#Preview {
    ScannerView()
        .environmentObject(SubscriptionService.shared)
}
