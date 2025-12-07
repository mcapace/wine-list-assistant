import SwiftUI
import UIKit

struct ScannerView: View {
    @StateObject private var viewModel = ScannerViewModel()
    @EnvironmentObject var subscriptionService: SubscriptionService
    @State private var selectedWine: RecognizedWine?
    @State private var showFilters = false
    @State private var showPaywall = false
    @State private var showInstructions = false
    @State private var showMatchedWinesList = false
    @State private var showClearConfirmation = false
    @State private var newMatchPulse = false
    @State private var showNewMatchBadge = false
    @State private var previousMatchCount = 0
    @State private var showFirstMatchToast = false
    @State private var showNameSessionDialog = false
    @State private var sessionLocation = ""
    @State private var showSessionHistory = false
    @State private var hasStartedCamera = false
    @AppStorage("hasSeenScannerInstructions") private var hasSeenInstructions = false

    // Count only wines that have been matched from the database (current frame)
    private var matchedWineCount: Int {
        viewModel.filteredWines.filter { $0.matchedWine != nil }.count
    }
    
    // Session match count (persistent)
    private var sessionMatchCount: Int {
        viewModel.sessionMatchCount
    }
    
    private var outstandingCount: Int {
        viewModel.matchedPersistentWines.filter { ($0.matchedWine?.score ?? 0) >= 95 }.count
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Camera Preview - full screen background
                CameraPreviewView(cameraService: viewModel.cameraService)
                    .ignoresSafeArea()

                // Error overlay - show when there's an error
                if let error = viewModel.error {
                    ScannerErrorView(error: error, onRetry: {
                        viewModel.retry()
                    }, onOpenSettings: {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    })
                    .ignoresSafeArea()
                }

                // AR Overlay - shows wine recognition badges (only for matched wines)
                let matchedWines = viewModel.filteredWines.filter { $0.matchedWine != nil }
                if !matchedWines.isEmpty && viewModel.error == nil {
                    AROverlayView(
                        recognizedWines: matchedWines,
                        viewSize: geometry.size,
                        onWineTapped: { wine in
                            selectedWine = wine
                        }
                    )
                }

                // Main UI overlay
                VStack(spacing: 0) {
                    // Top Controls - minimal and clean (Vivino-style)
                    HStack {
                        // Close/Back button
                        Button(action: {
                            // Could navigate back or show settings
                            showSessionHistory = true
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(Color.black.opacity(0.4))
                                )
                        }
                        
                        Spacer()
                        
                        // Torch toggle
                        Button(action: {
                            viewModel.torchEnabled.toggle()
                        }) {
                            Image(systemName: viewModel.torchEnabled ? "bolt.fill" : "bolt.slash.fill")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(Color.black.opacity(0.4))
                                )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, geometry.safeAreaInsets.top + 12)

                    // Scanning frame overlay (Vivino-style - subtle dashed frame)
                    if sessionMatchCount == 0 && viewModel.cameraService.isRunning && !viewModel.isProcessing {
                        ScanningFrameOverlay()
                            .transition(.opacity)
                    }
                    
                    Spacer()
                    
                    // Processing indicator - minimal and clean
                    if viewModel.isProcessing {
                        HStack(spacing: 8) {
                            ProgressView()
                                .tint(.white)
                            Text("Analyzing...")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.7))
                        )
                        .transition(.opacity)
                        .padding(.bottom, 120)
                    }
                    
                    // First match celebration toast
                    if showFirstMatchToast {
                        FirstMatchCelebrationToast()
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .zIndex(1000)
                    }

                    Spacer()

                    // Bottom section - cleaner Vivino-inspired design
                    VStack(spacing: 12) {
                        // Clean results summary chip (if wines found)
                        if sessionMatchCount > 0 {
                            Button(action: {
                                showMatchedWinesList = true
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "wineglass.fill")
                                        .font(.system(size: 14))
                                    Text("\(sessionMatchCount) wine\(sessionMatchCount == 1 ? "" : "s") found")
                                        .font(.system(size: 15, weight: .semibold))
                                    if outstandingCount > 0 {
                                        Text("• \(outstandingCount) outstanding")
                                            .font(.system(size: 14, weight: .medium))
                                            .opacity(0.8)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .semibold))
                                        .opacity(0.6)
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 14)
                                .background(
                                    Capsule()
                                        .fill(Color.black.opacity(0.75))
                                )
                            }
                            .padding(.horizontal)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                        
                        // Instructions card (Vivino-style) - when no wines found
                        if sessionMatchCount == 0 && viewModel.cameraService.isRunning && !viewModel.isProcessing {
                            InstructionsCard()
                                .padding(.horizontal)
                                .transition(.opacity)
                        }
                        
