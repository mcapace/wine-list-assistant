# iOS Technical Specification
## Wine List Assistant - iOS App

---

## Overview

This document details the technical implementation for the iOS version of the Wine List Assistant app. The app uses native iOS frameworks for optimal performance in OCR, AR overlay, and camera operations.

---

## System Requirements

### Minimum Requirements
- iOS 16.0+
- iPhone 11 or newer (for adequate camera/AR performance)
- A12 Bionic chip or newer (for Neural Engine OCR)
- 100MB storage (app + local cache)

### Recommended
- iOS 17.0+
- iPhone 13 or newer
- 200MB storage

---

## Project Structure

```
WineListAssistant/
├── App/
│   ├── WineListAssistantApp.swift      # App entry point
│   ├── AppDelegate.swift                # Legacy delegate if needed
│   └── Configuration/
│       ├── AppConfiguration.swift       # Environment config
│       └── Constants.swift              # App-wide constants
│
├── Features/
│   ├── Scanner/
│   │   ├── Views/
│   │   │   ├── ScannerView.swift        # Main scanner screen
│   │   │   ├── CameraPreviewView.swift  # Camera feed display
│   │   │   ├── AROverlayView.swift      # Score badges overlay
│   │   │   └── FilterControlsView.swift # Filter buttons
│   │   ├── ViewModels/
│   │   │   └── ScannerViewModel.swift   # Scanner business logic
│   │   └── Services/
│   │       ├── CameraService.swift      # AVFoundation wrapper
│   │       ├── OCRService.swift         # Vision OCR processing
│   │       └── AROverlayService.swift   # Overlay positioning
│   │
│   ├── WineDetail/
│   │   ├── Views/
│   │   │   ├── WineDetailSheet.swift    # Detail modal
│   │   │   ├── TastingNoteView.swift    # Tasting note card
│   │   │   └── WineMetadataView.swift   # Score, price, etc.
│   │   └── ViewModels/
│   │       └── WineDetailViewModel.swift
│   │
│   ├── MyWines/
│   │   ├── Views/
│   │   │   ├── MyWinesView.swift        # Saved wines list
│   │   │   └── WineRowView.swift        # List row component
│   │   └── ViewModels/
│   │       └── MyWinesViewModel.swift
│   │
│   ├── Settings/
│   │   ├── Views/
│   │   │   ├── SettingsView.swift
│   │   │   └── SubscriptionView.swift
│   │   └── ViewModels/
│   │       └── SettingsViewModel.swift
│   │
│   └── Onboarding/
│       ├── Views/
│       │   └── OnboardingView.swift
│       └── OnboardingManager.swift
│
├── Core/
│   ├── Models/
│   │   ├── Wine.swift                   # Wine entity
│   │   ├── Review.swift                 # Review entity
│   │   ├── RecognizedWine.swift         # OCR result + match
│   │   ├── ScanResult.swift             # Full scan output
│   │   └── User.swift                   # User model
│   │
│   ├── Services/
│   │   ├── WineMatchingService.swift    # Fuzzy matching logic
│   │   ├── WineAPIClient.swift          # Network layer
│   │   ├── AuthenticationService.swift  # Auth management
│   │   ├── SubscriptionService.swift    # StoreKit integration
│   │   └── AnalyticsService.swift       # Event tracking
│   │
│   ├── Persistence/
│   │   ├── LocalWineCache.swift         # SwiftData/CoreData
│   │   ├── UserPreferences.swift        # UserDefaults wrapper
│   │   └── KeychainManager.swift        # Secure storage
│   │
│   └── Extensions/
│       ├── String+Wine.swift            # Wine name parsing
│       ├── Color+Theme.swift            # App colors
│       └── View+Extensions.swift        # SwiftUI helpers
│
├── Design/
│   ├── Theme.swift                      # Design tokens
│   ├── Components/
│   │   ├── ScoreBadge.swift             # Score display badge
│   │   ├── PrimaryButton.swift          # Button styles
│   │   └── LoadingView.swift            # Loading states
│   └── Assets.xcassets                  # Images, colors
│
└── Resources/
    ├── Localizable.strings              # Localization
    ├── top_wines_cache.json             # Embedded wine cache
    └── Info.plist
```

---

## Core Components

### 1. Camera & OCR Pipeline

#### CameraService.swift

