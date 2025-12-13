import Foundation
import Combine
import AVFoundation
import UIKit

// NOTE: Removed @MainActor to fix deadlock during SwiftUI view initialization
// @Published handles thread safety, and SwiftUI always accesses from main thread
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
    @Published var isAutoScanning = true // Auto-scan vs manual photo mode

    // MARK: - Session Management

    private var currentSession: ScanSession?
    // MOVED TO INIT: private let sessionManager = SessionManager.shared
    private let sessionManager: SessionManager

    // MARK: - Services
    // ALL services are now initialized in init() to avoid property initializer blocking

    let cameraService: CameraService
    // MOVED TO INIT: let ocrService = OCRService.shared
    let ocrService: OCRService
    private let matchingService: WineMatchingService
    // MOVED TO INIT: private let subscriptionService = SubscriptionService.shared
    private let subscriptionService: SubscriptionService

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
        // CRITICAL: Print immediately as first line - before anything else
        #if DEBUG
        print("🎬 ScannerViewModel.init() - START - THIS SHOULD APPEAR IMMEDIATELY")
        #endif

        // Initialize ALL services in init() to avoid property initializer blocking
        #if DEBUG
        print("🎬 ScannerViewModel.init() - Step 0a: getting SessionManager.shared...")
        #endif
        self.sessionManager = SessionManager.shared

        #if DEBUG
        print("🎬 ScannerViewModel.init() - Step 0b: getting OCRService.shared...")
        #endif
        self.ocrService = OCRService.shared

        #if DEBUG
        print("🎬 ScannerViewModel.init() - Step 0c: getting SubscriptionService.shared...")
        #endif
        self.subscriptionService = SubscriptionService.shared

        #if DEBUG
        print("🎬 ScannerViewModel.init() - Step 0d: creating CameraService...")
        #endif
        self.cameraService = CameraService()
        #if DEBUG
        print("🎬 ScannerViewModel.init() - Step 0d: CameraService created")
        #endif

        // Access properties in order with logging between each
        #if DEBUG
        print("🎬 ScannerViewModel.init() - Step 1: creating WineMatchingService...")
        #endif
        self.matchingService = WineMatchingService()
        #if DEBUG
        print("🎬 ScannerViewModel.init() - Step 1: WineMatchingService created")
        #endif

        #if DEBUG
        print("🎬 ScannerViewModel.init() - Step 2: getting processingInterval...")
        #endif
        self.processingInterval = AppConfiguration.ocrProcessingIntervalSeconds
        #if DEBUG
        print("🎬 ScannerViewModel.init() - Step 2: processingInterval = \(self.processingInterval)")
        #endif

        #if DEBUG
        print("🎬 ScannerViewModel.init() - Step 3: deferring setupFrameProcessing to async task...")
        #endif

        // Defer frame processing setup to avoid blocking init
        Task { @MainActor [weak self] in
            #if DEBUG
            print("🎬 ScannerViewModel.init() - async task: calling setupFrameProcessing...")
            #endif
            self?.setupFrameProcessing()
        }

        #if DEBUG
        print("🎬 ScannerViewModel.init() - Step 4: loading session...")
        #endif
        // Load incomplete session if exists - wrap in do-catch for safety
        do {
            if let session = sessionManager.loadCurrentSession() {
                currentSession = session
                persistentMatches = session.wines
                #if DEBUG
                print("🎬 ScannerViewModel.init() - Step 4: loaded existing session with \(session.wines.count) wines")
                #endif
            } else {
                currentSession = ScanSession()
                #if DEBUG
                print("🎬 ScannerViewModel.init() - Step 4: created new session")
                #endif
            }
        } catch {
            #if DEBUG
            print("⚠️ ScannerViewModel.init() - Step 4: Error loading session: \(error), creating new session")
            #endif
            currentSession = ScanSession()
        }

        #if DEBUG
        print("🎬 ScannerViewModel.init() - COMPLETE - All steps finished")
        #endif
    }

    // MARK: - Public Methods

    func startScanning() async {
        #if DEBUG
        print("🚀 ScannerViewModel.startScanning() called")
        #endif
        
        // Clear any previous errors
        error = nil
        
        // Check subscription/free scan limit (but don't block camera initialization for testing)
        // Commenting out temporarily to ensure camera always works
        // guard subscriptionService.canPerformScan() else {
        //     error = .scanLimitReached
        //     return
        // }

        // Request camera authorization - this will show the permission dialog if needed
        #if DEBUG
        print("🔐 ScannerViewModel: Requesting camera authorization...")
        #endif
        let authorized = await cameraService.requestAuthorization()
        
        guard authorized else {
            #if DEBUG
            print("❌ ScannerViewModel: Camera authorization failed")
            #endif
            // Check current authorization status for better error message
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            if status == .denied || status == .restricted {
                error = .cameraNotAuthorized
            } else {
                // Not determined - this shouldn't happen if requestAuthorization was called correctly
                error = .cameraNotAuthorized
            }
            return
        }

        #if DEBUG
        print("✅ ScannerViewModel: Camera authorized, configuring...")
        #endif

        // Configure and start camera
        do {
            try await cameraService.configure()
            cameraService.start()
            
            #if DEBUG
            print("✅ ScannerViewModel: Camera started successfully")
            #endif

            // Record the scan for free users (only if subscription check passes)
            let canScan = await MainActor.run { subscriptionService.canPerformScan() }
            if canScan {
                await MainActor.run { subscriptionService.recordScan() }
            }
        } catch let cameraError as CameraService.CameraError {
            #if DEBUG
            print("❌ ScannerViewModel: Camera error: \(cameraError)")
            #endif
            switch cameraError {
            case .notAuthorized:
                error = .cameraNotAuthorized
            case .configurationFailed, .deviceNotAvailable:
                error = .cameraConfigurationFailed
            case .torchNotAvailable:
                break // Non-fatal
            }
        } catch {
            #if DEBUG
            print("❌ ScannerViewModel: Unexpected error: \(error)")
            #endif
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
    
    // MARK: - Manual Photo Capture
    
    func capturePhoto() async {
        #if DEBUG
        print("📸 capturePhoto: Called - isAutoScanning=\(isAutoScanning)")
        #endif
        
        // Allow manual capture even if auto-scanning is enabled (user can force a capture)
        guard let pixelBuffer = cameraService.currentFrame else {
            #if DEBUG
            print("📸 capturePhoto: No frame available")
            #endif
            return
        }
        
        isProcessing = true
        defer { isProcessing = false }
        
        #if DEBUG
        print("📸 capturePhoto: Processing captured frame...")
        #endif
        
        await processFrame(pixelBuffer)
    }

    // MARK: - Upload Image Processing

    func processUploadedImage(_ image: UIImage) async {
        #if DEBUG
        print("📷 processUploadedImage: Called with image size \(image.size)")
        #endif

        isProcessing = true
        defer { isProcessing = false }

        do {
            // Use OCR service to recognize text in the uploaded image
            let ocrResults = try await ocrService.recognizeText(in: image)

            #if DEBUG
            print("📷 processUploadedImage: OCR returned \(ocrResults.count) results")
            #endif

            // Group text into wine entry candidates
            let candidates = ocrService.groupIntoWineEntries(ocrResults)

            #if DEBUG
            print("📷 processUploadedImage: Grouped into \(candidates.count) wine candidates")
            #endif

            // Match each candidate against our wine database
            var matchedWines: [RecognizedWine] = []

            for (index, candidate) in candidates.enumerated() {
                let matchResult = await matchingService.matchWine(from: candidate.fullText)

                if let match = matchResult {
                    #if DEBUG
                    print("✅ Upload Match[\(index)]: '\(match.wine.name)' score=\(match.wine.score ?? 0)")
                    #endif
                }

                let price = extractPrice(from: candidate.fullText)

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
                mergeResults(matchedWines)
            }

        } catch {
            #if DEBUG
            print("❌ processUploadedImage error: \(error)")
            #endif
        }
    }

    // MARK: - Frame Processing

    private func setupFrameProcessing() {
        print("🔍 ScannerViewModel - setupFrameProcessing called")
        cameraService.$currentFrame
            .compactMap { $0 }
            .sink { [weak self] frame in
                self?.processFrameIfNeeded(frame)
            }
            .store(in: &cancellables)
    }

    private var frameReceivedCount = 0
    private var frameProcessedCount = 0

    private func processFrameIfNeeded(_ frame: CVPixelBuffer) {
        // If auto-scanning is disabled, don't process frames automatically
        guard isAutoScanning else {
            return
        }
        
        frameReceivedCount += 1

        let now = Date()
        // Debounce: Don't process frames faster than every 0.5 seconds
        guard now.timeIntervalSince(lastProcessedTime) >= max(processingInterval, 0.5) else {
            return
        }
        lastProcessedTime = now

        frameProcessedCount += 1
        print("🔍 Frame received #\(frameReceivedCount), processing #\(frameProcessedCount)")

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

        print("🔍 processFrame - starting OCR...")

        do {
            // Step 1: OCR - recognize text in frame
            let ocrResults = try await ocrService.recognizeText(in: frame)
            print("🔍 OCR returned \(ocrResults.count) text results")

            // Log first few results for debugging
            for (index, result) in ocrResults.prefix(3).enumerated() {
                print("🔍 OCR[\(index)]: '\(result.text.prefix(50))' confidence=\(result.confidence)")
            }

            // Update recovery mode status
            ocrRecoveryMode = ocrService.isInRecoveryMode
            if ocrRecoveryMode {
                print("🔍 OCR in recovery/fast mode")
            }
            guard !Task.isCancelled else { return }

            // Step 2: Group text into wine entry candidates
            let candidates = ocrService.groupIntoWineEntries(ocrResults)
            print("🔍 Grouped into \(candidates.count) wine candidates")

            // Log candidates for debugging
            for (index, candidate) in candidates.prefix(3).enumerated() {
                print("🔍 Candidate[\(index)]: '\(candidate.fullText.prefix(60))' confidence=\(candidate.confidence)")
            }

            guard !Task.isCancelled else { return }

            // Step 3: Match each candidate against our wine database
            // Use detached tasks to prevent API request cancellation when new frames arrive
            let taskId = UUID()
            pendingMatchTasks.insert(taskId)

            // Capture what we need for the detached task
            let matchingService = self.matchingService

            Task.detached { [weak self] in
                var matchedWines: [RecognizedWine] = []
                print("🔍 Starting wine matching for \(candidates.count) candidates...")

                for (index, candidate) in candidates.enumerated() {
                    // Note: We don't check Task.isCancelled here because this is a
                    // detached task that should complete its API calls
                    let matchResult = await matchingService.matchWine(from: candidate.fullText)

                    if let match = matchResult {
                        print("✅ Match[\(index)]: '\(match.wine.name)' score=\(match.wine.score ?? 0) confidence=\(match.confidence)")
                    } else {
                        print("⚪ No match[\(index)] for: '\(candidate.fullText.prefix(40))'")
                    }
                    
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
                print("❌ Frame processing error: \(error)")
                print("❌ Error type: \(type(of: error))")
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

}
