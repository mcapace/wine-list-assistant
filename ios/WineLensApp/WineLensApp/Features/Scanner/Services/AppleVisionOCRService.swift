import Vision
import CoreImage
import UIKit
import CoreVideo

/// Apple Vision framework OCR provider (fallback when Google Cloud unavailable)
final class AppleVisionOCRService: OCRProvider {
    // MARK: - OCRProvider Protocol

    let name = "Apple Vision"
    let requiresInternet = false

    // MARK: - Properties

    private let requestHandler = VNSequenceRequestHandler()

    /// Languages to recognize (prioritized)
    private let recognitionLanguages = ["en-US", "fr-FR", "it-IT", "es-ES", "de-DE", "pt-PT"]

    /// Track if we should use fast mode due to ANE issues
    private(set) var useFastRecognition = false

    /// Public property to check if OCR is in recovery/fast mode
    var isInRecoveryMode: Bool {
        useFastRecognition
    }

    // MARK: - OCRProvider Methods

    /// Recognize text in a pixel buffer (real-time camera frame)
    func recognizeText(in pixelBuffer: CVPixelBuffer) async throws -> [OCRService.OCRResult] {
        print("👁️ AppleVisionOCR - starting text recognition (fastMode=\(useFastRecognition))")
        do {
            return try await withCheckedThrowingContinuation { continuation in
                let request = self.createTextRecognitionRequest { result in
                    continuation.resume(with: result)
                }

                do {
                    try self.requestHandler.perform([request], on: pixelBuffer)
                } catch {
                    print("👁️ AppleVisionOCR - requestHandler.perform error: \(error)")
                    continuation.resume(throwing: error)
                }
            }
        } catch {
            // Handle Vision/ANE errors gracefully
            // These errors (numANECores, fopen data file) are internal to Apple's
            // Vision framework and are recoverable - just return empty results
            let nsError = error as NSError
            print("👁️ AppleVisionOCR - error caught: domain=\(nsError.domain), desc=\(nsError.localizedDescription)")
            if nsError.domain == "com.apple.Vision" ||
               nsError.domain.contains("VN") ||
               nsError.localizedDescription.contains("ANE") {
                // Try switching to fast mode for subsequent requests
                print("👁️ AppleVisionOCR - switching to fast mode due to ANE error")
                useFastRecognition = true
                return []
            }
            throw error
        }
    }

    /// Recognize text in a UIImage (captured photo)
    func recognizeText(in image: UIImage) async throws -> [OCRService.OCRResult] {
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = self.createTextRecognitionRequest { result in
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

    // MARK: - Private Methods

    private func createTextRecognitionRequest(
        completion: @escaping (Result<[OCRService.OCRResult], Error>) -> Void
    ) -> VNRecognizeTextRequest {
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                print("👁️ VNRecognizeTextRequest callback error: \(error)")
                completion(.failure(error))
                return
            }

            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                print("👁️ VNRecognizeTextRequest - no observations")
                completion(.success([]))
                return
            }

            print("👁️ VNRecognizeTextRequest - \(observations.count) observations")

            var filteredOutCount = 0
            let results = observations.compactMap { observation -> OCRService.OCRResult? in
                guard let candidate = observation.topCandidates(1).first else {
                    return nil
                }

                // Lowered confidence threshold from 0.7 to 0.5 for better detection
                guard candidate.confidence > 0.5 else {
                    filteredOutCount += 1
                    return nil
                }

                return OCRService.OCRResult(
                    text: candidate.string,
                    boundingBox: observation.boundingBox,
                    confidence: candidate.confidence
                )
            }

            print("👁️ VNRecognizeTextRequest - \(results.count) results (filtered out \(filteredOutCount) low confidence)")
            completion(.success(results))
        }

        // Configure for text recognition
        // Use fast mode if we've encountered ANE issues, otherwise use accurate mode
        request.recognitionLevel = useFastRecognition ? .fast : .accurate
        request.recognitionLanguages = recognitionLanguages
        request.usesLanguageCorrection = !useFastRecognition  // Disable for fast mode
        request.revision = VNRecognizeTextRequestRevision3

        return request
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
