import Vision
import CoreImage
import UIKit
import CoreVideo

/// Apple Vision Framework OCR implementation
final class AppleVisionOCRService: OCRProvider {
    // MARK: - Properties
    
    let name = "Apple Vision"
    let requiresInternet = false
    
    private let requestHandler = VNSequenceRequestHandler()
    private let recognitionLanguages = ["en-US", "fr-FR", "it-IT", "es-ES", "de-DE", "pt-PT"]

    // MARK: - OCRProvider Implementation
    
    func recognizeText(in pixelBuffer: CVPixelBuffer) async throws -> [OCRService.OCRResult] {
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

    func recognizeText(in image: UIImage) async throws -> [OCRService.OCRResult] {
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

    // MARK: - Private Methods

    private func createTextRecognitionRequest(
        completion: @escaping (Result<[OCRService.OCRResult], Error>) -> Void
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

            let results = observations.compactMap { observation -> OCRService.OCRResult? in
                guard let candidate = observation.topCandidates(1).first else {
                    return nil
                }

                // Filter out very low confidence results
                guard candidate.confidence > 0.5 else {
                    return nil
                }

                return OCRService.OCRResult(
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