```swift
import AVFoundation
import Combine

@MainActor
final class CameraService: NSObject, ObservableObject {
    @Published var currentFrame: CVPixelBuffer?
    @Published var isAuthorized: Bool = false
    @Published var error: CameraError?

    private let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "camera.session")

    enum CameraError: Error {
        case notAuthorized
        case configurationFailed
        case deviceNotAvailable
    }

    func requestAuthorization() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            isAuthorized = true
            return true
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            isAuthorized = granted
            return granted
        default:
            isAuthorized = false
            return false
        }
    }

    func configure() throws {
        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }

        captureSession.sessionPreset = .high

        guard let device = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .back
        ) else {
            throw CameraError.deviceNotAvailable
        }

        // Optimize for low light
        try device.lockForConfiguration()
        if device.isLowLightBoostSupported {
            device.automaticallyEnablesLowLightBoostWhenAvailable = true
        }
        device.unlockForConfiguration()

        let input = try AVCaptureDeviceInput(device: device)
        guard captureSession.canAddInput(input) else {
            throw CameraError.configurationFailed
        }
        captureSession.addInput(input)

        videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)
        videoOutput.alwaysDiscardsLateVideoFrames = true

        guard captureSession.canAddOutput(videoOutput) else {
            throw CameraError.configurationFailed
        }
        captureSession.addOutput(videoOutput)
    }

    func start() {
        sessionQueue.async { [weak self] in
            self?.captureSession.startRunning()
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            self?.captureSession.stopRunning()
        }
    }
}

extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        Task { @MainActor in
            self.currentFrame = pixelBuffer
        }
    }
}
```

#### OCRService.swift

```swift
import Vision
import CoreImage

final class OCRService {

    struct OCRResult {
        let text: String
        let boundingBox: CGRect  // Normalized coordinates (0-1)
        let confidence: Float
    }

    private let textRecognitionRequest: VNRecognizeTextRequest
    private let requestHandler: VNSequenceRequestHandler

    init() {
        textRecognitionRequest = VNRecognizeTextRequest()
        textRecognitionRequest.recognitionLevel = .accurate
        textRecognitionRequest.recognitionLanguages = ["en-US", "fr-FR", "it-IT", "es-ES", "de-DE"]
        textRecognitionRequest.usesLanguageCorrection = true

        requestHandler = VNSequenceRequestHandler()
    }

    func recognizeText(in pixelBuffer: CVPixelBuffer) async throws -> [OCRResult] {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: [])
                    return
                }

                let results = observations.compactMap { observation -> OCRResult? in
                    guard let candidate = observation.topCandidates(1).first else {
                        return nil
                    }
                    return OCRResult(
                        text: candidate.string,
                        boundingBox: observation.boundingBox,
                        confidence: candidate.confidence
                    )
                }

                continuation.resume(returning: results)
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            do {
                try requestHandler.perform([request], on: pixelBuffer)
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    /// Group OCR results into likely wine entries
    func groupIntoWineEntries(_ results: [OCRResult]) -> [WineTextCandidate] {
        // Wine entries typically span 1-3 lines:
        // Line 1: Producer / Wine Name
        // Line 2: Vintage, Region (optional)
        // Line 3: Price

        var candidates: [WineTextCandidate] = []
        var currentGroup: [OCRResult] = []
        var lastBottom: CGFloat = 0

        let sortedResults = results.sorted { $0.boundingBox.minY > $1.boundingBox.minY }

        for result in sortedResults {
            let gap = lastBottom - result.boundingBox.maxY

            // If gap is small, same entry; if large, new entry
            if gap < 0.02 || currentGroup.isEmpty {
                currentGroup.append(result)
            } else {
                if !currentGroup.isEmpty {
                    candidates.append(WineTextCandidate(from: currentGroup))
                }
                currentGroup = [result]
            }
            lastBottom = result.boundingBox.minY
        }

        if !currentGroup.isEmpty {
            candidates.append(WineTextCandidate(from: currentGroup))
        }

        return candidates
    }
}

struct WineTextCandidate {
    let fullText: String
    let boundingBox: CGRect
    let confidence: Float

    init(from results: [OCRService.OCRResult]) {
        fullText = results.map(\.text).joined(separator: " ")

        // Compute combined bounding box
        let minX = results.map(\.boundingBox.minX).min() ?? 0
        let minY = results.map(\.boundingBox.minY).min() ?? 0
        let maxX = results.map(\.boundingBox.maxX).max() ?? 1
        let maxY = results.map(\.boundingBox.maxY).max() ?? 1
        boundingBox = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)

        confidence = results.map(\.confidence).reduce(0, +) / Float(results.count)
    }
}
```

