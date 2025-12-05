import Foundation

final class WineMatchingService {
    // MARK: - Types

    struct MatchResult {
        let wine: Wine
        let confidence: Double
        let matchedVintage: Int?
        let matchType: RecognizedWine.MatchType
    }

    struct ParsedWineText {
        let producer: String?
        let wineName: String?
        let vintage: Int?
        let region: String?
        let price: Decimal?
        let normalizedText: String
    }

    // MARK: - Dependencies

    private let apiClient: WineAPIClient
    private let localCache: LocalWineCache

    // MARK: - Initialization

    init(apiClient: WineAPIClient = .shared, localCache: LocalWineCache = .shared) {
        self.apiClient = apiClient
        self.localCache = localCache
    }

    // MARK: - Public Methods

    /// Match a wine text candidate to our database
    func matchWine(from text: String) async -> MatchResult? {
        let parsed = parseWineText(text)

        // Step 1: Try exact match in local cache
        if let exactMatch = await tryExactMatch(parsed) {
            return exactMatch
        }

        // Step 2: Try fuzzy match in local cache
        if let fuzzyMatch = await tryFuzzyMatch(parsed) {
            return fuzzyMatch
        }

        // Step 3: Query API for broader search
        if let apiMatch = await tryAPIMatch(parsed) {
            return apiMatch
        }

        return nil
    }

    /// Batch match multiple wine texts (more efficient for API calls)
    func batchMatch(texts: [String]) async -> [String: MatchResult?] {
        var results: [String: MatchResult?] = [:]

        // First, try local matches
        for text in texts {
            let parsed = parseWineText(text)
            var match: MatchResult?
            if let exactMatch = await tryExactMatch(parsed) {
                match = exactMatch
            } else {
                match = await tryFuzzyMatch(parsed)
            }
            if let match = match {
                results[text] = match
            }
        }

        // For unmatched, try API batch
        let unmatchedTexts = texts.filter { results[$0] == nil }
        if !unmatchedTexts.isEmpty {
            let apiResults = await tryBatchAPIMatch(unmatchedTexts)
            for (text, result) in apiResults {
                results[text] = result
            }
        }

        return results
    }

    // MARK: - Text Parsing

    func parseWineText(_ text: String) -> ParsedWineText {
        var normalized = normalizeText(text)
        let vintage = extractVintage(from: normalized)
        let price = extractPrice(from: text)

        // Remove price from normalized text for matching
        normalized = removePricePattern(from: normalized)

        return ParsedWineText(
            producer: nil,  // TODO: NLP extraction
            wineName: nil,  // TODO: NLP extraction
            vintage: vintage,
            region: nil,    // TODO: NLP extraction
            price: price,
            normalizedText: normalized
        )
    }

    // MARK: - Text Normalization

    private func normalizeText(_ text: String) -> String {
        var normalized = text
            .lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)

        // Expand common abbreviations
        let abbreviations: [String: String] = [
            "ch.": "chateau",
            "ch ": "chateau ",
            "cht.": "chateau",
            "dom.": "domaine",
            "dom ": "domaine ",
            "cab": "cabernet",
            "sauv": "sauvignon",
            "chard": "chardonnay",
            "sb": "sauvignon blanc",
            "cs": "cabernet sauvignon",
            "pn": "pinot noir",
            "pg": "pinot grigio",
            "zin": "zinfandel",
            "rsv": "reserve",
            "res": "reserve",
            "res.": "reserve",
            "vyd": "vineyard",
            "vnyd": "vineyard",
            "v'yd": "vineyard",
            "est": "estate",
            "est.": "estate",
            "btl": "bottle",
            "gls": "glass",
            "nv": "non-vintage",
            "n.v.": "non-vintage",
            "gsm": "grenache syrah mourvedre",
            "bdx": "bordeaux",
            "burg": "burgundy",
            "brut": "brut"
        ]

        for (abbrev, full) in abbreviations {
            normalized = normalized.replacingOccurrences(of: abbrev, with: full)
        }

