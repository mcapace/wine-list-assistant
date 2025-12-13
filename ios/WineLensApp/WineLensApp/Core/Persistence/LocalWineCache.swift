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
    private let cacheVersionURL: URL
    private let currentCacheVersion = 2 // Increment when schema changes (added label_url, tasting_note, etc.)

    // MARK: - Initialization

    private init() {
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheURL = cacheDir.appendingPathComponent("wine_cache.json")
        cacheVersionURL = cacheDir.appendingPathComponent("wine_cache_version.txt")

        // Load cached wines from disk (only if version matches)
        Task {
            await loadFromDisk()
        }
    }

    // MARK: - Cache Operations

    func cache(wine: Wine) {
        wineCache[wine.id] = wine
        indexWine(wine)
        
        #if DEBUG
        print("💾 LocalWineCache: Cached wine \(wine.producer) \(wine.name)")
        print("   - Has labelUrl: \(wine.labelUrl != nil)")
        print("   - Has tastingNote: \(wine.tastingNote != nil)")
        print("   - Has top100Rank: \(wine.top100Rank != nil)")
        #endif
    }

    func cache(wines: [Wine]) {
        for wine in wines {
            wineCache[wine.id] = wine
            indexWine(wine)
        }

        #if DEBUG
        print("💾 LocalWineCache: Cached \(wines.count) wines")
        if let first = wines.first {
            print("   Sample: \(first.producer) \(first.name)")
            print("   - Has labelUrl: \(first.labelUrl != nil)")
            print("   - Has tastingNote: \(first.tastingNote != nil)")
        }
        #endif

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
        
        // Remove cache file and version file from disk
        if FileManager.default.fileExists(atPath: cacheURL.path) {
            try? FileManager.default.removeItem(at: cacheURL)
        }
        if FileManager.default.fileExists(atPath: cacheVersionURL.path) {
            try? FileManager.default.removeItem(at: cacheVersionURL)
        }
        
        #if DEBUG
        print("🗑️ LocalWineCache: Cleared cache files and memory")
        #endif
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
            
            // Save cache version
            try String(currentCacheVersion).write(to: cacheVersionURL, atomically: true, encoding: .utf8)
            
            #if DEBUG
            print("💾 LocalWineCache: Saved \(wines.count) wines to disk (version \(currentCacheVersion))")
            #endif
        } catch {
            print("Failed to save wine cache: \(error)")
        }
    }

    private func loadFromDisk() {
        guard FileManager.default.fileExists(atPath: cacheURL.path) else {
            return
        }

        // Check cache version - if it doesn't match, clear old cache
        let savedVersion: Int
        if FileManager.default.fileExists(atPath: cacheVersionURL.path),
           let versionData = try? String(contentsOf: cacheVersionURL),
           let version = Int(versionData.trimmingCharacters(in: .whitespacesAndNewlines)) {
            savedVersion = version
        } else {
            savedVersion = 0
        }

        if savedVersion != currentCacheVersion {
            #if DEBUG
            print("🔄 LocalWineCache: Cache version mismatch (saved: \(savedVersion), current: \(currentCacheVersion)). Clearing old cache.")
            #endif
            clear()
            return
        }

        do {
            let data = try Data(contentsOf: cacheURL)
            let wines = try JSONDecoder().decode([Wine].self, from: data)
            
            #if DEBUG
            print("📂 LocalWineCache: Loaded \(wines.count) wines from disk")
            if let first = wines.first {
                print("   Sample: \(first.producer) \(first.name)")
                print("   - Has labelUrl: \(first.labelUrl != nil)")
                print("   - Has tastingNote: \(first.tastingNote != nil)")
            }
            #endif
            
            cache(wines: wines)
        } catch {
            print("Failed to load wine cache: \(error)")
            // If decoding fails, clear the cache
            clear()
        }
    }
}