### 2. Wine Matching Service

#### WineMatchingService.swift

```swift
import Foundation

final class WineMatchingService {

    struct MatchResult {
        let wine: Wine
        let confidence: Double  // 0.0 - 1.0
        let matchedVintage: Int?
        let matchType: MatchType

        enum MatchType {
            case exact
            case fuzzyName
            case fuzzyProducer
            case vintageVariant
        }
    }

    private let localCache: LocalWineCache
    private let apiClient: WineAPIClient

    init(localCache: LocalWineCache, apiClient: WineAPIClient) {
        self.localCache = localCache
        self.apiClient = apiClient
    }

    func matchWine(from candidate: WineTextCandidate) async -> MatchResult? {
        let normalizedText = normalizeWineText(candidate.fullText)
        let components = parseWineComponents(normalizedText)

        // Step 1: Try exact match in local cache
        if let exactMatch = localCache.findExact(
            producer: components.producer,
            name: components.wineName,
            vintage: components.vintage
        ) {
            return MatchResult(
                wine: exactMatch,
                confidence: 0.98,
                matchedVintage: components.vintage,
                matchType: .exact
            )
        }

        // Step 2: Try fuzzy match in local cache
        if let fuzzyMatch = localCache.findFuzzy(normalizedText: normalizedText) {
            return MatchResult(
                wine: fuzzyMatch.wine,
                confidence: fuzzyMatch.score,
                matchedVintage: components.vintage,
                matchType: .fuzzyName
            )
        }

        // Step 3: Query API for broader search
        do {
            let apiResults = try await apiClient.searchWines(query: normalizedText)
            if let bestMatch = apiResults.first {
                return MatchResult(
                    wine: bestMatch.wine,
                    confidence: bestMatch.confidence,
                    matchedVintage: components.vintage,
                    matchType: .fuzzyName
                )
            }
        } catch {
            // Log error, continue with no match
            print("API search failed: \(error)")
        }

        return nil
    }

    // MARK: - Text Normalization

    private func normalizeWineText(_ text: String) -> String {
        var normalized = text
            .lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)

        // Expand common abbreviations
        let abbreviations: [String: String] = [
            "ch.": "chateau",
            "ch ": "chateau ",
            "dom.": "domaine",
            "dom ": "domaine ",
            "cht.": "chateau",
            "cab": "cabernet",
            "sauv": "sauvignon",
            "chard": "chardonnay",
            "sb": "sauvignon blanc",
            "cs": "cabernet sauvignon",
            "pn": "pinot noir",
            "zin": "zinfandel",
            "rsv": "reserve",
            "res": "reserve",
            "vyd": "vineyard",
            "vnyd": "vineyard",
            "est": "estate",
            "btl": "bottle",
            "gls": "glass",
            "nv": "non-vintage"
        ]

        for (abbrev, full) in abbreviations {
            normalized = normalized.replacingOccurrences(of: abbrev, with: full)
        }

        // Standardize vintage format
        // '19 -> 2019, '98 -> 1998
        let vintagePattern = #"'(\d{2})(?!\d)"#
        if let regex = try? NSRegularExpression(pattern: vintagePattern) {
            let range = NSRange(normalized.startIndex..., in: normalized)
            normalized = regex.stringByReplacingMatches(
                in: normalized,
                range: range,
                withTemplate: { (match: NSTextCheckingResult) -> String in
                    guard let yearRange = Range(match.range(at: 1), in: normalized) else {
                        return ""
                    }
                    let year = Int(normalized[yearRange]) ?? 0
                    let fullYear = year > 50 ? 1900 + year : 2000 + year
                    return String(fullYear)
                }
            )
        }

        // Remove price patterns
        normalized = normalized.replacingOccurrences(
            of: #"\$[\d,]+(?:\.\d{2})?"#,
            with: "",
            options: .regularExpression
        )

        // Remove extra whitespace
        normalized = normalized.replacingOccurrences(
            of: #"\s+"#,
            with: " ",
            options: .regularExpression
        ).trimmingCharacters(in: .whitespaces)

        return normalized
    }

    private func parseWineComponents(_ text: String) -> WineComponents {
        // Extract vintage (4-digit year between 1900-2030)
        let vintagePattern = #"\b(19[5-9]\d|20[0-3]\d)\b"#
        var vintage: Int?
        if let regex = try? NSRegularExpression(pattern: vintagePattern),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let range = Range(match.range, in: text) {
            vintage = Int(text[range])
        }

        // TODO: More sophisticated NLP for producer/wine name extraction
        // For now, use full text as search query

        return WineComponents(
            producer: nil,
            wineName: nil,
            vintage: vintage,
            fullText: text
        )
    }
}

struct WineComponents {
    let producer: String?
    let wineName: String?
    let vintage: Int?
    let fullText: String
}
```