                        // Action buttons row (when wines found)
                        if sessionMatchCount > 0 {
                            HStack(spacing: 12) {
                                // View Results button - full width primary
                                Button(action: {
                                    showMatchedWinesList = true
                                }) {
                                    Text("View Results")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(Theme.primaryColor)
                                        .cornerRadius(12)
                                }
                                
                                // Save button - secondary
                                Button(action: {
                                    let generator = UIImpactFeedbackGenerator(style: .medium)
                                    generator.impactOccurred()
                                    showNameSessionDialog = true
                                }) {
                                    Image(systemName: "square.and.arrow.down")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(width: 50, height: 50)
                                        .background(Color.white.opacity(0.2))
                                        .cornerRadius(12)
                                }
                            }
                            .padding(.horizontal)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                        
                        // Filter bar (keep but make it less prominent when no wines)
                        if sessionMatchCount > 0 {
                            FilterBar(
                                filters: $viewModel.filters,
                                isExpanded: $showFilters
                            )
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, geometry.safeAreaInsets.bottom + 20)
                }
                .animation(.easeInOut(duration: 0.3), value: matchedWineCount)
                .animation(.easeInOut(duration: 0.2), value: viewModel.isProcessing)

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
        .sheet(isPresented: $showMatchedWinesList) {
            MatchedWinesListView(
                matchedWines: viewModel.matchedPersistentWines,
                onWineTapped: { wine in
                    selectedWine = wine
                    showMatchedWinesList = false
                }
            )
        }
        .sheet(isPresented: $showSessionHistory) {
            SessionHistoryView()
        }
        .alert("Name This Session", isPresented: $showNameSessionDialog) {
            TextField("Restaurant name (optional)", text: $sessionLocation)
            Button("Cancel", role: .cancel) {
                sessionLocation = ""
            }
            Button("Save & Exit") {
                viewModel.updateSessionLocation(sessionLocation.isEmpty ? nil : sessionLocation)
                viewModel.saveSessionToHistory()
                sessionLocation = ""
                // Navigate back or dismiss scanner
            }
        } message: {
            Text("Give this scan session a name (e.g., restaurant name) for easy reference later.")
        }
        .confirmationDialog("Clear Session", isPresented: $showClearConfirmation) {
            Button("Clear All", role: .destructive) {
                viewModel.clearSession()
                previousMatchCount = 0
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will clear all wines found in this session. Continue?")
        }
            .onAppear {
                // Start camera when view appears (more reliable than .task with lazy loading)
                guard !hasStartedCamera else { return }
                hasStartedCamera = true
                
                Task { @MainActor in
                    // Small delay to ensure view is fully rendered
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                    
                    // Check if camera is already running to avoid duplicate starts
                    guard !viewModel.cameraService.isRunning else { return }
                    
                    // Always request authorization and start camera
                    // This will show permission dialog if needed
                    await viewModel.startScanning()
                }
            }
            .onDisappear {
                viewModel.stopScanning()
                hasStartedCamera = false // Reset so it can start again if view reappears
            }
        .onChange(of: sessionMatchCount) { oldValue, newValue in
            // First match celebration!
            if newValue == 1 && oldValue == 0 {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    showFirstMatchToast = true
                }
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                
                // Hide toast after 2.5 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showFirstMatchToast = false
                    }
                }
            }
            
            // Detect new match added
            if newValue > previousMatchCount {
                // Haptic feedback (already triggered in mergeResults, but ensure it happens)
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                
                // Show pulse animation
                withAnimation(.easeInOut(duration: 0.3)) {
                    newMatchPulse = true
                    showNewMatchBadge = true
                }
                
                // Reset pulse
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        newMatchPulse = false
                    }
                }
                
                // Hide badge after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showNewMatchBadge = false
                    }
                }
            }
            previousMatchCount = newValue
        }
    }
}

