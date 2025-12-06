import SwiftUI

struct ScannerView: View {
    @StateObject private var viewModel = ScannerViewModel()
    @EnvironmentObject var subscriptionService: SubscriptionService
    @State private var selectedWine: RecognizedWine?
    @State private var showFilters = false
    @State private var showPaywall = false
    @State private var showInstructions = false
    @AppStorage("hasSeenScannerInstructions") private var hasSeenInstructions = false

    // Computed property for matched wines (only wines with actual database matches)
    private var matchedWines: [RecognizedWine] {
        viewModel.filteredWines.filter { $0.matchedWine != nil }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Camera Preview
                CameraPreviewView(cameraService: viewModel.cameraService)
                    .ignoresSafeArea()

                // AR Overlay - only show matched wines (not unmatched OCR results)
                if !matchedWines.isEmpty {
                    AROverlayView(
                        recognizedWines: matchedWines,
                        viewSize: geometry.size,
                        onWineTapped: { wine in
                            selectedWine = wine
                        }
                    )
                }

                // Top Controls with branding - better spacing
                VStack {
                    ScannerTopBar(
                        torchEnabled: $viewModel.torchEnabled,
                        scansRemaining: subscriptionService.remainingFreeScans(),
                        isPremium: subscriptionService.subscriptionStatus.isActive,
                        onHelpTapped: { showInstructions = true }
                    )

                    Spacer()
                }
                .padding(.top, geometry.safeAreaInsets.top + 8)
                .padding(.horizontal, 0)

                // Center instruction hint (when no matched wines found) - perfectly centered
                if matchedWines.isEmpty && viewModel.cameraService.isRunning {
                    VStack {
                        Spacer()
                        ScannerHintView()
                            .padding(.horizontal, 32)
                        Spacer()
                    }
                }

                // Bottom Controls - better symmetry and spacing
                VStack(spacing: 0) {
                    Spacer()

                    // Scan status - only show when we have MATCHED wines (not just detected text)
                    if matchedWines.count > 0 {
                        VStack(spacing: 16) {
                            ScanningIndicator(winesFound: matchedWines.count)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                            
                            FilterBar(
                                filters: $viewModel.filters,
                                isExpanded: $showFilters
                            )
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, geometry.safeAreaInsets.bottom + 20)
                    } else {
                        FilterBar(
                            filters: $viewModel.filters,
                            isExpanded: $showFilters
                        )
                        .padding(.horizontal, 20)
                        .padding(.bottom, geometry.safeAreaInsets.bottom + 20)
                    }
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
        HStack(alignment: .center, spacing: 12) {
            // Left: Torch button - elevated design
            Button(action: { torchEnabled.toggle() }) {
                Image(systemName: torchEnabled ? "flashlight.on.fill" : "flashlight.off.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.black.opacity(0.7),
                                        Color.black.opacity(0.5)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.3),
                                                Color.white.opacity(0.1)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1.5
                                    )
                            )
                    )
                    .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
            }

            Spacer()

            // Center branding - use WineLensBadge component
            WineLensBadge(style: .light)
                .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 3)

            Spacer()

            // Right side - scan count or help - elevated design
            HStack(spacing: 10) {
                if !isPremium {
                    HStack(spacing: 6) {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 12, weight: .semibold))
                        Text("\(scansRemaining)")
                            .font(.system(size: 15, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.black.opacity(0.7),
                                        Color.black.opacity(0.5)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                Capsule()
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.3),
                                                Color.white.opacity(0.1)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1.5
                                    )
                            )
                    )
                    .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 3)
                }

                Button(action: onHelpTapped) {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.black.opacity(0.7),
                                            Color.black.opacity(0.5)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    Circle()
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(0.3),
                                                    Color.white.opacity(0.1)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1.5
                                        )
                                )
                        )
                        .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
}

// MARK: - Scanner Hint View

