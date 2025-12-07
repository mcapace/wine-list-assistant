import Foundation
import Combine
import AVFoundation
import UIKit

@MainActor
final class ScannerViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var recognizedWines: [RecognizedWine] = [] // Current frame wines for AR overlay
    @Published var persistentMatches: [RecognizedWine] = [] // All matched wines from session (never clears automatically)
    @Published var filters = FilterSet()
    @Published var isProcessing = false
    @Published var error: ScannerError?
    @Published var ocrRecoveryMode = false // Track if OCR is in recovery/fast mode
    @Published var torchEnabled = false {
        didSet {
            cameraService.torchEnabled = torchEnabled
        }
    }
    
    // MARK: - Session Management
    
    private var currentSession: ScanSession?
    private let sessionManager = SessionManager.shared

    // MARK: - Services

    let cameraService = CameraService()
    let ocrService = OCRService.shared // Made accessible to check recovery mode
    private let matchingService: WineMatchingService
    private let subscriptionService = SubscriptionService.shared

    // MARK: - Internal State

    private var cancellables = Set<AnyCancellable>()
    private var frameProcessingTask: Task<Void, Never>?
    private var lastProcessedTime = Date.distantPast
    private let processingInterval: TimeInterval
    private var pendingMatchTasks: Set<UUID> = []

    // MARK: - Computed Properties

    var filteredWines: [RecognizedWine] {
        filters.apply(to: recognizedWines)
    }
    
    var sessionMatchCount: Int {
        persistentMatches.count
    }
    
    var matchedPersistentWines: [RecognizedWine] {
        persistentMatches.filter { $0.isMatched }
    }

    // MARK: - Initialization

    init() {
        self.matchingService = WineMatchingService()
        self.processingInterval = AppConfiguration.ocrProcessingIntervalSeconds

        setupFrameProcessing()
        
        // Load incomplete session if exists
        if let session = sessionManager.loadCurrentSession() {
            currentSession = session
            persistentMatches = session.wines
        } else {
            // Start new session
            currentSession = ScanSession()
        }
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
    
    func clearSession() {
        persistentMatches.removeAll()
        recognizedWines.removeAll()
        currentSession = ScanSession()
        sessionManager.clearCurrentSession()
    }
    
    func updateSessionLocation(_ location: String?) {
        currentSession?.location = location
        saveSession()
    }
    
    func saveSessionToHistory() {
        guard var session = currentSession else { return }
        session.wines = persistentMatches
        sessionManager.saveSession(session)
        sessionManager.clearCurrentSession()
        currentSession = ScanSession()
    }
    
    private func saveSession() {
        guard var session = currentSession else { return }
        session.wines = persistentMatches
        sessionManager.saveCurrentSession(session)
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
        // Debounce: Don't process frames faster than every 0.5 seconds
        guard now.timeIntervalSince(lastProcessedTime) >= max(processingInterval, 0.5) else {
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
            // Update recovery mode status
            ocrRecoveryMode = ocrService.isInRecoveryMode
            guard !Task.isCancelled else { return }

            // Step 2: Group text into wine entry candidates
            let candidates = ocrService.groupIntoWineEntries(ocrResults)
            guard !Task.isCancelled else { return }

            // Step 3: Match each candidate against our wine database
            // Use detached tasks to prevent API request cancellation when new frames arrive
            let taskId = UUID()
            pendingMatchTasks.insert(taskId)

            // Capture what we need for the detached task
            let matchingService = self.matchingService

            Task.detached { [weak self] in
                var matchedWines: [RecognizedWine] = []

                for candidate in candidates {
                    // Note: We don't check Task.isCancelled here because this is a
                    // detached task that should complete its API calls
                    let matchResult = await matchingService.matchWine(from: candidate.fullText)
                    
                    // Extract price before creating RecognizedWine to avoid MainActor isolation issues
                    let price = await MainActor.run {
                        self?.extractPrice(from: candidate.fullText)
                    }

                    let recognized = RecognizedWine(
                        id: UUID(),
                        originalText: candidate.fullText,
                        boundingBox: candidate.boundingBox,
                        ocrConfidence: candidate.confidence,
                        matchedWine: matchResult?.wine,
                        matchConfidence: matchResult?.confidence ?? 0,
                        matchedVintage: matchResult?.matchedVintage,
                        matchType: matchResult?.matchType ?? .noMatch,
                        listPrice: price
                    )

                    matchedWines.append(recognized)
                }

                // Update UI on main thread
                await MainActor.run {
                    self?.pendingMatchTasks.remove(taskId)
                    // Merge with existing results to avoid flickering
                    self?.mergeResults(matchedWines)
                }
            }

        } catch {
            // Don't log cancellation errors - they're expected during rapid frame processing
            if !(error is CancellationError) {
                print("Frame processing error: \(error)")
            }
        }
    }

    private func mergeResults(_ newResults: [RecognizedWine]) {
        // Update recognizedWines for current frame (AR overlay bubbles)
        // This uses bounding box overlap to track wines in current view
        var merged = recognizedWines

        for newWine in newResults {
            // Check if this overlaps with an existing wine in current frame
            let existingIndex = merged.firstIndex { existing in
                boxesOverlap(existing.boundingBox, newWine.boundingBox, threshold: 0.5)
            }

            if let index = existingIndex {
                // Update existing if new has higher confidence
                if newWine.matchConfidence > merged[index].matchConfidence {
                    merged[index] = newWine
                }
            } else {
                // Add new wine to current frame
                merged.append(newWine)
            }
        }

        // Update current frame wines (may clear when camera moves)
        recognizedWines = merged
        
        // Add newly matched wines to persistentMatches (deduplicated by wine ID)
        for newWine in newResults {
            // Only add if matched and not already in persistentMatches
            guard newWine.isMatched,
                  let wineId = newWine.matchedWine?.id else {
                continue
            }
            
            // Check if this wine ID already exists in persistentMatches
            let alreadyExists = persistentMatches.contains { existing in
                existing.matchedWine?.id == wineId
            }
            
            if !alreadyExists {
                // New match! Add to persistent list
                persistentMatches.append(newWine)
                
                // Trigger haptic feedback for new match
                // Using UIImpactFeedbackGenerator directly to avoid indexing issues with HapticManager
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                
                // Auto-save session
                saveSession()
            } else {
                // Update existing match if confidence is higher
                if let existingIndex = persistentMatches.firstIndex(where: { $0.matchedWine?.id == wineId }) {
                    if newWine.matchConfidence > persistentMatches[existingIndex].matchConfidence {
                        persistentMatches[existingIndex] = newWine
                        saveSession()
                    }
                }
            }
        }
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
