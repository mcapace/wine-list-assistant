import Foundation
import Combine
import AVFoundation

@MainActor
final class ScannerViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var recognizedWines: [RecognizedWine] = []
    @Published var filters = FilterSet()
    @Published var isProcessing = false
    @Published var error: ScannerError?
    @Published var torchEnabled = false {
        didSet {
            cameraService.torchEnabled = torchEnabled
        }
    }

    // MARK: - Services

    let cameraService = CameraService()
    private let ocrService = OCRService()
    private let matchingService: WineMatchingService
    private let subscriptionService = SubscriptionService.shared

    // MARK: - Internal State

    private var cancellables = Set<AnyCancellable>()
    private var frameProcessingTask: Task<Void, Never>?
    private var lastProcessedTime = Date.distantPast
    private let processingInterval: TimeInterval

    // MARK: - Computed Properties

    var filteredWines: [RecognizedWine] {
        filters.apply(to: recognizedWines)
    }

    // MARK: - Initialization

    init() {
        self.matchingService = WineMatchingService()
        self.processingInterval = AppConfiguration.ocrProcessingIntervalSeconds

        setupFrameProcessing()
    }

    // MARK: - Public Methods

    func startScanning() async {
        // Check subscription/free scan limit
        guard subscriptionService.canPerformScan() else {
            error = .scanLimitReached
            return
        }

        // Request camera authorization
        guard await cameraService.requestAuthorization() else {
            error = .cameraNotAuthorized
            return
        }

        // Configure and start camera
        do {
            try cameraService.configure()
            cameraService.start()

            // Record the scan for free users
            subscriptionService.recordScan()
        } catch let cameraError as CameraService.CameraError {
            switch cameraError {
            case .notAuthorized:
                error = .cameraNotAuthorized
            case .configurationFailed, .deviceNotAvailable:
                error = .cameraConfigurationFailed
            case .torchNotAvailable:
                break // Non-fatal
            }
        } catch {
            self.error = .cameraConfigurationFailed
        }
    }

    func stopScanning() {
        cameraService.stop()
        frameProcessingTask?.cancel()
        frameProcessingTask = nil
    }

    func retry() {
        error = nil
        recognizedWines = []
        Task {
            await startScanning()
        }
    }

    func focusAt(_ point: CGPoint) {
        cameraService.focus(at: point)
    }

    // MARK: - Frame Processing

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

        frameProcessingTask = Task { [weak self] in
            await self?.processFrame(frame)
        }
    }

    private func processFrame(_ frame: CVPixelBuffer) async {
        guard !Task.isCancelled else { return }

        isProcessing = true
        defer { isProcessing = false }

        do {
            // Step 1: OCR - recognize text in frame
            let ocrResults = try await ocrService.recognizeText(in: frame)
            guard !Task.isCancelled else { return }
            
            #if DEBUG
            print("🔍 OCR found \(ocrResults.count) text observations")
            #endif

            // Step 2: Group text into wine entry candidates
            let candidates = ocrService.groupIntoWineEntries(ocrResults)
            guard !Task.isCancelled else { return }
            
            #if DEBUG
            print("🍷 Grouped into \(candidates.count) wine candidates")
            for candidate in candidates.prefix(3) {
                print("   - \"\(candidate.fullText)\" (confidence: \(candidate.confidence))")
            }
            #endif

            // Step 3: Match each candidate against our wine database
            var matchedWines: [RecognizedWine] = []

            for candidate in candidates {
                guard !Task.isCancelled else { return }

                let matchResult = await matchingService.matchWine(from: candidate.fullText)
                
                #if DEBUG
                if let match = matchResult {
                    print("✅ Matched: \"\(candidate.fullText)\" → \(match.wine.producer) \(match.wine.name) (confidence: \(match.confidence))")
                } else {
                    print("❌ No match for: \"\(candidate.fullText)\"")
                }
                #endif

                // Only add wines that actually matched (or have high enough confidence)
                // This prevents showing "wines found" for unmatched text
                if let match = matchResult, match.confidence >= AppConfiguration.matchConfidenceThreshold {
                    let recognized = RecognizedWine(
                        id: UUID(),
                        originalText: candidate.fullText,
                        boundingBox: candidate.boundingBox,
                        ocrConfidence: candidate.confidence,
                        matchedWine: match.wine,
                        matchConfidence: match.confidence,
                        matchedVintage: match.matchedVintage,
                        matchType: match.matchType,
                        listPrice: extractPrice(from: candidate.fullText)
                    )

                    matchedWines.append(recognized)
                }
            }
            
            #if DEBUG
            print("📊 Total matched wines this frame: \(matchedWines.count)")
            #endif

            // Update UI on main thread
            await MainActor.run {
                // Merge with existing results to avoid flickering
                let previousCount = self.recognizedWines.filter { $0.isMatched }.count
                self.mergeResults(matchedWines)
                let newCount = self.recognizedWines.filter { $0.isMatched }.count
                
                // Haptic feedback for new matches
                if newCount > previousCount {
                    HapticService.shared.wineMatched()
                }
            }

        } catch {
            print("❌ Frame processing error: \(error)")
        }
    }

    private func mergeResults(_ newResults: [RecognizedWine]) {
        // Simple strategy: replace if positions overlap significantly
        // More sophisticated merging could track wines across frames

        var merged = recognizedWines

        for newWine in newResults {
            // Check if this overlaps with an existing wine
            let existingIndex = merged.firstIndex { existing in
                boxesOverlap(existing.boundingBox, newWine.boundingBox, threshold: 0.5)
            }

            if let index = existingIndex {
                // Update existing if new has higher confidence
                if newWine.matchConfidence > merged[index].matchConfidence {
                    merged[index] = newWine
                }
            } else {
                // Add new wine
                merged.append(newWine)
            }
        }

        // Remove wines not seen in recent frames (they scrolled out of view)
        // This is simplified - production would track frame counts
        recognizedWines = merged
    }

    private func boxesOverlap(_ box1: CGRect, _ box2: CGRect, threshold: Double) -> Bool {
        let intersection = box1.intersection(box2)
        guard !intersection.isNull else { return false }

        let intersectionArea = intersection.width * intersection.height
        let minArea = min(box1.width * box1.height, box2.width * box2.height)

        return intersectionArea / minArea > threshold
    }

    private func extractPrice(from text: String) -> Decimal? {
        let pattern = #"\$\s*([\d,]+(?:\.\d{2})?)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let priceRange = Range(match.range(at: 1), in: text) else {
            return nil
        }

        let priceString = text[priceRange].replacingOccurrences(of: ",", with: "")
        return Decimal(string: String(priceString))
    }

    // MARK: - Error Types

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
    }
}
