import AVFoundation
import Combine
import UIKit

// NOTE: Removed @MainActor to fix deadlock during SwiftUI view initialization
// @Published handles thread safety, camera work happens on sessionQueue anyway
final class CameraService: NSObject, ObservableObject {
    // MARK: - Published Properties

    @Published private(set) var currentFrame: CVPixelBuffer?
    @Published private(set) var isAuthorized: Bool = false
    @Published private(set) var isRunning: Bool = false
    @Published private(set) var error: CameraError?
    @Published var torchEnabled: Bool = false {
        didSet {
            updateTorch()
        }
    }

    // MARK: - Private Properties

    /// The capture session - exposed for preview layer connection
    let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "com.winespec.winelensapp.camera.session")
    private let videoOutputQueue = DispatchQueue(label: "com.winespec.winelensapp.camera.output")
    private var currentDevice: AVCaptureDevice?
    private var isConfigured = false

    // MARK: - Error Types

    enum CameraError: Error, LocalizedError {
        case notAuthorized
        case configurationFailed
        case deviceNotAvailable
        case torchNotAvailable

        var errorDescription: String? {
            switch self {
            case .notAuthorized:
                return "Camera access is required to scan wine lists"
            case .configurationFailed:
                return "Unable to configure the camera"
            case .deviceNotAvailable:
                return "No camera available on this device"
            case .torchNotAvailable:
                return "Torch is not available on this device"
            }
        }

        var recoverySuggestion: String? {
            switch self {
            case .notAuthorized:
                return "Please enable camera access in Settings"
            case .configurationFailed, .deviceNotAvailable:
                return "Please restart the app"
            case .torchNotAvailable:
                return nil
            }
        }
    }

    // MARK: - Authorization

    func checkAuthorization() -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isAuthorized = true
            return true
        default:
            isAuthorized = false
            return false
        }
    }

    func requestAuthorization() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        #if DEBUG
        let statusString: String
        switch status {
        case .notDetermined: statusString = "notDetermined"
        case .restricted: statusString = "restricted"
        case .denied: statusString = "denied"
        case .authorized: statusString = "authorized"
        @unknown default: statusString = "unknown"
        }
        print("📷 Camera authorization status: \(statusString) (rawValue: \(status.rawValue))")
        #endif

        switch status {
        case .authorized:
            #if DEBUG
            print("✅ Camera already authorized")
            #endif
            await MainActor.run {
                isAuthorized = true
            }
            return true

        case .notDetermined:
            #if DEBUG
            print("📱 STATUS: notDetermined - iOS will show permission dialog when requestAccess() is called")
            print("📱 Calling AVCaptureDevice.requestAccess(for: .video) NOW...")
            #endif
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            #if DEBUG
            print("📱 AVCaptureDevice.requestAccess() completed - granted: \(granted)")
            if !granted {
                print("⚠️ WARNING: Permission was denied by user or Info.plist is missing NSCameraUsageDescription")
            }
            #endif
            await MainActor.run {
                isAuthorized = granted
                if !granted {
                    error = .notAuthorized
                }
            }
            return granted

        case .denied:
            #if DEBUG
            print("❌ Camera permission DENIED - User must enable in Settings")
            print("❌ The permission dialog will NOT appear again unless app is deleted and reinstalled")
            #endif
            await MainActor.run {
                isAuthorized = false
                error = .notAuthorized
            }
            return false
            
        case .restricted:
            #if DEBUG
            print("❌ Camera permission RESTRICTED - Parental controls or MDM")
            #endif
            await MainActor.run {
                isAuthorized = false
                error = .notAuthorized
            }
            return false

        @unknown default:
            #if DEBUG
            print("❌ Camera authorization status unknown")
            #endif
            return false
        }
    }

    // MARK: - Configuration

    func configure() async throws {
        // Skip if already configured to avoid FigCaptureSource errors
        guard !isConfigured else { return }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            sessionQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume()
                    return
                }

                do {
                    // Ensure session is fully stopped before configuration
                    if self.captureSession.isRunning {
                        self.captureSession.stopRunning()
                    }

                    // Clear any existing configuration
                    self.captureSession.beginConfiguration()
                    self.captureSession.inputs.forEach { self.captureSession.removeInput($0) }
                    self.captureSession.outputs.forEach { self.captureSession.removeOutput($0) }
                    self.captureSession.commitConfiguration()

                    try self.configureSessionSync()

                    Task { @MainActor in
                        self.isConfigured = true
                    }
                    continuation.resume()
                } catch {
                    Task { @MainActor in
                        self.isConfigured = false
                        self.error = error as? CameraError ?? .configurationFailed
                    }
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func configureSessionSync() throws {
        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }

        // Set session preset for high quality
        if captureSession.canSetSessionPreset(.high) {
            captureSession.sessionPreset = .high
        }

        // Get camera device
        guard let device = getBestCamera() else {
            throw CameraError.deviceNotAvailable
        }

        currentDevice = device

        // Configure device for low light (must be done before adding input)
        try configureDeviceSync(device)

        // Add input
        let input = try AVCaptureDeviceInput(device: device)
        guard captureSession.canAddInput(input) else {
            throw CameraError.configurationFailed
        }
        captureSession.addInput(input)

        // Configure output
        videoOutput.setSampleBufferDelegate(nil, queue: nil)
        videoOutput.setSampleBufferDelegate(self, queue: videoOutputQueue)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]

        guard captureSession.canAddOutput(videoOutput) else {
            throw CameraError.configurationFailed
        }
        captureSession.addOutput(videoOutput)

        // Set video orientation
        if let connection = videoOutput.connection(with: .video) {
            if connection.isVideoRotationAngleSupported(90) {
                connection.videoRotationAngle = 90
            }
        }
    }

    private func getBestCamera() -> AVCaptureDevice? {
        // Prefer wide angle camera for best OCR results
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            return device
        }

        // Fallback to any available camera
        return AVCaptureDevice.default(for: .video)
    }

    private func configureDeviceSync(_ device: AVCaptureDevice) throws {
        try device.lockForConfiguration()
        defer { device.unlockForConfiguration() }

        // Enable auto-focus for text
        if device.isFocusModeSupported(.continuousAutoFocus) {
            device.focusMode = .continuousAutoFocus
        }

        // Enable auto-exposure
        if device.isExposureModeSupported(.continuousAutoExposure) {
            device.exposureMode = .continuousAutoExposure
        }

        // Enable low light boost if available
        if device.isLowLightBoostSupported {
            device.automaticallyEnablesLowLightBoostWhenAvailable = true
        }
    }

    // MARK: - Session Control

    func start() {
        guard !isRunning, isConfigured else {
            print("📷 CameraService.start() - skipped: isRunning=\(isRunning), isConfigured=\(isConfigured)")
            return
        }

        // Set isRunning immediately so frames aren't discarded during startup race condition
        isRunning = true
        print("📷 CameraService.start() - setting isRunning=true, starting session...")

        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            // Only start if not already running
            guard !self.captureSession.isRunning else {
                print("📷 CameraService - session already running")
                return
            }

            self.captureSession.startRunning()
            let actuallyRunning = self.captureSession.isRunning
            print("📷 CameraService - session started, isRunning=\(actuallyRunning)")

            Task { @MainActor in
                // Update to actual state (in case start failed)
                if !actuallyRunning {
                    self.isRunning = false
                    print("📷 CameraService - session failed to start")
                }
            }
        }
    }

    func stop() {
        guard isRunning else { return }

        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            // Remove delegate to prevent new frames
            self.videoOutput.setSampleBufferDelegate(nil, queue: nil)

            // Stop session
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }

            Task { @MainActor in
                self.currentFrame = nil
                self.isRunning = false
            }
        }
    }

    // MARK: - Torch Control

    private func updateTorch() {
        guard let device = currentDevice, device.hasTorch else {
            error = .torchNotAvailable
            return
        }

        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Only update torch if session is running
            guard self.captureSession.isRunning else { return }
            
            do {
                // Try to lock device for configuration
                // lockForConfiguration() will throw if device is already locked
                try device.lockForConfiguration()
                device.torchMode = self.torchEnabled ? .on : .off
                device.unlockForConfiguration()
            } catch {
                // Torch errors are non-fatal, don't set error state
                // This prevents FigCaptureSource errors from propagating
            }
        }
    }

    // MARK: - Focus

    func focus(at point: CGPoint) {
        guard let device = currentDevice else { return }
        
        // Only focus if session is running
        guard captureSession.isRunning else { return }

        sessionQueue.async {
            do {
                try device.lockForConfiguration()

                if device.isFocusPointOfInterestSupported {
                    device.focusPointOfInterest = point
                    device.focusMode = .autoFocus
                }

                if device.isExposurePointOfInterestSupported {
                    device.exposurePointOfInterest = point
                    device.exposureMode = .autoExpose
                }

                device.unlockForConfiguration()
            } catch {
                // Focus errors are non-fatal, silently fail
                // This prevents FigCaptureSource errors from propagating
            }
        }
    }

    // MARK: - Capture Still Image

    func capturePhoto() async -> UIImage? {
        guard let frame = currentFrame else { return nil }

        let ciImage = CIImage(cvPixelBuffer: frame)
        let context = CIContext()

        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }
    
    // MARK: - Cleanup
    
    func reset() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Stop session
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
            
            // Remove delegate
            self.videoOutput.setSampleBufferDelegate(nil, queue: nil)
            
            // Clear configuration
            self.captureSession.beginConfiguration()
            self.captureSession.inputs.forEach { self.captureSession.removeInput($0) }
            self.captureSession.outputs.forEach { self.captureSession.removeOutput($0) }
            self.captureSession.commitConfiguration()
            
            // Reset state
            Task { @MainActor in
                self.currentFrame = nil
                self.isRunning = false
                self.isConfigured = false
                self.currentDevice = nil
            }
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    // Track frame count for debug logging (every 30 frames ~= 1 second)
    private static var frameCount = 0

    nonisolated func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        // Only publish frame if session is actively running
        // This helps prevent FigCaptureSource errors during session transitions
        Task { @MainActor in
            guard self.isRunning else { return }
            self.currentFrame = pixelBuffer

            // Debug: log every 30th frame
            CameraService.frameCount += 1
            if CameraService.frameCount % 30 == 0 {
                print("📷 Frame published: #\(CameraService.frameCount)")
            }
        }
    }

    nonisolated func captureOutput(
        _ output: AVCaptureOutput,
        didDrop sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        // Frames are being dropped - this is normal during heavy processing
        // FigCaptureSource may log errors here but they're recoverable
    }
}
