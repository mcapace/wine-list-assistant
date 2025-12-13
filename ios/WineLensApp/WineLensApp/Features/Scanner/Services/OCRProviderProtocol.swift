import Foundation
import UIKit
import CoreVideo

/// Protocol for OCR providers (Apple Vision, Google Cloud, etc.)
protocol OCRProvider {
    /// Recognize text in a pixel buffer (real-time camera frame)
    func recognizeText(in pixelBuffer: CVPixelBuffer) async throws -> [OCRService.OCRResult]
    
    /// Recognize text in a UIImage (captured photo)
    func recognizeText(in image: UIImage) async throws -> [OCRService.OCRResult]
    
    /// Provider name for display
    var name: String { get }
    
    /// Whether this provider requires internet connection
    var requiresInternet: Bool { get }
}

/// Shared OCR result structure
extension OCRService {
    struct OCRResult {
        let text: String
        let boundingBox: CGRect  // Normalized coordinates (0-1), origin bottom-left
        let confidence: Float

        /// Convert Vision coordinates to SwiftUI coordinates
        func convertedBoundingBox(for viewSize: CGSize) -> CGRect {
            CGRect(
                x: boundingBox.minX * viewSize.width,
                y: (1 - boundingBox.maxY) * viewSize.height,
                width: boundingBox.width * viewSize.width,
                height: boundingBox.height * viewSize.height
            )
        }
    }
}




