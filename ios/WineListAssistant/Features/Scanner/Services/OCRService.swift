import Vision
import CoreImage
import UIKit

final class OCRService {
    // MARK: - Types

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

    struct WineTextCandidate {
        let fullText: String
        let boundingBox: CGRect
        let confidence: Float
        let lineCount: Int
    }

    // MARK: - Properties

    private let requestHandler = VNSequenceRequestHandler()

    /// Languages to recognize (prioritized)
    private let recognitionLanguages = ["en-US", "fr-FR", "it-IT", "es-ES", "de-DE", "pt-PT"]

    // MARK: - Public Methods

    /// Recognize text in a pixel buffer (real-time camera frame)
    func recognizeText(in pixelBuffer: CVPixelBuffer) async throws -> [OCRResult] {
        try await withCheckedThrowingContinuation { continuation in
            let request = createTextRecognitionRequest { result in
                continuation.resume(with: result)
            }

            do {
                try requestHandler.perform([request], on: pixelBuffer)
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    /// Recognize text in a UIImage (captured photo)
    func recognizeText(in image: UIImage) async throws -> [OCRResult] {
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = createTextRecognitionRequest { result in
                continuation.resume(with: result)
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    /// Group OCR results into likely wine entries
    func groupIntoWineEntries(_ results: [OCRResult]) -> [WineTextCandidate] {
        guard !results.isEmpty else { return [] }

        // Sort by vertical position (top to bottom in view coordinates)
        let sortedResults = results.sorted { $0.boundingBox.maxY > $1.boundingBox.maxY }

        var candidates: [WineTextCandidate] = []
        var currentGroup: [OCRResult] = []
        var lastBottom: CGFloat = 1.0

        for result in sortedResults {
            let gap = lastBottom - result.boundingBox.maxY

            // If gap is small (< 2% of height), consider same entry
            // Wine list entries typically have consistent spacing
            if gap < 0.025 || currentGroup.isEmpty {
                currentGroup.append(result)
            } else {
                // Start new group
                if !currentGroup.isEmpty {
                    if let candidate = createCandidate(from: currentGroup) {
                        candidates.append(candidate)
                    }
                }
                currentGroup = [result]
            }

            lastBottom = result.boundingBox.minY
        }

        // Don't forget the last group
        if !currentGroup.isEmpty {
            if let candidate = createCandidate(from: currentGroup) {
                candidates.append(candidate)
            }
        }

        // Filter out likely non-wine entries (headers, page numbers, etc.)
        return candidates.filter { isLikelyWineEntry($0) }
    }

    // MARK: - Private Methods

    private func createTextRecognitionRequest(
        completion: @escaping (Result<[OCRResult], Error>) -> Void
    ) -> VNRecognizeTextRequest {
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completion(.success([]))
                return
            }

            let results = observations.compactMap { observation -> OCRResult? in
                guard let candidate = observation.topCandidates(1).first else {
                    return nil
                }

                // Filter out very low confidence results
                guard candidate.confidence > 0.5 else {
                    return nil
                }

                return OCRResult(
                    text: candidate.string,
                    boundingBox: observation.boundingBox,
                    confidence: candidate.confidence
                )
            }

            completion(.success(results))
        }

        // Configure for best text recognition
        request.recognitionLevel = .accurate
        request.recognitionLanguages = recognitionLanguages
        request.usesLanguageCorrection = true
        request.revision = VNRecognizeTextRequestRevision3

        return request
    }

    private func createCandidate(from results: [OCRResult]) -> WineTextCandidate? {
        guard !results.isEmpty else { return nil }

        // Combine text from all lines
        let fullText = results.map(\.text).joined(separator: " ")

        // Skip very short text (likely not a wine entry)
        guard fullText.count >= 5 else { return nil }

        // Compute combined bounding box
        let minX = results.map(\.boundingBox.minX).min() ?? 0
        let minY = results.map(\.boundingBox.minY).min() ?? 0
        let maxX = results.map(\.boundingBox.maxX).max() ?? 1
        let maxY = results.map(\.boundingBox.maxY).max() ?? 1

        let boundingBox = CGRect(
            x: minX,
            y: minY,
            width: maxX - minX,
            height: maxY - minY
        )

        // Average confidence
        let avgConfidence = results.map(\.confidence).reduce(0, +) / Float(results.count)

        return WineTextCandidate(
            fullText: fullText,
            boundingBox: boundingBox,
            confidence: avgConfidence,
            lineCount: results.count
        )
    }

    private func isLikelyWineEntry(_ candidate: WineTextCandidate) -> Bool {
        let text = candidate.fullText.lowercased()

        // Skip common non-wine patterns
        let skipPatterns = [
            "wine list",
            "by the glass",
            "by the bottle",
            "sparkling wines",
            "white wines",
            "red wines",
            "rose wines",
            "dessert wines",
            "page ",
            "continued",
            "see server",
            "ask your",
            "reserve list"
        ]

        for pattern in skipPatterns {
            if text.contains(pattern) {
                return false
            }
        }

        // Look for wine-like patterns
        let wineIndicators = [
            // Vintage year patterns
            #"(19|20)\d{2}"#,
            #"'\d{2}"#,
            // Price patterns
            #"\$\d+"#,
            #"\d+\.\d{2}"#,
            // Common wine terms
            "cabernet", "merlot", "pinot", "chardonnay", "sauvignon",
            "shiraz", "syrah", "riesling", "zinfandel", "malbec",
            "champagne", "prosecco", "chablis", "barolo", "chianti",
            "rioja", "bordeaux", "burgundy", "napa", "sonoma",
            "chateau", "domaine", "estate", "vineyard", "reserve"
        ]

        for indicator in wineIndicators {
            if indicator.hasPrefix("#") {
                // Regex pattern
                if let regex = try? NSRegularExpression(pattern: indicator, options: .caseInsensitive) {
                    let range = NSRange(text.startIndex..., in: text)
                    if regex.firstMatch(in: text, range: range) != nil {
                        return true
                    }
                }
            } else {
                // Simple string contains
                if text.contains(indicator) {
                    return true
                }
            }
        }

        // If text is long enough and has multiple words, might be a wine
        let wordCount = text.split(separator: " ").count
        return wordCount >= 3 && candidate.fullText.count >= 15
    }

    // MARK: - Errors

    enum OCRError: Error, LocalizedError {
        case invalidImage
        case recognitionFailed

        var errorDescription: String? {
            switch self {
            case .invalidImage:
                return "Invalid image format"
            case .recognitionFailed:
                return "Text recognition failed"
            }
        }
    }
}