        // Standardize spacing
        normalized = normalized
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)

        return normalized
    }

    private func extractVintage(from text: String) -> Int? {
        // Match full year (1950-2030)
        let fullYearPattern = #"\b(19[5-9]\d|20[0-3]\d)\b"#
        if let match = text.range(of: fullYearPattern, options: .regularExpression) {
            return Int(text[match])
        }

        // Match abbreviated year ('98, '19, etc.)
        let shortYearPattern = #"'(\d{2})\b"#
        if let regex = try? NSRegularExpression(pattern: shortYearPattern),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let yearRange = Range(match.range(at: 1), in: text) {
            let yearNum = Int(text[yearRange]) ?? 0
            // Assume 50+ is 1900s, under 50 is 2000s
            return yearNum >= 50 ? 1900 + yearNum : 2000 + yearNum
        }

        return nil
    }

    private func extractPrice(from text: String) -> Decimal? {
        // Match $XXX or $XXX.XX patterns
        let pricePattern = #"\$\s*([\d,]+(?:\.\d{2})?)"#

        guard let regex = try? NSRegularExpression(pattern: pricePattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let priceRange = Range(match.range(at: 1), in: text) else {
            return nil
        }

        let priceString = text[priceRange]
            .replacingOccurrences(of: ",", with: "")

        return Decimal(string: String(priceString))
    }

    private func removePricePattern(from text: String) -> String {
        text.replacingOccurrences(
            of: #"\$\s*[\d,]+(?:\.\d{2})?"#,
            with: "",
            options: .regularExpression
        ).trimmingCharacters(in: .whitespaces)
    }

    // MARK: - Matching Strategies

    private func tryExactMatch(_ parsed: ParsedWineText) async -> MatchResult? {
        guard let wine = await localCache.findExact(text: parsed.normalizedText, vintage: parsed.vintage) else {
            return nil
        }

        return MatchResult(
            wine: wine,
            confidence: 0.98,
            matchedVintage: parsed.vintage,
            matchType: .exact
        )
    }

    private func tryFuzzyMatch(_ parsed: ParsedWineText) async -> MatchResult? {
        guard let result = await localCache.findFuzzy(text: parsed.normalizedText) else {
            return nil
        }

        guard result.score >= AppConfiguration.matchConfidenceThreshold else {
            return nil
        }

        return MatchResult(
            wine: result.wine,
            confidence: result.score,
            matchedVintage: parsed.vintage,
            matchType: .fuzzyName
        )
    }

    private func tryAPIMatch(_ parsed: ParsedWineText) async -> MatchResult? {
        do {
            let results = try await apiClient.searchWines(
                query: parsed.normalizedText,
                vintage: parsed.vintage,
                limit: 1
            )

            guard let best = results.first,
                  best.confidence >= AppConfiguration.matchConfidenceThreshold else {
                return nil
            }

            // Cache the result for future searches
            await localCache.cache(wine: best.wine)

            return MatchResult(
                wine: best.wine,
                confidence: best.confidence,
                matchedVintage: parsed.vintage ?? best.wine.vintage,
                matchType: .fuzzyName
            )
        } catch {
            // Don't log cancellation errors - they're expected when new frames arrive
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
                // Request was cancelled, this is normal during rapid scanning
                return nil
            }
            print("API match failed: \(error)")
            return nil
        }
    }

    private func tryBatchAPIMatch(_ texts: [String]) async -> [String: MatchResult?] {
        let parsedTexts = texts.map { (text: $0, parsed: parseWineText($0)) }

        do {
            let queries = parsedTexts.map(\.parsed.normalizedText)
            let apiResults = try await apiClient.batchMatch(queries: queries)

            var results: [String: MatchResult?] = [:]

            for (original, parsed) in parsedTexts {
                if let apiResult = apiResults[parsed.normalizedText],
                   let wine = apiResult,
                   apiResult != nil {
                    results[original] = MatchResult(
                        wine: wine,
                        confidence: 0.85,  // Batch matches have slightly lower confidence
                        matchedVintage: parsed.vintage ?? wine.vintage,
                        matchType: .fuzzyName
                    )

                    // Cache for future
                    await localCache.cache(wine: wine)
                } else {
                    results[original] = nil
                }
            }

            return results
        } catch {
            // Don't log cancellation errors - they're expected when new frames arrive
            let nsError = error as NSError
            if !(nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled) {
                print("Batch API match failed: \(error)")
            }
            return Dictionary(uniqueKeysWithValues: texts.map { ($0, nil as MatchResult?) })
        }
    }
}
