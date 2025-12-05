import Foundation

actor LocalWineCache {
    // MARK: - Singleton

    static let shared = LocalWineCache()

    // MARK: - Types

    struct FuzzyMatchResult {
        let wine: Wine
        let score: Double
    }

    // MARK: - Storage

    private var wineCache: [String: Wine] = [:]  // id -> Wine
    private var searchIndex: [String: Set<String>] = [:]  // normalized term -> wine ids
    private let cacheURL: URL

    // MARK: - Initialization

    private init() {
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheURL = cacheDir.appendingPathComponent("wine_cache.json")

        // Load cached wines from disk
        Task {
            await loadFromDisk()
        }
    }

    // MARK: - Cache Operations

    func cache(wine: Wine) {
        wineCache[wine.id] = wine
        indexWine(wine)
    }

    func cache(wines: [Wine]) {
        for wine in wines {
            wineCache[wine.id] = wine
            indexWine(wine)
        }

        // Save periodically
        Task {
            await saveToDisk()
        }
    }

    func getWine(id: String) -> Wine? {
        wineCache[id]
    }

    func clear() {
        wineCache.removeAll()
        searchIndex.removeAll()
        try? FileManager.default.removeItem(at: cacheURL)
    }

    // MARK: - Search

    func findExact(text: String, vintage: Int?) -> Wine? {
        let normalizedText = normalizeForSearch(text)

        for wine in wineCache.values {
            let wineName = normalizeForSearch("\(wine.producer) \(wine.name)")

            if wineName == normalizedText {
                // Check vintage if specified
                if let vintage = vintage {
                    if wine.vintage == vintage {
                        return wine
                    }
                } else {
                    return wine
                }
            }
        }

        return nil
    }

    func findFuzzy(text: String) -> FuzzyMatchResult? {
        let normalizedText = normalizeForSearch(text)
        let searchTerms = Set(normalizedText.split(separator: " ").map(String.init))

        var bestMatch: (wine: Wine, score: Double)?

        // Find wines that share search terms
        var candidateIds = Set<String>()
        for term in searchTerms {
            if let ids = searchIndex[term] {
                candidateIds.formUnion(ids)
            }

            // Also check partial matches
            for (indexTerm, ids) in searchIndex {
                if indexTerm.contains(term) || term.contains(indexTerm) {
                    candidateIds.formUnion(ids)
                }
            }
        }

        // Score each candidate
        for id in candidateIds {
            guard let wine = wineCache[id] else { continue }

            let wineName = normalizeForSearch("\(wine.producer) \(wine.name)")
            let score = calculateSimilarity(normalizedText, wineName)

            if score > (bestMatch?.score ?? 0) {
                bestMatch = (wine, score)
            }
        }

        guard let best = bestMatch, best.score >= 0.5 else {
            return nil
        }

        return FuzzyMatchResult(wine: best.wine, score: best.score)
    }

    // MARK: - Indexing

    private func indexWine(_ wine: Wine) {
        let searchText = normalizeForSearch("\(wine.producer) \(wine.name) \(wine.region)")
        let terms = searchText.split(separator: " ").map(String.init)

        for term in terms where term.count >= 3 {
            searchIndex[term, default: []].insert(wine.id)
        }
    }

    private func normalizeForSearch(_ text: String) -> String {
        text
            .lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)
            .replacingOccurrences(of: #"[^\w\s]"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
    }

    // MARK: - Similarity Scoring

    private func calculateSimilarity(_ s1: String, _ s2: String) -> Double {
        // Use a combination of token overlap and edit distance

        let tokens1 = Set(s1.split(separator: " ").map(String.init))
        let tokens2 = Set(s2.split(separator: " ").map(String.init))

        // Jaccard similarity for tokens
        let intersection = tokens1.intersection(tokens2).count
        let union = tokens1.union(tokens2).count
        let tokenSimilarity = union > 0 ? Double(intersection) / Double(union) : 0

        // Normalized edit distance for full strings
        let editDistance = levenshteinDistance(s1, s2)
        let maxLength = max(s1.count, s2.count)
        let editSimilarity = maxLength > 0 ? 1.0 - (Double(editDistance) / Double(maxLength)) : 0

        // Weighted combination
        return (tokenSimilarity * 0.6) + (editSimilarity * 0.4)
    }

    private func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let s1Array = Array(s1)
        let s2Array = Array(s2)
        let m = s1Array.count
        let n = s2Array.count

        if m == 0 { return n }
        if n == 0 { return m }

        var matrix = [[Int]](repeating: [Int](repeating: 0, count: n + 1), count: m + 1)

        for i in 0...m { matrix[i][0] = i }
        for j in 0...n { matrix[0][j] = j }

        for i in 1...m {
            for j in 1...n {
                let cost = s1Array[i - 1] == s2Array[j - 1] ? 0 : 1
                matrix[i][j] = min(
                    matrix[i - 1][j] + 1,      // deletion
                    matrix[i][j - 1] + 1,      // insertion
                    matrix[i - 1][j - 1] + cost // substitution
                )
            }
        }

        return matrix[m][n]
    }

    // MARK: - Persistence

    private func saveToDisk() {
        do {
            let wines = Array(wineCache.values)
            let data = try JSONEncoder().encode(wines)
            try data.write(to: cacheURL)
        } catch {
            print("Failed to save wine cache: \(error)")
        }
    }

    private func loadFromDisk() {
        guard FileManager.default.fileExists(atPath: cacheURL.path) else {
            return
        }

        do {
            let data = try Data(contentsOf: cacheURL)
            let wines = try JSONDecoder().decode([Wine].self, from: data)
            cache(wines: wines)
        } catch {
            print("Failed to load wine cache: \(error)")
        }
    }
}
