import Foundation

struct ScanResult: Identifiable {
    let id: UUID
    let timestamp: Date
    let recognizedWines: [RecognizedWine]
    let processingTimeMs: Int
    let imageData: Data?

    // MARK: - Computed Properties

    var matchedWines: [RecognizedWine] {
        recognizedWines.filter { $0.isMatched }
    }

    var unmatchedWines: [RecognizedWine] {
        recognizedWines.filter { !$0.isMatched }
    }

    var matchRate: Double {
        guard !recognizedWines.isEmpty else { return 0 }
        return Double(matchedWines.count) / Double(recognizedWines.count)
    }

    var averageScore: Double? {
        let scores = matchedWines.compactMap { $0.matchedWine?.score }
        guard !scores.isEmpty else { return nil }
        return Double(scores.reduce(0, +)) / Double(scores.count)
    }

    var highestScoredWine: RecognizedWine? {
        matchedWines.max { ($0.matchedWine?.score ?? 0) < ($1.matchedWine?.score ?? 0) }
    }

    var bestValueWine: RecognizedWine? {
        matchedWines.filter { $0.isBestValue }.first
    }

    // MARK: - Summary

    var summary: ScanSummary {
        ScanSummary(
            totalWines: recognizedWines.count,
            matchedWines: matchedWines.count,
            matchRate: matchRate,
            averageScore: averageScore,
            scoreDistribution: scoreDistribution,
            processingTimeMs: processingTimeMs
        )
    }

    var scoreDistribution: [ScoreCategory: Int] {
        var distribution: [ScoreCategory: Int] = [:]
        for wine in matchedWines {
            guard let score = wine.matchedWine?.score else { continue }
            let category = ScoreCategory(score: score)
            distribution[category, default: 0] += 1
        }
        return distribution
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        recognizedWines: [RecognizedWine],
        processingTimeMs: Int,
        imageData: Data? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.recognizedWines = recognizedWines
        self.processingTimeMs = processingTimeMs
        self.imageData = imageData
    }
}

struct ScanSummary: Codable {
    let totalWines: Int
    let matchedWines: Int
    let matchRate: Double
    let averageScore: Double?
    let scoreDistribution: [String: Int]  // String keys for Codable
    let processingTimeMs: Int

    init(
        totalWines: Int,
        matchedWines: Int,
        matchRate: Double,
        averageScore: Double?,
        scoreDistribution: [ScoreCategory: Int],
        processingTimeMs: Int
    ) {
        self.totalWines = totalWines
        self.matchedWines = matchedWines
        self.matchRate = matchRate
        self.averageScore = averageScore
        self.scoreDistribution = Dictionary(
            uniqueKeysWithValues: scoreDistribution.map { ($0.key.displayName, $0.value) }
        )
        self.processingTimeMs = processingTimeMs
    }
}

// MARK: - Preview Helpers

#if DEBUG
extension ScanResult {
    static let preview = ScanResult(
        recognizedWines: [
            RecognizedWine.preview,
            RecognizedWine.previewLowConfidence,
            RecognizedWine.previewNoMatch
        ],
        processingTimeMs: 450
    )
}
#endif