struct ScannerHintView: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 20) {
            // Animated scan frame - elevated design
            ZStack {
                // Outer glow
                ScanFrameCorners()
                    .stroke(Theme.secondaryColor.opacity(0.3), lineWidth: 3)
                    .frame(width: 240, height: 170)
                    .blur(radius: 8)
                
                // Main corner brackets
                ScanFrameCorners()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Theme.secondaryColor,
                                Theme.secondaryColor.opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2.5
                    )
                    .frame(width: 220, height: 150)
                    .shadow(color: Theme.secondaryColor.opacity(0.5), radius: 12, x: 0, y: 0)

                // Scanning line animation
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Theme.secondaryColor.opacity(0),
                                Theme.secondaryColor.opacity(0.8),
                                Theme.secondaryColor.opacity(0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 200, height: 3)
                    .offset(y: isAnimating ? 70 : -70)
                    .animation(
                        Animation.easeInOut(duration: 2).repeatForever(autoreverses: true),
                        value: isAnimating
                    )
                    .shadow(color: Theme.secondaryColor.opacity(0.6), radius: 4, x: 0, y: 0)
            }

            VStack(spacing: 8) {
                Text("Point at a wine list")
                    .font(.system(size: 19, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)

                Text("Hold steady to scan wine names")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.white.opacity(0.85))
            }
        }
        .padding(28)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.75),
                            Color.black.opacity(0.65)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.2),
                                    Color.white.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
        )
        .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
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
        VStack(spacing: 14) {
            // Quick filters - elevated design
            HStack(spacing: 10) {
                ForEach(WineFilter.quickFilters) { filter in
                    FilterButton(
                        filter: filter,
                        isActive: filters.contains(filter),
                        action: { filters.toggle(filter) }
                    )
                }

                Spacer()

                // Expand button - elevated design
                Button(action: { withAnimation { isExpanded.toggle() } }) {
                    Image(systemName: isExpanded ? "chevron.down" : "slider.horizontal.3")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.black.opacity(0.7),
                                            Color.black.opacity(0.5)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    Circle()
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(0.3),
                                                    Color.white.opacity(0.1)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1.5
                                        )
                                )
                        )
                        .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 3)
                }
            }

            // Expanded filters
            if isExpanded {
                ExpandedFiltersView(filters: $filters)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isExpanded)
    }
}

struct FilterButton: View {
    let filter: WineFilter
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: filter.iconName)
                    .font(.system(size: 13, weight: .semibold))
                Text(filter.displayName)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
            }
            .foregroundColor(isActive ? .black : .white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(
                        isActive
                            ? LinearGradient(
                                colors: [Color.white, Color.white.opacity(0.95)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [
                                    Color.black.opacity(0.7),
                                    Color.black.opacity(0.5)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
                    .overlay(
                        Capsule()
                            .stroke(
                                isActive
                                    ? Color.clear
                                    : LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.3),
                                            Color.white.opacity(0.1)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                lineWidth: isActive ? 0 : 1.5
                            )
                    )
            )
            .shadow(
                color: isActive
                    ? Color.white.opacity(0.3)
                    : Color.black.opacity(0.4),
                radius: isActive ? 8 : 6,
                x: 0,
                y: isActive ? 4 : 3
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
        HStack(spacing: 12) {
            // Animated progress indicator
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 2.5)
                    .frame(width: 20, height: 20)
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Theme.secondaryColor))
                    .scaleEffect(0.8)
            }

            if winesFound > 0 {
                Text("\(winesFound) wine\(winesFound == 1 ? "" : "s") found")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
            } else {
                Text("Scanning...")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
            }
        }
        .foregroundColor(.white)
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.8),
                            Color.black.opacity(0.7)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    Capsule()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Theme.secondaryColor.opacity(0.4),
                                    Theme.secondaryColor.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
        )
        .shadow(color: .black.opacity(0.5), radius: 12, x: 0, y: 6)
        .shadow(color: Theme.secondaryColor.opacity(0.3), radius: 8, x: 0, y: 4)
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
