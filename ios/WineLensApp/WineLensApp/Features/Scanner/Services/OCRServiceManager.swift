import Foundation
import UIKit
import CoreVideo

/// Manages OCR providers and provides unified interface
final class OCRService {
    // MARK: - Shared Instance
    
    static let shared = OCRService()
    
    // MARK: - Properties
    
    private var currentProvider: OCRProvider
    // Make lazy to avoid blocking during singleton initialization
    private lazy var appleVisionProvider: AppleVisionOCRService = {
        #if DEBUG
        print("🔍 OCRService - Creating AppleVisionOCRService lazily...")
        #endif
        let provider = AppleVisionOCRService()
        #if DEBUG
        print("🔍 OCRService - AppleVisionOCRService created lazily")
        #endif
        return provider
    }()
    private var googleCloudProvider: GoogleCloudOCRService?
    
    // MARK: - Initialization
    
    private init() {
        #if DEBUG
        print("🔍 OCRService.init() - START")
        #endif
        
        // Get preferred provider first (this reads UserDefaults, should be fast)
        #if DEBUG
        print("🔍 OCRService.init() - Getting preferred OCR provider...")
        #endif
        let preferredProvider = AppConfiguration.preferredOCRProvider
        #if DEBUG
        print("🔍 OCRService.init() - Preferred provider: \(preferredProvider)")
        #endif
        
        // Temporarily create a dummy provider, we'll replace it below
        // This avoids triggering lazy init during init()
        #if DEBUG
        print("🔍 OCRService.init() - Creating temporary provider...")
        #endif
        
        // Initialize currentProvider - this will trigger lazy init of appleVisionProvider
        // but we need to set it to something, so we'll access appleVisionProvider
        switch preferredProvider.lowercased() {
        case "google", "googlecloud", "google cloud":
            #if DEBUG
            print("🔍 OCRService.init() - Google Cloud preferred, will check below")
            #endif
            // Will set below after checking if Google Cloud is available
            self.currentProvider = appleVisionProvider // Triggers lazy init
        default:
            #if DEBUG
            print("🔍 OCRService.init() - Apple Vision preferred (default)")
            #endif
            self.currentProvider = appleVisionProvider // Triggers lazy init
        }
        #if DEBUG
        print("🔍 OCRService.init() - Initial provider set (lazy init should have completed)")
        #endif
        
        // Initialize Google Cloud provider if API key is available
        #if DEBUG
        print("🔍 OCRService.init() - Checking for Google Cloud API key...")
        #endif
        if let apiKey = AppConfiguration.googleCloudVisionAPIKey, !apiKey.isEmpty {
            #if DEBUG
            print("🔍 OCRService.init() - Creating GoogleCloudOCRService...")
            #endif
            self.googleCloudProvider = GoogleCloudOCRService(apiKey: apiKey)
            #if DEBUG
            print("🔍 OCRService.init() - GoogleCloudOCRService created")
            #endif
            
            // If Google Cloud is preferred and now available, switch to it
            if preferredProvider.lowercased() == "google" || 
               preferredProvider.lowercased() == "googlecloud" || 
               preferredProvider.lowercased() == "google cloud" {
                if let googleCloud = googleCloudProvider {
                    self.currentProvider = googleCloud
                    #if DEBUG
                    print("🔍 OCRService.init() - Switched to Google Cloud provider")
                    #endif
                }
            }
        } else {
            #if DEBUG
            print("🔍 OCRService.init() - No Google Cloud API key, skipping")
            #endif
        }
        #if DEBUG
        print("🔍 OCRService.init() - COMPLETE")
        #endif
    }
    
    // MARK: - Provider Management
    
    /// Available OCR providers
    var availableProviders: [OCRProvider] {
        var providers: [OCRProvider] = [appleVisionProvider]
        if let googleCloud = googleCloudProvider {
            providers.append(googleCloud)
        }
        return providers
    }
    
    /// Current OCR provider
    var provider: OCRProvider {
        return currentProvider
    }
    
    /// Whether OCR is in recovery/fast mode (only applies to Apple Vision)
    var isInRecoveryMode: Bool {
        (currentProvider as? AppleVisionOCRService)?.isInRecoveryMode ?? false
    }
    
    /// Switch to a different OCR provider
    func setProvider(_ providerName: String) {
        switch providerName.lowercased() {
        case "apple", "vision":
            currentProvider = appleVisionProvider
        case "google", "googlecloud", "google cloud":
            if let googleCloud = googleCloudProvider {
                currentProvider = googleCloud
            } else {
                print("⚠️ Google Cloud Vision not available - API key missing")
                currentProvider = appleVisionProvider
            }
        default:
            currentProvider = appleVisionProvider
        }
    }
    
    // MARK: - OCR Methods (Delegate to current provider)
    
    /// Recognize text in a pixel buffer (real-time camera frame)
    func recognizeText(in pixelBuffer: CVPixelBuffer) async throws -> [OCRResult] {
        return try await currentProvider.recognizeText(in: pixelBuffer)
    }
    
    /// Recognize text in a UIImage (captured photo)
    func recognizeText(in image: UIImage) async throws -> [OCRResult] {
        return try await currentProvider.recognizeText(in: image)
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
    
    // MARK: - Private Helper Methods
    
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
}

// MARK: - Types

extension OCRService {
    struct WineTextCandidate {
        let fullText: String
        let boundingBox: CGRect
        let confidence: Float
        let lineCount: Int
    }
}

