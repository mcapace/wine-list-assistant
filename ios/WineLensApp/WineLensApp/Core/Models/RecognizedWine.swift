import Foundation
import CoreGraphics

struct RecognizedWine: Identifiable {
    let id: UUID
    let originalText: String
    let boundingBox: CGRect  // Normalized coordinates (0-1)
    let ocrConfidence: Float
    let matchedWine: Wine?
    let matchConfidence: Double
    let matchedVintage: Int?
    let matchType: MatchType
    let listPrice: Decimal?

    enum MatchType: String {
        case exact
        case fuzzyName
        case fuzzyProducer
        case vintageVariant
        case noMatch
    }

    // MARK: - Computed Properties

    var isMatched: Bool {
        matchedWine != nil && matchConfidence >= AppConfiguration.matchConfidenceThreshold
    }
    
    var isPartialMatch: Bool {
        matchedWine != nil && matchConfidence >= AppConfiguration.partialMatchThreshold && matchConfidence < AppConfiguration.matchConfidenceThreshold
    }

    var hasLowConfidence: Bool {
        matchConfidence < 0.85 && matchConfidence >= AppConfiguration.matchConfidenceThreshold
    }

    var valueRatio: Double? {
        guard let wine = matchedWine,
              let releasePrice = wine.releasePrice,
              let listPrice = listPrice,
              releasePrice > 0 else {
            return nil
        }

        let release = Double(truncating: releasePrice as NSDecimalNumber)
        let list = Double(truncating: listPrice as NSDecimalNumber)
        return list / release
    }

    var isBestValue: Bool {
        guard let wine = matchedWine, let ratio = valueRatio else {
            return false
        }
        // Best value: high score with reasonable markup (< 2.5x)
        return (wine.score ?? 0) >= 90 && ratio < 2.5
    }

    var valueIndicator: ValueIndicator {
        guard let ratio = valueRatio else { return .unknown }

        switch ratio {
        case ..<2.0: return .excellent
        case 2.0..<2.5: return .good
        case 2.5..<3.5: return .fair
        default: return .poor
        }
    }

    enum ValueIndicator {
        case excellent
        case good
        case fair
        case poor
        case unknown

        var displayText: String {
            switch self {
            case .excellent: return "Great Value"
            case .good: return "Good Value"
            case .fair: return "Fair"
            case .poor: return "Premium"
            case .unknown: return ""
            }
        }
    }

    // MARK: - Initializers

    init(
        id: UUID = UUID(),
        originalText: String,
        boundingBox: CGRect,
        ocrConfidence: Float = 1.0,
        matchedWine: Wine? = nil,
        matchConfidence: Double = 0,
        matchedVintage: Int? = nil,
        matchType: MatchType = .noMatch,
        listPrice: Decimal? = nil
    ) {
        self.id = id
        self.originalText = originalText
        self.boundingBox = boundingBox
        self.ocrConfidence = ocrConfidence
        self.matchedWine = matchedWine
        self.matchConfidence = matchConfidence
        self.matchedVintage = matchedVintage
        self.matchType = matchType
        self.listPrice = listPrice
    }
}

// MARK: - Preview Helpers

#if DEBUG
extension RecognizedWine {
    static let preview = RecognizedWine(
        originalText: "Opus One 2019 $850",
        boundingBox: CGRect(x: 0.1, y: 0.3, width: 0.8, height: 0.05),
        ocrConfidence: 0.95,
        matchedWine: Wine.preview,
        matchConfidence: 0.98,
        matchedVintage: 2019,
        matchType: .exact,
        listPrice: 850.00
    )

    static let previewLowConfidence = RecognizedWine(
        originalText: "Ch. Margaux '15",
        boundingBox: CGRect(x: 0.1, y: 0.5, width: 0.6, height: 0.05),
        ocrConfidence: 0.88,
        matchedWine: Wine.preview,
        matchConfidence: 0.75,
        matchedVintage: 2015,
        matchType: .fuzzyName,
        listPrice: nil
    )

    static let previewNoMatch = RecognizedWine(
        originalText: "Some Unknown Wine 2020",
        boundingBox: CGRect(x: 0.1, y: 0.7, width: 0.7, height: 0.05),
        ocrConfidence: 0.92,
        matchedWine: nil,
        matchConfidence: 0,
        matchedVintage: nil,
        matchType: .noMatch,
        listPrice: 45.00
    )
}
#endif
