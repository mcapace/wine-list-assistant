import AVFoundation
import Combine
import UIKit

@MainActor
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
    private let sessionQueue = DispatchQueue(label: "com.winespectator.wla.camera.session")
    private let videoOutputQueue = DispatchQueue(label: "com.winespectator.wla.camera.output")
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

        switch status {
        case .authorized:
            isAuthorized = true
            return true

        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            await MainActor.run {
                isAuthorized = granted
                if !granted {
                    error = .notAuthorized
                }
            }
            return granted

        case .denied, .restricted:
            await MainActor.run {
                isAuthorized = false
                error = .notAuthorized
            }
            return false

        @unknown default:
            return false
        }
    }

    // MARK: - Configuration

    func configure() throws {
        // Skip if already configured to avoid FigCaptureSource errors
        guard !isConfigured else { return }

        sessionQueue.sync {
            do {
                // Ensure session is fully stopped before configuration
                // This prevents FigCaptureSource errors (err=-12710, err=-17281)
                if captureSession.isRunning {
                    captureSession.stopRunning()
                    // Wait for session to fully stop before reconfiguring
                    // This prevents race conditions that cause FigCaptureSource errors
                    var attempts = 0
                    while captureSession.isRunning && attempts < 10 {
                        Thread.sleep(forTimeInterval: 0.05)
                        attempts += 1
                    }
                }
                
                // Clear any existing configuration
                captureSession.beginConfiguration()
                captureSession.inputs.forEach { captureSession.removeInput($0) }
                captureSession.outputs.forEach { captureSession.removeOutput($0) }
                captureSession.commitConfiguration()
                
                // Small delay to ensure cleanup is complete
                Thread.sleep(forTimeInterval: 0.1)
                
                try configureSession()
                isConfigured = true
            } catch {
                isConfigured = false
                Task { @MainActor in
                    self.error = error as? CameraError ?? .configurationFailed
                }
            }
        }
    }

    private func configureSession() throws {
        captureSession.beginConfiguration()
        defer { 
            captureSession.commitConfiguration()
            // Small delay after commit to ensure configuration is fully applied
            Thread.sleep(forTimeInterval: 0.05)
        }

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
        try configureDevice(device)

        // Add input - ensure device is unlocked before creating input
        let input = try AVCaptureDeviceInput(device: device)
        guard captureSession.canAddInput(input) else {
            throw CameraError.configurationFailed
        }
        captureSession.addInput(input)

        // Configure output
        videoOutput.setSampleBufferDelegate(nil, queue: nil) // Clear delegate first
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

    private func configureDevice(_ device: AVCaptureDevice) throws {
        // Try to lock device for configuration
        // lockForConfiguration() will throw if device is already locked
        try device.lockForConfiguration()
        defer { 
            device.unlockForConfiguration()
            // Small delay after unlock to ensure changes are committed
            Thread.sleep(forTimeInterval: 0.05)
        }

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

        // Set frame rate - use a more conservative rate to reduce FigCaptureSource errors
        let desiredFrameRate = CMTimeMake(value: 1, timescale: Int32(Constants.Camera.defaultFrameRate))
        if device.activeFormat.isVideoStabilizationModeSupported(.auto) {
            // Only set frame rate if format supports it
            do {
                device.activeVideoMinFrameDuration = desiredFrameRate
                device.activeVideoMaxFrameDuration = desiredFrameRate
            } catch {
                // Frame rate setting failed - continue without it
                // This is non-fatal and helps avoid FigCaptureSource errors
            }
        }
    }

    // MARK: - Session Control

    func start() {
        guard !isRunning else { return }
        
        // Ensure we're configured before starting
        guard isConfigured else {
            do {
                try configure()
            } catch {
                Task { @MainActor in
                    self.error = error as? CameraError ?? .configurationFailed
                }
                return
            }
            return // Return after successful configuration
        }

        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Only start if not already running
            guard !self.captureSession.isRunning else {
                Task { @MainActor in
                    self.isRunning = true
                }
                return
            }
            
            self.captureSession.startRunning()
            
            // Wait a moment and verify it actually started
            Thread.sleep(forTimeInterval: 0.1)
            
            Task { @MainActor in
                self.isRunning = self.captureSession.isRunning
            }
        }
    }

    func stop() {
        guard isRunning else { return }

        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Clear frame first to stop processing before stopping session
            Task { @MainActor in
                self.currentFrame = nil
            }
            
            // Remove delegate to prevent new frames during shutdown
            self.videoOutput.setSampleBufferDelegate(nil, queue: nil)
            
            // Small delay to allow frame processing to complete
            Thread.sleep(forTimeInterval: 0.1)
            
            // Stop session
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
                
                // Wait for session to fully stop
                var attempts = 0
                while self.captureSession.isRunning && attempts < 20 {
                    Thread.sleep(forTimeInterval: 0.05)
                    attempts += 1
                }
            }
            
            Task { @MainActor in
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
