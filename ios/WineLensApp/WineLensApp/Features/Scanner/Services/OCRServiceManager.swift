import Foundation
import UIKit
import CoreVideo

/// Manages OCR providers and provides unified interface
final class OCRService {
    // MARK: - Shared Instance
    
    static let shared = OCRService()
    
    // MARK: - Properties
    
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
    
    // Cache the preferred provider name to avoid repeated UserDefaults access
    private let preferredProviderName: String
    
    // MARK: - Initialization
    
    private init() {
        #if DEBUG
        print("🔍 OCRService.init() - START")
        #endif
        
        // Get preferred provider first (this reads UserDefaults, should be fast)
        #if DEBUG
        print("🔍 OCRService.init() - Getting preferred OCR provider...")
        #endif
        self.preferredProviderName = AppConfiguration.preferredOCRProvider
        #if DEBUG
        print("🔍 OCRService.init() - Preferred provider: \(preferredProviderName)")
        #endif
        
        // Initialize Google Cloud provider if API key is available (this is optional, so no blocking)
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
        } else {
            #if DEBUG
            print("🔍 OCRService.init() - No Google Cloud API key, skipping")
            #endif
        }
        
        // DON'T access appleVisionProvider here - it will be created lazily on first use
        // currentProvider is now computed, so no blocking during init
        #if DEBUG
        print("🔍 OCRService.init() - COMPLETE (no lazy properties accessed)")
        #endif
    }
    
    // MARK: - Computed Properties
    
    /// Current OCR provider (computed to avoid blocking during init)
    private var currentProvider: OCRProvider {
        // If manually set, use that
        if let manual = _manualProvider {
            return manual
        }
        
        // Otherwise use preferred provider
        let preferred = preferredProviderName.lowercased()
        if (preferred == "google" || preferred == "googlecloud" || preferred == "google cloud"),
           let googleCloud = googleCloudProvider {
            return googleCloud
        }
        // Default to Apple Vision (lazy, created on first access)
        return appleVisionProvider
    }
    
    // Store manually set provider (when setProvider is called)
    private var _manualProvider: OCRProvider?
    
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
            _manualProvider = appleVisionProvider
        case "google", "googlecloud", "google cloud":
            if let googleCloud = googleCloudProvider {
                _manualProvider = googleCloud
            } else {
                print("⚠️ Google Cloud Vision not available - API key missing")
                _manualProvider = appleVisionProvider
            }
        default:
            _manualProvider = appleVisionProvider
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

        // Must have minimum length
        guard candidate.fullText.count >= 15 else { return false }
        
        // Check OCR confidence threshold
        guard candidate.confidence > 0.5 else { return false }

        // STRICT: Reject menu UI elements and keyboard noise
        let rejectPatterns = [
            "wine color", "wine type", "country", "grid", "list", "share",
            "menu", "restaurant", "welcome", "please", "thank",
            "bookmarks", "profiles", "tab", "window", "help",
            "option", "command", "esc", "fa", "f1", "f2", "f3", "f4", "f5", "f6", "f7", "f8",
            "&", "%", "$", "#", "@", "~", "^", "*", "+", "=", "-",
            "top100", "spectator", "share:", "= list", "= lis",
            "all", "white", "red", "rose", "na", // These alone aren't wines
            "sparkling", "still", "dessert", // These alone aren't wines
            "australia", "argentina", "france", "spain", "united states", // Countries alone
            "chile", "austria", "germany", "italy" // Countries alone
        ]
        
        // Reject if it contains reject patterns (except as part of actual wine names)
        for pattern in rejectPatterns {
            // Use word boundaries to avoid false positives (e.g., "chardonnay" contains "on")
            if text == pattern || text.hasPrefix(pattern + " ") || text.hasSuffix(" " + pattern) || text.contains(" " + pattern + " ") {
                return false
            }
        }
        
        // Reject keyboard-like strings (too many special chars or function keys)
        let specialCharCount = candidate.fullText.filter { "&%$#@~^*+-=".contains($0) }.count
        if specialCharCount > 2 {
            return false
        }
        
        // Reject strings that are mostly numbers/symbols (keyboard layout detection)
        let numericSymbolCount = candidate.fullText.filter { $0.isNumber || "&%$#@~^*+-= ".contains($0) }.count
        if Double(numericSymbolCount) / Double(candidate.fullText.count) > 0.5 {
            return false
        }
        
        // Reject all caps headers (menu section titles) - but allow short ALL CAPS wine names
        if candidate.fullText == candidate.fullText.uppercased() && candidate.fullText.count > 8 {
            // Allow short ALL CAPS like "OPUS ONE" but reject longer headers
            return false
        }

        // MUST contain at least one STRONG wine indicator
        var hasGrapeVariety = false
        var hasWineRegion = false
        var hasVintage = false
        var hasProducer = false
        
        // Grape varieties
        let grapes = ["cabernet", "merlot", "pinot", "chardonnay", "sauvignon", "shiraz", "syrah", 
                     "riesling", "zinfandel", "malbec", "sangiovese", "tempranillo", "grenache",
                     "viognier", "gewurztraminer", "chenin", "semillon", "muscat"]
        for grape in grapes {
            if text.contains(grape) {
                hasGrapeVariety = true
                break
            }
        }
        
        // Wine regions
        let regions = ["bordeaux", "burgundy", "champagne", "napa", "sonoma", "rioja", "barolo",
                      "chianti", "tuscany", "rhone", "alsace", "loire", "chablis", "cote",
                      "margaux", "pauillac", "saint", "st.", "chateau", "domaine", "estate",
                      "vineyard", "appellation", "ava", "aoc", "doc", "docg"]
        for region in regions {
            if text.contains(region) {
                hasWineRegion = true
                break
            }
        }
        
        // Vintage year (4-digit year between 1970-2025)
        if let _ = text.range(of: #"\b(19[789]\d|20[012]\d)\b"#, options: .regularExpression) {
            hasVintage = true
        }
        
        // Producer indicators
        let producers = ["chateau", "château", "domaine", "estate", "vineyard", "winery", "cellars",
                        "wines", "vintners", "productions", "reserve", "special", "private", "select"]
        for producer in producers {
            if text.contains(producer) {
                hasProducer = true
                break
            }
        }
        
        // Must have at least TWO strong indicators (to avoid false positives)
        let indicatorCount = [hasGrapeVariety, hasWineRegion, hasVintage, hasProducer].filter { $0 }.count
        guard indicatorCount >= 2 else {
            return false
        }

        // Additional check: reject if it's clearly menu structure text
        let menuWords = ["grid", "list", "share", "color", "type", "country"]
        let menuWordCount = menuWords.filter { text.contains($0) }.count
        if menuWordCount >= 2 {
            return false
        }

        return true
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

