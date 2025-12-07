import Vision
import CoreImage
import UIKit

/// Apple Vision framework OCR implementation
final class AppleVisionOCRService: OCRProvider {
    let name = "Apple Vision"
    let requiresInternet = false
    
    private let requestHandler = VNSequenceRequestHandler()
    private let recognitionLanguages = ["en-US", "fr-FR", "it-IT", "es-ES", "de-DE", "pt-PT"]
    
    /// Track if using fast mode due to ANE issues
    private(set) var useFastRecognition = false
    
    var isInRecoveryMode: Bool { useFastRecognition }
    
    func recognizeText(in pixelBuffer: CVPixelBuffer) async throws -> [OCRService.OCRResult] {
        do {
            return try await withCheckedThrowingContinuation { continuation in
                let request = createTextRecognitionRequest { result in
                    continuation.resume(with: result)
                }
                do {
                    try self.requestHandler.perform([request], on: pixelBuffer)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        } catch {
            let nsError = error as NSError
            if nsError.domain == "com.apple.Vision" || nsError.domain.contains("VN") {
                useFastRecognition = true
                return []
            }
            throw error
        }
    }
    
    func recognizeText(in image: UIImage) async throws -> [OCRService.OCRResult] {
        guard let cgImage = image.cgImage else {
            throw NSError(domain: "OCR", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid image"])
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
    
    private func createTextRecognitionRequest(completion: @escaping (Result<[OCRService.OCRResult], Error>) -> Void) -> VNRecognizeTextRequest {
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
                guard let candidate = observation.topCandidates(1).first, candidate.confidence > 0.5 else {
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
        
        request.recognitionLevel = useFastRecognition ? .fast : .accurate
        request.recognitionLanguages = recognitionLanguages
        request.usesLanguageCorrection = !useFastRecognition
        
        return request
    }
}