### 3. AR Overlay System

#### AROverlayView.swift

```swift
import SwiftUI

struct AROverlayView: View {
    let recognizedWines: [RecognizedWine]
    let viewSize: CGSize
    let onWineTapped: (RecognizedWine) -> Void

    var body: some View {
        ZStack {
            ForEach(recognizedWines) { wine in
                ScoreBadgeOverlay(
                    wine: wine,
                    position: convertToViewCoordinates(wine.boundingBox),
                    onTap: { onWineTapped(wine) }
                )
            }
        }
    }

    private func convertToViewCoordinates(_ normalizedBox: CGRect) -> CGPoint {
        // Vision coordinates: origin bottom-left, y increases upward
        // SwiftUI coordinates: origin top-left, y increases downward
        CGPoint(
            x: normalizedBox.midX * viewSize.width,
            y: (1 - normalizedBox.midY) * viewSize.height
        )
    }
}

struct ScoreBadgeOverlay: View {
    let wine: RecognizedWine
    let position: CGPoint
    let onTap: () -> Void

    @State private var isAppearing = false

    var body: some View {
        ScoreBadge(
            score: wine.matchedWine?.score,
            confidence: wine.matchConfidence,
            vintage: wine.matchedVintage
        )
        .position(position)
        .scaleEffect(isAppearing ? 1.0 : 0.5)
        .opacity(isAppearing ? 1.0 : 0.0)
        .onTapGesture(perform: onTap)
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isAppearing = true
            }
        }
    }
}

struct ScoreBadge: View {
    let score: Int?
    let confidence: Double
    let vintage: Int?

    private var scoreColor: Color {
        guard let score = score else { return .gray }
        switch score {
        case 95...100: return .purple     // Outstanding
        case 90...94: return .green       // Excellent
        case 85...89: return .yellow      // Very Good
        case 80...84: return .orange      // Good
        default: return .red              // Below average
        }
    }

    private var displayText: String {
        guard let score = score else { return "?" }
        if let vintage = vintage {
            return "\(score) '\(vintage % 100)"
        }
        return "\(score)"
    }

    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 8)
                .fill(scoreColor)
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)

            // Score text
            Text(displayText)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)

            // Low confidence indicator
            if confidence < 0.8 {
                Circle()
                    .fill(.white.opacity(0.8))
                    .frame(width: 8, height: 8)
                    .offset(x: 20, y: -12)
            }
        }
        .fixedSize()
    }
}
```

### 4. Main Scanner View

#### ScannerView.swift

```swift
import SwiftUI
import AVFoundation

struct ScannerView: View {
    @StateObject private var viewModel = ScannerViewModel()
    @State private var selectedWine: RecognizedWine?
    @State private var showFilters = false

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

                // Filter Controls
                VStack {
                    Spacer()
                    FilterBar(
                        activeFilters: $viewModel.activeFilters,
                        isExpanded: $showFilters
                    )
                    .padding()
                }

                // Scanning indicator
                if viewModel.isProcessing {
                    ScanningIndicator()
                }

                // Error state
                if let error = viewModel.error {
                    ErrorOverlay(error: error, onRetry: viewModel.retry)
                }
            }
        }
        .sheet(item: $selectedWine) { wine in
            WineDetailSheet(wine: wine)
        }
        .onAppear {
            Task {
                await viewModel.startScanning()
            }
        }
        .onDisappear {
            viewModel.stopScanning()
        }
    }
}

struct FilterBar: View {
    @Binding var activeFilters: Set<WineFilter>
    @Binding var isExpanded: Bool

    var body: some View {
        VStack(spacing: 12) {
            // Quick filters
            HStack(spacing: 12) {
                FilterButton(
                    title: "90+",
                    isActive: activeFilters.contains(.score90Plus),
                    action: { toggleFilter(.score90Plus) }
                )

                FilterButton(
                    title: "Ready Now",
                    isActive: activeFilters.contains(.drinkNow),
                    action: { toggleFilter(.drinkNow) }
                )

                FilterButton(
                    title: "Best Value",
                    isActive: activeFilters.contains(.bestValue),
                    action: { toggleFilter(.bestValue) }
                )

                Button(action: { isExpanded.toggle() }) {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Circle())
                }
            }

            if isExpanded {
                // Extended filters
                ExpandedFiltersView(activeFilters: $activeFilters)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }

    private func toggleFilter(_ filter: WineFilter) {
        if activeFilters.contains(filter) {
            activeFilters.remove(filter)
        } else {
            activeFilters.insert(filter)
        }
    }
}

struct FilterButton: View {
    let title: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isActive ? .black : .white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isActive ? Color.white : Color.black.opacity(0.6))
                )
        }
    }
}

enum WineFilter: Hashable {
    case score90Plus
    case score85Plus
    case drinkNow
    case bestValue
    case redOnly
    case whiteOnly
}
```

