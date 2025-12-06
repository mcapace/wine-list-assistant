import SwiftUI
import AVFoundation

struct CameraPreviewView: UIViewRepresentable {
    @ObservedObject var cameraService: CameraService

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        // Connect the camera session to the preview layer
        view.previewLayer.session = cameraService.captureSession
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        // Always ensure session is connected and update when camera state changes
        if uiView.previewLayer.session !== cameraService.captureSession {
            uiView.previewLayer.session = cameraService.captureSession
        }

        // Force layout update when running state changes
        if cameraService.isRunning {
            uiView.setNeedsLayout()
            uiView.layoutIfNeeded()
        }
    }
}

class PreviewView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupPreview()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupPreview()
    }

    private func setupPreview() {
        previewLayer.videoGravity = .resizeAspectFill
        backgroundColor = .black
    }
}

// MARK: - Alternative SwiftUI Implementation using Metal/Core Image

struct CameraFrameView: View {
    @ObservedObject var cameraService: CameraService

    var body: some View {
        GeometryReader { geometry in
            if let pixelBuffer = cameraService.currentFrame {
                PixelBufferView(pixelBuffer: pixelBuffer)
                    .frame(width: geometry.size.width, height: geometry.size.height)
            } else {
                Rectangle()
                    .fill(Color.black)
            }
        }
    }
}

struct PixelBufferView: UIViewRepresentable {
    let pixelBuffer: CVPixelBuffer

    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }

    func updateUIView(_ uiView: UIImageView, context: Context) {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
            uiView.image = UIImage(cgImage: cgImage)
        }
    }
}
