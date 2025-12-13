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
        // Use the enhanced text normalizer for consistent normalization
        TextNormalizer.shared.normalize(text)
    }

    // MARK: - Similarity Scoring

    private func calculateSimilarity(_ s1: String, _ s2: String) -> Double {
        // Use the enhanced text normalizer's similarity function
        // This includes token overlap, edit distance, and phonetic matching
        return TextNormalizer.shared.similarity(s1, s2)
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
