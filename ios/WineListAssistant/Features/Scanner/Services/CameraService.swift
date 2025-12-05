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

    let captureSession = AVCaptureSession()  // Made internal so preview can access it
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "com.winespectator.wla.camera.session")
    private let videoOutputQueue = DispatchQueue(label: "com.winespectator.wla.camera.output")
    private var currentDevice: AVCaptureDevice?

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
        sessionQueue.sync {
            do {
                try configureSession()
            } catch {
                Task { @MainActor in
                    self.error = error as? CameraError ?? .configurationFailed
                }
            }
        }
    }

    private func configureSession() throws {
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

        // Configure device for low light
        try configureDevice(device)

        // Add input
        let input = try AVCaptureDeviceInput(device: device)
        guard captureSession.canAddInput(input) else {
            throw CameraError.configurationFailed
        }

        // Remove existing inputs
        captureSession.inputs.forEach { captureSession.removeInput($0) }
        captureSession.addInput(input)

        // Configure output
        videoOutput.setSampleBufferDelegate(self, queue: videoOutputQueue)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]

        // Remove existing outputs
        captureSession.outputs.forEach { captureSession.removeOutput($0) }

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

        // Set frame rate
        let desiredFrameRate = CMTimeMake(value: 1, timescale: Int32(Constants.Camera.defaultFrameRate))
        device.activeVideoMinFrameDuration = desiredFrameRate
        device.activeVideoMaxFrameDuration = desiredFrameRate
    }

    // MARK: - Session Control

    func start() {
        guard !isRunning else { return }

        sessionQueue.async { [weak self] in
            self?.captureSession.startRunning()
            Task { @MainActor in
                self?.isRunning = self?.captureSession.isRunning ?? false
                #if DEBUG
                print("📷 Camera started: \(self?.isRunning ?? false)")
                #endif
            }
        }
    }

    func stop() {
        guard isRunning else { return }

        sessionQueue.async { [weak self] in
            self?.captureSession.stopRunning()
            Task { @MainActor in
                self?.isRunning = false
                self?.currentFrame = nil
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
            do {
                try device.lockForConfiguration()
                device.torchMode = self?.torchEnabled == true ? .on : .off
                device.unlockForConfiguration()
            } catch {
                Task { @MainActor in
                    self?.error = .torchNotAvailable
                }
            }
        }
    }

    // MARK: - Focus

    func focus(at point: CGPoint) {
        guard let device = currentDevice else { return }

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
                print("Failed to set focus point: \(error)")
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

        Task { @MainActor in
            self.currentFrame = pixelBuffer
            #if DEBUG
            // Log occasionally to avoid spam (every 30 frames ≈ 1 second at 30fps)
            if Int.random(in: 0..<30) == 0 {
                print("📹 Frame captured: \(pixelBuffer.width)x\(pixelBuffer.height)")
            }
            #endif
        }
    }

    nonisolated func captureOutput(
        _ output: AVCaptureOutput,
        didDrop sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        // Frames are being dropped - could log for performance monitoring
    }
}