// MARK: - OCR Recovery Indicator

struct OCRRecoveryIndicator: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 12))
                .foregroundColor(.orange)
            
            Text("Using fast mode")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.7))
                .overlay(
                    Capsule()
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.top, 8)
    }
}

// MARK: - Scanner Top Bar with Branding

struct ScannerTopBar: View {
    @Binding var torchEnabled: Bool
    let scansRemaining: Int
    let isPremium: Bool
    let onHelpTapped: () -> Void
    let onHistoryTapped: () -> Void
    let onClearTapped: () -> Void

    var body: some View {
        HStack(alignment: .center) {
            // Left side - menu button
            Menu {
                Button(action: onHistoryTapped) {
                    Label("View History", systemImage: "clock.arrow.circlepath")
                }
                
                Button(role: .destructive, action: onClearTapped) {
                    Label("Clear Session", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(Color.black.opacity(0.6))
                    )
            }

            Spacer()

            // Center branding
            WineLensBadge(style: .light)

            Spacer()

            // Right side
            HStack(spacing: 8) {
                // Torch button
                Button(action: { torchEnabled.toggle() }) {
                    Image(systemName: torchEnabled ? "flashlight.on.fill" : "flashlight.off.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(torchEnabled ? Theme.secondaryColor : .white)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(Color.black.opacity(0.6))
                        )
                }
                
                // Scan count (free users only)
                if !isPremium {
                    HStack(spacing: 4) {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 12))
                        Text("\(scansRemaining)")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.6))
                    )
                } else {
                    // Empty spacer to balance layout for premium users
                    Color.clear
                        .frame(width: 44, height: 44)
                }
            }
        }
    }
}

// MARK: - Scanning Frame Overlay (Vivino-style)

struct ScanningFrameOverlay: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Subtle dashed scanning frame in center
                RoundedRectangle(cornerRadius: 16)
                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [8, 6]))
                    .foregroundColor(.white.opacity(0.5))
                    .frame(width: geometry.size.width * 0.85, height: 220)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - Instructions Card (Vivino-style clean card)

struct InstructionsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "list.bullet.rectangle")
                    .font(.system(size: 20))
                    .foregroundColor(Theme.primaryColor)
                    .frame(width: 32, height: 32)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Pick the right wine")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("Take a photo of wine list, aim for straight lines and clear text")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
}

// MARK: - Scanner Hint View

struct ScannerHintView: View {
    @State private var isAnimating = false
    @State private var scanLineOffset: CGFloat = -60
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 24) {
            // Animated wine glass icon
            ZStack {
                // Pulse animation background
                Circle()
                    .fill(Theme.secondaryColor.opacity(0.1))
                    .frame(width: 120, height: 120)
                    .scaleEffect(pulseScale)
                
                Image(systemName: "wineglass.fill")
                    .font(.system(size: 48))
                    .foregroundColor(Theme.secondaryColor)
            }

            // Animated scan frame with pulse effect
            ZStack {
                // Pulse animation
                ScanPulseAnimation()
                    .opacity(0.5)

                // Corner brackets frame
                ScanFrameCorners()
                    .stroke(Theme.secondaryColor, lineWidth: 2)
                    .frame(width: 200, height: 140)

                // Scanning line animation
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Theme.secondaryColor.opacity(0),
                                Theme.secondaryColor.opacity(0.6),
                                Theme.secondaryColor.opacity(0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 180, height: 2)
                    .offset(y: scanLineOffset)
            }
            .frame(width: 200, height: 200)

            VStack(spacing: 12) {
                Text("Point at a wine list")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)

                Text("Hold steady to scan wine names")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
                
                // Example hint
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 12))
                    Text("Ensure good lighting and move closer to text")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(.white.opacity(0.6))
                .padding(.top, 4)
            }
            .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 32)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.black.opacity(0.75))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Theme.secondaryColor.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        .onAppear {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()

            // Animate scan line
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                scanLineOffset = 60
            }
            
            // Pulse animation
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                pulseScale = 1.2
            }
        }
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
        Button(action: {
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
            action()
        }) {
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
        HStack(spacing: 10) {
            // Wine glass icon with count
            Image(systemName: "wineglass.fill")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Theme.secondaryColor)

            Text("\(winesFound)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text(winesFound == 1 ? "wine found" : "wines found")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.8))
                .overlay(
                    Capsule()
                        .stroke(Theme.secondaryColor.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Session Stats Chip

struct SessionStatsChip: View {
    let wineCount: Int
    let outstandingCount: Int
    let onTap: () -> Void
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            onTap()
        }) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.secondaryColor)
                
                Text("\(wineCount) wine\(wineCount == 1 ? "" : "s")")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                if outstandingCount > 0 {
                    Text("• \(outstandingCount) outstanding")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.7))
                    .overlay(
                        Capsule()
                            .stroke(Theme.secondaryColor.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
}

// MARK: - View Results Button

struct ViewResultsButton: View {
    let count: Int
    var pulse: Bool = false
    var showNewBadge: Bool = false
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            onTap()
        }) {
            HStack(spacing: 12) {
                ZStack {
                    if showNewBadge {
                        Text("+1")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.green)
                            )
                            .offset(x: -20, y: -20)
                            .transition(.scale.combined(with: .opacity))
                    }
                    
                    Image(systemName: "list.bullet.rectangle")
                        .font(.system(size: 18, weight: .semibold))
                }
                
                Text("View Results")
                    .font(.system(size: 16, weight: .semibold))
                
                Text("(\(count))")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Theme.secondaryColor)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Theme.secondaryColor.opacity(0.9),
                                Theme.secondaryColor.opacity(0.7)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .shadow(color: Theme.secondaryColor.opacity(0.3), radius: 12, x: 0, y: 6)
            .scaleEffect(isPressed ? 0.95 : (pulse ? 1.05 : 1.0))
            .animation(.easeInOut(duration: 0.2), value: isPressed)
            .animation(.easeInOut(duration: 0.3), value: pulse)
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
    }
}

