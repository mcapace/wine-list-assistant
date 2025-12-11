import Foundation
import UIKit
import CoreVideo

/// Google Cloud Vision API OCR implementation
final class GoogleCloudOCRService: OCRProvider {
    // MARK: - Properties
    
    let name = "Google Cloud Vision"
    let requiresInternet = true
    
    private let apiKey: String
    private let apiURL = "https://vision.googleapis.com/v1/images:annotate"
    
    // MARK: - Initialization
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    // MARK: - OCRProvider Implementation
    
    func recognizeText(in pixelBuffer: CVPixelBuffer) async throws -> [OCRService.OCRResult] {
        // Convert pixel buffer to UIImage
        let image = pixelBufferToUIImage(pixelBuffer)
        return try await recognizeText(in: image)
    }
    
    func recognizeText(in image: UIImage) async throws -> [OCRService.OCRResult] {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw GoogleCloudOCRError.invalidImage
        }
        
        // Encode image as base64
        let base64Image = imageData.base64EncodedString()
        
        // Create request
        let requestBody: [String: Any] = [
            "requests": [
                [
                    "image": [
                        "content": base64Image
                    ],
                    "features": [
                        [
                            "type": "TEXT_DETECTION",
                            "maxResults": 100
                        ]
                    ],
                    "imageContext": [
                        "languageHints": ["en", "fr", "it", "es", "de", "pt"]
                    ]
                ]
            ]
        ]
        
        guard let url = URL(string: "\(apiURL)?key=\(apiKey)") else {
            throw GoogleCloudOCRError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        // Make API call
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GoogleCloudOCRError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorData["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw GoogleCloudOCRError.apiError(message)
            }
            throw GoogleCloudOCRError.httpError(httpResponse.statusCode)
        }
        
        // Parse response
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let responses = json["responses"] as? [[String: Any]],
              let firstResponse = responses.first,
              let textAnnotations = firstResponse["textAnnotations"] as? [[String: Any]] else {
            return []
        }
        
        // Convert to OCRResult format
        var results: [OCRService.OCRResult] = []
        
        // Skip first annotation (it's the full text)
        for annotation in textAnnotations.dropFirst() {
            guard let description = annotation["description"] as? String,
                  let boundingPoly = annotation["boundingPoly"] as? [String: Any],
                  let vertices = boundingPoly["vertices"] as? [[String: Any]] else {
                continue
            }
            
            // Convert vertices to normalized bounding box
            let boundingBox = parseBoundingBox(from: vertices, imageSize: image.size)
            
            // Google Cloud doesn't provide confidence scores for TEXT_DETECTION
            // Use a default high confidence since Google Cloud is generally accurate
            let confidence: Float = 0.9
            
            results.append(OCRService.OCRResult(
                text: description,
                boundingBox: boundingBox,
                confidence: confidence
            ))
        }
        
        return results
    }
    
    // MARK: - Helper Methods
    
    private func pixelBufferToUIImage(_ pixelBuffer: CVPixelBuffer) -> UIImage {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return UIImage()
        }
        return UIImage(cgImage: cgImage)
    }
    
    private func parseBoundingBox(from vertices: [[String: Any]], imageSize: CGSize) -> CGRect {
        guard vertices.count >= 2 else {
            return CGRect.zero
        }
        
        // Get min/max x and y coordinates
        var minX = CGFloat.greatestFiniteMagnitude
        var minY = CGFloat.greatestFiniteMagnitude
        var maxX: CGFloat = 0
        var maxY: CGFloat = 0
        
        for vertex in vertices {
            if let x = vertex["x"] as? CGFloat {
                minX = min(minX, x)
                maxX = max(maxX, x)
            }
            if let y = vertex["y"] as? CGFloat {
                minY = min(minY, y)
                maxY = max(maxY, y)
            }
        }
        
        // Normalize to 0-1 range (Vision Framework format: origin bottom-left)
        let normalizedX = minX / imageSize.width
        let normalizedY = 1.0 - (maxY / imageSize.height) // Flip Y axis
        let normalizedWidth = (maxX - minX) / imageSize.width
        let normalizedHeight = (maxY - minY) / imageSize.height
        
        return CGRect(
            x: normalizedX,
            y: normalizedY,
            width: normalizedWidth,
            height: normalizedHeight
        )
    }
    
    // MARK: - Errors
    
    enum GoogleCloudOCRError: Error, LocalizedError {
        case invalidImage
        case invalidURL
        case invalidResponse
        case httpError(Int)
        case apiError(String)
        
        var errorDescription: String? {
            switch self {
            case .invalidImage:
                return "Invalid image format"
            case .invalidURL:
                return "Invalid API URL"
            case .invalidResponse:
                return "Invalid API response"
            case .httpError(let code):
                return "HTTP error: \(code)"
            case .apiError(let message):
                return "Google Cloud API error: \(message)"
            }
        }
    }
}