### 5. Scanner ViewModel

#### ScannerViewModel.swift

```swift
import Foundation
import Combine
import AVFoundation

@MainActor
final class ScannerViewModel: ObservableObject {
    // Published state
    @Published var recognizedWines: [RecognizedWine] = []
    @Published var activeFilters: Set<WineFilter> = []
    @Published var isProcessing = false
    @Published var error: ScannerError?

    // Services
    let cameraService = CameraService()
    private let ocrService = OCRService()
    private let matchingService: WineMatchingService

    // Internal state
    private var cancellables = Set<AnyCancellable>()
    private var frameProcessingTask: Task<Void, Never>?
    private var lastProcessedTime = Date.distantPast
    private let processingInterval: TimeInterval = 0.5  // Process every 500ms

    var filteredWines: [RecognizedWine] {
        guard !activeFilters.isEmpty else { return recognizedWines }

        return recognizedWines.filter { wine in
            guard let matched = wine.matchedWine else { return false }

            for filter in activeFilters {
                switch filter {
                case .score90Plus:
                    if matched.score < 90 { return false }
                case .score85Plus:
                    if matched.score < 85 { return false }
                case .drinkNow:
                    if !matched.isReadyToDrink { return false }
                case .bestValue:
                    if !wine.isBestValue { return false }
                case .redOnly:
                    if matched.color != .red { return false }
                case .whiteOnly:
                    if matched.color != .white { return false }
                }
            }
            return true
        }
    }

    init() {
        let cache = LocalWineCache.shared
        let apiClient = WineAPIClient.shared
        self.matchingService = WineMatchingService(localCache: cache, apiClient: apiClient)

        setupFrameProcessing()
    }

    func startScanning() async {
        guard await cameraService.requestAuthorization() else {
            error = .cameraNotAuthorized
            return
        }

        do {
            try cameraService.configure()
            cameraService.start()
        } catch {
            self.error = .cameraConfigurationFailed
        }
    }

    func stopScanning() {
        cameraService.stop()
        frameProcessingTask?.cancel()
    }

    func retry() {
        error = nil
        Task {
            await startScanning()
        }
    }

    private func setupFrameProcessing() {
        cameraService.$currentFrame
            .compactMap { $0 }
            .sink { [weak self] frame in
                self?.processFrameIfNeeded(frame)
            }
            .store(in: &cancellables)
    }

    private func processFrameIfNeeded(_ frame: CVPixelBuffer) {
        let now = Date()
        guard now.timeIntervalSince(lastProcessedTime) >= processingInterval else {
            return
        }
        lastProcessedTime = now

        // Cancel any existing processing
        frameProcessingTask?.cancel()

        frameProcessingTask = Task {
            await processFrame(frame)
        }
    }

    private func processFrame(_ frame: CVPixelBuffer) async {
        guard !Task.isCancelled else { return }

        isProcessing = true
        defer { isProcessing = false }

        do {
            // Step 1: OCR
            let ocrResults = try await ocrService.recognizeText(in: frame)
            guard !Task.isCancelled else { return }

            // Step 2: Group into wine candidates
            let candidates = ocrService.groupIntoWineEntries(ocrResults)
            guard !Task.isCancelled else { return }

            // Step 3: Match each candidate
            var matched: [RecognizedWine] = []
            for candidate in candidates {
                guard !Task.isCancelled else { return }

                if let match = await matchingService.matchWine(from: candidate) {
                    let recognized = RecognizedWine(
                        id: UUID(),
                        originalText: candidate.fullText,
                        boundingBox: candidate.boundingBox,
                        matchedWine: match.wine,
                        matchConfidence: match.confidence,
                        matchedVintage: match.matchedVintage
                    )
                    matched.append(recognized)
                }
            }

            // Update UI
            await MainActor.run {
                self.recognizedWines = matched
            }

        } catch {
            print("Frame processing error: \(error)")
        }
    }
}

enum ScannerError: Error, Identifiable {
    case cameraNotAuthorized
    case cameraConfigurationFailed
    case processingFailed

    var id: String { String(describing: self) }

    var title: String {
        switch self {
        case .cameraNotAuthorized:
            return "Camera Access Required"
        case .cameraConfigurationFailed:
            return "Camera Error"
        case .processingFailed:
            return "Processing Error"
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
        }
    }
}
```

