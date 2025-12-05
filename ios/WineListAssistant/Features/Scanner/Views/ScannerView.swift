import SwiftUI

struct ScannerView: View {
    @StateObject private var viewModel = ScannerViewModel()
    @EnvironmentObject var subscriptionService: SubscriptionService
    @State private var selectedWine: RecognizedWine?
    @State private var showFilters = false
    @State private var showPaywall = false

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

                // Top Controls
                VStack {
                    TopControlBar(
                        torchEnabled: $viewModel.torchEnabled,
                        scansRemaining: subscriptionService.remainingFreeScans(),
                        isPremium: subscriptionService.subscriptionStatus.isActive
                    )

                    Spacer()
                }
                .padding()

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
