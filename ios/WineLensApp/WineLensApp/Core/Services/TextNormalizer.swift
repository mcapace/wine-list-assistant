import Foundation

/// Enhanced text normalizer for wine list matching
/// Handles OCR errors, language variations, abbreviations, and spelling mistakes
final class TextNormalizer {
    static let shared = TextNormalizer()
    
    private init() {}
    
    // MARK: - Main Normalization
    
    /// Normalize text for matching, handling OCR errors, language variations, and abbreviations
    func normalize(_ text: String) -> String {
        var normalized = text
        
        // Step 1: Fix common OCR errors first (before lowercasing)
        normalized = fixOCRErrors(normalized)
        
        // Step 2: Lowercase and remove diacritics
        normalized = normalized
            .lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)
        
        // Step 3: Expand abbreviations
        normalized = expandAbbreviations(normalized)
        
        // Step 4: Normalize producer name variations
        normalized = normalizeProducerNames(normalized)
        
        // Step 5: Remove special characters and normalize spacing
        normalized = normalized
            .replacingOccurrences(of: #"[^\w\s]"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
        
        return normalized
    }
    
    // MARK: - OCR Error Correction
    
    /// Fix common OCR character recognition errors
    private func fixOCRErrors(_ text: String) -> String {
        var fixed = text
        
        // Common OCR substitutions (context-aware where possible)
        let ocrCorrections: [(pattern: String, replacement: String, options: NSRegularExpression.Options)] = [
            // Numbers that look like letters (in word context)
            (#"\b0([a-z])", "O$1", []),  // "0pus" -> "Opus"
            (#"\b1([a-z])", "I$1", []),  // "1nst" -> "Inst"
            (#"([a-z])0([a-z])", "$1O$2", []),  // "w0rd" -> "wOrd" (less aggressive)
            (#"([a-z])1([a-z])", "$1I$2", []),  // "w1ne" -> "wIne"
            
            // Letters that look like numbers (in word context)
            (#"\bO(\d)", "0$1", []),  // "O2019" -> "02019" (but we'll extract vintage separately)
            
            // Common single-character OCR errors
            ("5", "S", []),  // "5auvignon" -> "Sauvignon" (but only in certain contexts)
            ("8", "B", []),  // Less common but happens
            ("6", "G", []),  // Less common
            
            // Common multi-character patterns
            ("rn", "m", []),  // "rn" often misread as "m"
            ("vv", "w", []),  // "vv" often misread as "w"
            ("cl", "d", []),  // In certain fonts
        ]
        
        // Apply corrections (be careful with order)
        for (pattern, replacement, options) in ocrCorrections {
            if let regex = try? NSRegularExpression(pattern: pattern, options: options) {
                let range = NSRange(fixed.startIndex..., in: fixed)
                fixed = regex.stringByReplacingMatches(in: fixed, options: [], range: range, withTemplate: replacement)
            }
        }
        
        return fixed
    }
    
    // MARK: - Abbreviation Expansion
    
    /// Expand common wine-related abbreviations
    private func expandAbbreviations(_ text: String) -> String {
        var expanded = text
        
        // Comprehensive abbreviation dictionary
        let abbreviations: [String: String] = [
            // Producer prefixes
            "ch.": "chateau",
            "ch ": "chateau ",
            "cht.": "chateau",
            "cht ": "chateau ",
            "château": "chateau",
            "chateau": "chateau",
            "dom.": "domaine",
            "dom ": "domaine ",
            "domaine": "domaine",
            "est.": "estate",
            "est ": "estate ",
            "estate": "estate",
            "vyd": "vineyard",
            "vnyd": "vineyard",
            "v'yd": "vineyard",
            "vineyard": "vineyard",
            
            // Grape varieties
            "cab": "cabernet",
            "cab sauv": "cabernet sauvignon",
            "cs": "cabernet sauvignon",
            "cabernet sauv": "cabernet sauvignon",
            "sauv": "sauvignon",
            "sb": "sauvignon blanc",
            "sauv blanc": "sauvignon blanc",
            "chard": "chardonnay",
            "pn": "pinot noir",
            "pg": "pinot grigio",
            "pinot g": "pinot grigio",
            "zin": "zinfandel",
            "zinf": "zinfandel",
            "syrah": "syrah",
            "shiraz": "syrah",
            "merlot": "merlot",
            "malbec": "malbec",
            "riesling": "riesling",
            "gewurz": "gewurztraminer",
            "gewürztraminer": "gewurztraminer",
            "viognier": "viognier",
            "semillon": "semillon",
            "sémillon": "semillon",
            "grenache": "grenache",
            "tempranillo": "tempranillo",
            "sangiovese": "sangiovese",
            "nebbiolo": "nebbiolo",
            "barbera": "barbera",
            "dolcetto": "dolcetto",
            "vermentino": "vermentino",
            "albarino": "albarino",
            "albariño": "albarino",
            "gruner": "gruner veltliner",
            "grüner": "gruner veltliner",
            "moscato": "moscato",
            
            // Wine types
            "nv": "non-vintage",
            "n.v.": "non-vintage",
            "non vintage": "non-vintage",
            "brut": "brut",
            "sec": "sec",
            "demi sec": "demi-sec",
            "demi-sec": "demi-sec",
            "doux": "doux",
            
            // Regions
            "bdx": "bordeaux",
            "burg": "burgundy",
            "bourgogne": "burgundy",
            "cote": "cote",
            "côte": "cote",
            "cotes": "cotes",
            "côtes": "cotes",
            "rhone": "rhone",
            "rhône": "rhone",
            "loire": "loire",
            "champagne": "champagne",
            "alsace": "alsace",
            "provence": "provence",
            "tuscany": "tuscany",
            "toscana": "tuscany",
            "piedmont": "piedmont",
            "piemonte": "piedmont",
            "rioja": "rioja",
            "ribera": "ribera del duero",
            "ribera del duero": "ribera del duero",
            "napa": "napa valley",
            "sonoma": "sonoma",
            
            // Quality indicators
            "rsv": "reserve",
            "res": "reserve",
            "res.": "reserve",
            "reserve": "reserve",
            "reserva": "reserve",
            "riserva": "reserve",
            "grand cru": "grand cru",
            "premier cru": "premier cru",
            "1er cru": "premier cru",
            "1er": "premier cru",
            "gc": "grand cru",
            "pc": "premier cru",
            
            // Blends
            "gsm": "grenache syrah mourvedre",
            "cdp": "chateauneuf du pape",
            "chateauneuf": "chateauneuf du pape",
            "châteauneuf": "chateauneuf du pape",
            
            // Serving sizes
            "btl": "bottle",
            "gls": "glass",
            "bottle": "bottle",
            "glass": "glass",
        ]
        
        // Sort by length (longest first) to avoid partial matches
        let sortedAbbrevs = abbreviations.sorted { $0.key.count > $1.key.count }
        
        for (abbrev, full) in sortedAbbrevs {
            // Use word boundaries to avoid partial matches
            let pattern = #"\b"# + NSRegularExpression.escapedPattern(for: abbrev) + #"\b"#
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(expanded.startIndex..., in: expanded)
                expanded = regex.stringByReplacingMatches(in: expanded, options: [], range: range, withTemplate: full)
            }
        }
        
        return expanded
    }
    
    // MARK: - Producer Name Normalization
    
    /// Normalize common producer name variations
    private func normalizeProducerNames(_ text: String) -> String {
        var normalized = text
        
        // Common producer name patterns
        let producerPatterns: [(pattern: String, replacement: String)] = [
            // Remove common suffixes that don't affect matching
            (#"\s+estate\s*$", ""),
            (#"\s+vineyards?\s*$", ""),
            (#"\s+winery\s*$", ""),
            (#"\s+cellars?\s*$", ""),
            
            // Normalize "and" variations
            (" & ", " and "),
            (" &amp; ", " and "),
            (" + ", " and "),
            
            // Normalize possessive forms
            ("'s ", " "),
            ("' ", " "),
        ]
        
        for (pattern, replacement) in producerPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(normalized.startIndex..., in: normalized)
                normalized = regex.stringByReplacingMatches(in: normalized, options: [], range: range, withTemplate: replacement)
            }
        }
        
        return normalized
    }
    
    // MARK: - Phonetic Matching
    
    /// Generate a phonetic key for fuzzy matching (simplified Soundex)
    func phoneticKey(_ text: String) -> String {
        let normalized = normalize(text)
        guard !normalized.isEmpty else { return "" }
        
        // Simplified phonetic encoding
        var key = String(normalized.prefix(1).uppercased())
        let rest = normalized.dropFirst()
        
        let phoneticMap: [Character: String] = [
            "b": "1", "f": "1", "p": "1", "v": "1",
            "c": "2", "g": "2", "j": "2", "k": "2", "q": "2", "s": "2", "x": "2", "z": "2",
            "d": "3", "t": "3",
            "l": "4",
            "m": "5", "n": "5",
            "r": "6"
        ]
        
        var lastCode = ""
        for char in rest {
            if let code = phoneticMap[char] {
                if code != lastCode {
                    key += code
                    lastCode = code
                }
            }
        }
        
        // Pad to 4 characters
        while key.count < 4 {
            key += "0"
        }
        
        return String(key.prefix(4))
    }
    
    // MARK: - Similarity Scoring
    
    /// Calculate similarity between two normalized strings
    func similarity(_ s1: String, _ s2: String) -> Double {
        let norm1 = normalize(s1)
        let norm2 = normalize(s2)
        
        // Exact match
        if norm1 == norm2 {
            return 1.0
        }
        
        // Token-based similarity (Jaccard)
        let tokens1 = Set(norm1.split(separator: " ").map(String.init))
        let tokens2 = Set(norm2.split(separator: " ").map(String.init))
        
        let intersection = tokens1.intersection(tokens2).count
        let union = tokens1.union(tokens2).count
        let tokenSimilarity = union > 0 ? Double(intersection) / Double(union) : 0
        
        // Edit distance similarity
        let editDistance = levenshteinDistance(norm1, norm2)
        let maxLength = max(norm1.count, norm2.count)
        let editSimilarity = maxLength > 0 ? 1.0 - (Double(editDistance) / Double(maxLength)) : 0
        
        // Phonetic similarity (bonus if phonetic keys match)
        let phonetic1 = phoneticKey(s1)
        let phonetic2 = phoneticKey(s2)
        let phoneticBonus = phonetic1 == phonetic2 && !phonetic1.isEmpty ? 0.1 : 0
        
        // Weighted combination
        return min(1.0, (tokenSimilarity * 0.5) + (editSimilarity * 0.4) + phoneticBonus)
    }
    
    // MARK: - Levenshtein Distance
    
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
}