---

## Data Models

### Wine.swift

```swift
import Foundation

struct Wine: Identifiable, Codable, Hashable {
    let id: String
    let producer: String
    let name: String
    let vintage: Int?
    let region: String
    let country: String
    let color: WineColor
    let grapeVarieties: [String]
    let score: Int
    let tastingNote: String
    let reviewerInitials: String
    let drinkWindowStart: Int?
    let drinkWindowEnd: Int?
    let releasePrice: Decimal?
    let reviewDate: Date

    var isReadyToDrink: Bool {
        guard let start = drinkWindowStart else { return true }
        let currentYear = Calendar.current.component(.year, from: Date())
        return currentYear >= start
    }

    var isPastPrime: Bool {
        guard let end = drinkWindowEnd else { return false }
        let currentYear = Calendar.current.component(.year, from: Date())
        return currentYear > end
    }

    var drinkWindowDisplay: String {
        switch (drinkWindowStart, drinkWindowEnd) {
        case (nil, nil):
            return "No drink window"
        case (let start?, nil):
            return "From \(start)"
        case (nil, let end?):
            return "Until \(end)"
        case (let start?, let end?):
            return "\(start)-\(end)"
        }
    }

    var fullName: String {
        if let vintage = vintage {
            return "\(producer) \(name) \(vintage)"
        }
        return "\(producer) \(name)"
    }
}

enum WineColor: String, Codable {
    case red
    case white
    case rose
    case sparkling
    case dessert
    case fortified
}
```

### RecognizedWine.swift

```swift
import Foundation

struct RecognizedWine: Identifiable {
    let id: UUID
    let originalText: String
    let boundingBox: CGRect
    let matchedWine: Wine?
    let matchConfidence: Double
    let matchedVintage: Int?

    var isBestValue: Bool {
        // TODO: Implement value calculation based on score:price ratio
        guard let wine = matchedWine, let _ = wine.releasePrice else {
            return false
        }
        return wine.score >= 90 // Simplified for now
    }
}
```

---

## API Integration

### WineAPIClient.swift

```swift
import Foundation

final class WineAPIClient {
    static let shared = WineAPIClient()

    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder

    private init() {
        baseURL = URL(string: AppConfiguration.apiBaseURL)!

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 30
        session = URLSession(configuration: config)

        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    // MARK: - Search

    struct SearchResult {
        let wine: Wine
        let confidence: Double
    }

    func searchWines(query: String, limit: Int = 10) async throws -> [SearchResult] {
        var components = URLComponents(url: baseURL.appendingPathComponent("v1/wines/search"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "fuzzy", value: "true"),
            URLQueryItem(name: "limit", value: String(limit))
        ]

        let request = try authorizedRequest(url: components.url!)
        let (data, _) = try await session.data(for: request)

        let response = try decoder.decode(SearchResponse.self, from: data)
        return response.results.map { SearchResult(wine: $0.wine, confidence: $0.confidence) }
    }

    // MARK: - Wine Details

    func getWine(id: String) async throws -> Wine {
        let url = baseURL.appendingPathComponent("v1/wines/\(id)")
        let request = try authorizedRequest(url: url)
        let (data, _) = try await session.data(for: request)
        return try decoder.decode(Wine.self, from: data)
    }

    // MARK: - Batch Match (B2B)

    func batchMatch(texts: [String]) async throws -> [String: Wine?] {
        let url = baseURL.appendingPathComponent("v1/wines/batch-match")
        var request = try authorizedRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["queries": texts])

        let (data, _) = try await session.data(for: request)
        let response = try decoder.decode(BatchMatchResponse.self, from: data)
        return response.matches
    }

    // MARK: - Helpers

    private func authorizedRequest(url: URL) throws -> URLRequest {
        var request = URLRequest(url: url)

        if let token = AuthenticationService.shared.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        request.setValue(AppConfiguration.apiKey, forHTTPHeaderField: "X-API-Key")

        return request
    }
}

// MARK: - Response Types

private struct SearchResponse: Codable {
    struct Result: Codable {
        let wine: Wine
        let confidence: Double
    }
    let results: [Result]
}

private struct BatchMatchResponse: Codable {
    let matches: [String: Wine?]
}
```