// MARK: - Processing Indicator

struct ProcessingIndicator: View {
    @State private var scanLineOffset: CGFloat = -100
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        VStack(spacing: 12) {
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
                .offset(y: scanLineOffset)
                .blur(radius: 2)
            
            HStack(spacing: 8) {
                // Pulsing dots animation
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Theme.secondaryColor)
                        .frame(width: 8, height: 8)
                        .scaleEffect(pulseScale)
                        .animation(
                            .easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                            value: pulseScale
                        )
                }
            }
            .padding(.top, 4)
            
            Text("Analyzing...")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
        }
        .frame(width: 200, height: 200)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                scanLineOffset = 100
            }
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                pulseScale = 0.5
            }
        }
    }
}

// MARK: - First Match Celebration Toast

struct FirstMatchCelebrationToast: View {
    @State private var confettiScale: CGFloat = 0.5
    @State private var confettiOpacity: Double = 1.0

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                // Confetti burst effect
                ForEach(0..<8) { index in
                    Image(systemName: "sparkle")
                        .font(.system(size: 16))
                        .foregroundColor(confettiColor(for: index))
                        .offset(confettiOffset(for: index))
                        .scaleEffect(confettiScale)
                        .opacity(confettiOpacity)
                }

                // Main icon
                Image(systemName: "party.popper.fill")
                    .font(.system(size: 32))
                    .foregroundColor(Theme.secondaryColor)
            }

            Text("Found one!")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text("Tap to see details")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.85),
                            Color.black.opacity(0.75)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Theme.secondaryColor.opacity(0.4), lineWidth: 1.5)
                )
        )
        .shadow(color: Theme.secondaryColor.opacity(0.3), radius: 20, x: 0, y: 10)
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
        .onAppear {
            // Confetti animation
            withAnimation(.easeOut(duration: 0.5)) {
                confettiScale = 1.2
            }
            withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
                confettiOpacity = 0
            }
        }
    }

    private func confettiColor(for index: Int) -> Color {
        let colors: [Color] = [.yellow, .orange, .pink, .purple, .blue, .green, .red, Theme.secondaryColor]
        return colors[index % colors.count]
    }

    private func confettiOffset(for index: Int) -> CGSize {
        let angle = Double(index) * .pi / 4
        let distance: CGFloat = 35
        return CGSize(
            width: CGFloat(Foundation.cos(angle)) * distance,
            height: CGFloat(Foundation.sin(angle)) * distance
        )
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