---

## Subscription & Monetization

### SubscriptionService.swift

```swift
import StoreKit

@MainActor
final class SubscriptionService: ObservableObject {
    static let shared = SubscriptionService()

    @Published var subscriptionStatus: SubscriptionStatus = .unknown
    @Published var products: [Product] = []

    private var updateTask: Task<Void, Never>?

    enum SubscriptionStatus {
        case unknown
        case notSubscribed
        case subscribed(expirationDate: Date?)
        case expired
    }

    enum ProductID: String, CaseIterable {
        case monthlyPremium = "com.winespectator.winelistassistant.premium.monthly"
        case yearlyPremium = "com.winespectator.winelistassistant.premium.yearly"
    }

    private init() {
        updateTask = Task {
            await observeTransactionUpdates()
        }
    }

    deinit {
        updateTask?.cancel()
    }

    func loadProducts() async {
        do {
            let productIDs = ProductID.allCases.map(\.rawValue)
            products = try await Product.products(for: productIDs)
        } catch {
            print("Failed to load products: \(error)")
        }
    }

    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updateSubscriptionStatus()
            await transaction.finish()
            return true

        case .userCancelled:
            return false

        case .pending:
            return false

        @unknown default:
            return false
        }
    }

    func restorePurchases() async {
        try? await AppStore.sync()
        await updateSubscriptionStatus()
    }

    func updateSubscriptionStatus() async {
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else {
                continue
            }

            if transaction.productType == .autoRenewable {
                subscriptionStatus = .subscribed(expirationDate: transaction.expirationDate)
                return
            }
        }

        subscriptionStatus = .notSubscribed
    }

    private func observeTransactionUpdates() async {
        for await result in Transaction.updates {
            guard case .verified(let transaction) = result else {
                continue
            }
            await updateSubscriptionStatus()
            await transaction.finish()
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.verificationFailed
        case .verified(let value):
            return value
        }
    }

    enum StoreError: Error {
        case verificationFailed
    }
}
```

---

## Testing Strategy

### Unit Tests
- Wine name normalization
- Fuzzy matching algorithm
- Filter logic
- Data model encoding/decoding

### Integration Tests
- API client with mock server
- OCR → Matching pipeline
- Subscription verification

### UI Tests
- Scanner flow end-to-end
- Filter application
- Wine detail sheet

### Performance Tests
- OCR processing speed (target: <500ms)
- Matching speed (target: <100ms per wine)
- Memory usage during scanning
- Battery consumption

### Real-World Testing
- Test with 100+ actual restaurant wine lists
- Various lighting conditions
- Different phone angles
- Multiple languages (French, Italian, Spanish wine names)

---

## Analytics Events

```swift
enum AnalyticsEvent {
    case appLaunched
    case scanStarted
    case scanCompleted(winesFound: Int, matchRate: Double)
    case wineDetailViewed(wineId: String, fromScan: Bool)
    case filterApplied(filter: String)
    case wineSaved(wineId: String)
    case subscriptionViewed
    case subscriptionStarted(productId: String)
    case searchPerformed(query: String, resultsCount: Int)
    case errorOccurred(type: String, message: String)
}
```

---

## Privacy & Security

### Data Collection
- Camera feed processed on-device (not uploaded)
- Scanned text sent to API only for matching
- No storage of scanned wine lists on server
- Analytics anonymized

### Required Permissions
- Camera (mandatory)
- Internet (mandatory)
- Photo Library (optional, for saving scans)

### App Privacy Label (App Store)
- Data Used to Track You: None
- Data Linked to You: Email, Purchase History
- Data Not Linked to You: Usage Data, Diagnostics

---

*Document Version: 1.0*
*iOS Target: 16.0+*
*Last Updated: December 2024*
