import Foundation

struct Wine: Identifiable, Codable, Hashable {
    let id: String
    let producer: String
    let name: String
    let vintage: Int?
    let region: String?
    let subRegion: String?
    let appellation: String?
    let country: String?
    let color: WineColor
    let grapeVarieties: [GrapeVariety]
    let alcohol: Double?
    let score: Int?
    let tastingNote: String? // Made optional - API sometimes returns null
    let reviewer: Reviewer?
    let reviewDate: Date?
    let issueDate: Date?
    let drinkWindowStart: Int?
    let drinkWindowEnd: Int?
    let releasePrice: Decimal?
    let releasePriceCurrency: String?

    // MARK: - Computed Properties

    var fullName: String {
        if let vintage = vintage {
            return "\(producer) \(name) \(vintage)"
        }
        return "\(producer) \(name)"
    }

    var displayName: String {
        if name.lowercased() == producer.lowercased() {
            return name
        }
        return "\(producer) \(name)"
    }

    var isReadyToDrink: Bool {
        guard let start = drinkWindowStart else { return true }
        let currentYear = Calendar.current.component(.year, from: Date())
        return currentYear >= start
    }

    var isPastPrime: Bool {
        guard let end = drinkWindowEnd else { return false }
        let currentYear = Calendar.current.component(.year, from: Date())
        return currentYear > end
    }

    var drinkWindowDisplay: String {
        switch (drinkWindowStart, drinkWindowEnd) {
        case (nil, nil):
            return "Drink now"
        case (let start?, nil):
            return "From \(start)"
        case (nil, let end?):
            return "Until \(end)"
        case (let start?, let end?):
            if start == end {
                return "\(start)"
            }
            return "\(start)-\(end)"
        }
    }

    var drinkWindowStatus: DrinkWindowStatus {
        let currentYear = Calendar.current.component(.year, from: Date())

        guard let start = drinkWindowStart else {
            return .ready
        }

        if currentYear < start {
            return .tooYoung
        }

        if let end = drinkWindowEnd, currentYear > end {
            return .pastPrime
        }

        if let end = drinkWindowEnd, currentYear >= end - 2 {
            return .peaking
        }

        return .ready
    }

    var releasePriceDisplay: String? {
        guard let price = releasePrice else { return nil }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = releasePriceCurrency ?? "USD"
        return formatter.string(from: price as NSDecimalNumber)
    }

    var scoreCategory: ScoreCategory? {
        guard let score = score else { return nil }
        return ScoreCategory(score: score)
    }

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case id
        case producer
        case name
        case vintage
        case region
        case subRegion = "sub_region"
        case appellation
        case country
        case color
        case grapeVarieties = "grape_varieties"
        case alcohol
        case score
        case tastingNote = "tasting_note"
        case reviewer
        case reviewDate = "review_date"
        case issueDate = "issue_date"
        case drinkWindowStart = "drink_window_start"
        case drinkWindowEnd = "drink_window_end"
        case releasePrice = "release_price"
        case releasePriceCurrency = "release_price_currency"
    }

    // MARK: - Memberwise Initializer (for preview code and manual creation)

    init(
        id: String,
        producer: String,
        name: String,
        vintage: Int?,
        region: String?,
        subRegion: String?,
        appellation: String?,
        country: String?,
        color: WineColor,
        grapeVarieties: [GrapeVariety],
        alcohol: Double?,
        score: Int?,
        tastingNote: String?,
        reviewer: Reviewer?,
        reviewDate: Date?,
        issueDate: Date?,
        drinkWindowStart: Int?,
        drinkWindowEnd: Int?,
        releasePrice: Decimal?,
        releasePriceCurrency: String?
    ) {
        self.id = id
        self.producer = producer
        self.name = name
        self.vintage = vintage
        self.region = region
        self.subRegion = subRegion
        self.appellation = appellation
        self.country = country
        self.color = color
        self.grapeVarieties = grapeVarieties
        self.alcohol = alcohol
        self.score = score
        self.tastingNote = tastingNote
        self.reviewer = reviewer
        self.reviewDate = reviewDate
        self.issueDate = issueDate
        self.drinkWindowStart = drinkWindowStart
        self.drinkWindowEnd = drinkWindowEnd
        self.releasePrice = releasePrice
        self.releasePriceCurrency = releasePriceCurrency
    }

    // MARK: - Custom Decoding

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        producer = try container.decode(String.self, forKey: .producer)
        name = try container.decode(String.self, forKey: .name)
        vintage = try container.decodeIfPresent(Int.self, forKey: .vintage)
        region = try container.decodeIfPresent(String.self, forKey: .region)
        subRegion = try container.decodeIfPresent(String.self, forKey: .subRegion)
        appellation = try container.decodeIfPresent(String.self, forKey: .appellation)
        country = try container.decodeIfPresent(String.self, forKey: .country)
        color = try container.decodeIfPresent(WineColor.self, forKey: .color) ?? .red
        grapeVarieties = try container.decodeIfPresent([GrapeVariety].self, forKey: .grapeVarieties) ?? []
        alcohol = try container.decodeIfPresent(Double.self, forKey: .alcohol)
        score = try container.decodeIfPresent(Int.self, forKey: .score)
        tastingNote = try container.decodeIfPresent(String.self, forKey: .tastingNote)
        reviewer = try container.decodeIfPresent(Reviewer.self, forKey: .reviewer)
        reviewDate = try container.decodeIfPresent(Date.self, forKey: .reviewDate)
        issueDate = try container.decodeIfPresent(Date.self, forKey: .issueDate)
        drinkWindowStart = try container.decodeIfPresent(Int.self, forKey: .drinkWindowStart)
        drinkWindowEnd = try container.decodeIfPresent(Int.self, forKey: .drinkWindowEnd)
        releasePrice = try container.decodeIfPresent(Decimal.self, forKey: .releasePrice)
        releasePriceCurrency = try container.decodeIfPresent(String.self, forKey: .releasePriceCurrency)
    }

    // MARK: - Encoding

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(producer, forKey: .producer)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(vintage, forKey: .vintage)
        try container.encodeIfPresent(region, forKey: .region)
        try container.encodeIfPresent(subRegion, forKey: .subRegion)
        try container.encodeIfPresent(appellation, forKey: .appellation)
        try container.encodeIfPresent(country, forKey: .country)
        try container.encode(color, forKey: .color)
        try container.encode(grapeVarieties, forKey: .grapeVarieties)
        try container.encodeIfPresent(alcohol, forKey: .alcohol)
        try container.encodeIfPresent(score, forKey: .score)
        try container.encodeIfPresent(tastingNote, forKey: .tastingNote)
        try container.encodeIfPresent(reviewer, forKey: .reviewer)
        try container.encodeIfPresent(reviewDate, forKey: .reviewDate)
        try container.encodeIfPresent(issueDate, forKey: .issueDate)
        try container.encodeIfPresent(drinkWindowStart, forKey: .drinkWindowStart)
        try container.encodeIfPresent(drinkWindowEnd, forKey: .drinkWindowEnd)
        try container.encodeIfPresent(releasePrice, forKey: .releasePrice)
        try container.encodeIfPresent(releasePriceCurrency, forKey: .releasePriceCurrency)
    }
}

// MARK: - Supporting Types

enum WineColor: String, Codable, CaseIterable {
    case red
    case white
    case rose
    case sparkling
    case dessert
    case fortified

    var displayName: String {
        switch self {
        case .red: return "Red"
        case .white: return "White"
        case .rose: return "Rosé"
        case .sparkling: return "Sparkling"
        case .dessert: return "Dessert"
        case .fortified: return "Fortified"
        }
    }

    var iconName: String {
        switch self {
        case .red: return "drop.fill"
        case .white: return "drop"
        case .rose: return "drop.halffull"
        case .sparkling: return "bubbles.and.sparkles"
        case .dessert: return "drop.degreesign.fill"
        case .fortified: return "drop.triangle.fill"
        }
    }
}

struct GrapeVariety: Codable, Hashable {
    let name: String
    let percentage: Int?
}

struct Reviewer: Codable, Hashable {
    let initials: String
    let name: String?
}

enum DrinkWindowStatus {
    case tooYoung
    case ready
    case peaking
    case pastPrime

    var displayText: String {
        switch self {
        case .tooYoung: return "Too Young"
        case .ready: return "Ready"
        case .peaking: return "Peaking"
        case .pastPrime: return "Past Prime"
        }
    }

    var iconName: String {
        switch self {
        case .tooYoung: return "hourglass"
        case .ready: return "checkmark.circle.fill"
        case .peaking: return "star.fill"
        case .pastPrime: return "exclamationmark.triangle.fill"
        }
    }
}

enum ScoreCategory {
    case outstanding   // 95-100
    case excellent     // 90-94
    case veryGood      // 85-89
    case good          // 80-84
    case acceptable    // 75-79
    case belowAverage  // <75

    init(score: Int) {
        switch score {
        case 95...100: self = .outstanding
        case 90...94: self = .excellent
        case 85...89: self = .veryGood
        case 80...84: self = .good
        case 75...79: self = .acceptable
        default: self = .belowAverage
        }
    }

    var displayName: String {
        switch self {
        case .outstanding: return "Outstanding"
        case .excellent: return "Excellent"
        case .veryGood: return "Very Good"
        case .good: return "Good"
        case .acceptable: return "Acceptable"
        case .belowAverage: return "Below Average"
        }
    }
}

// MARK: - Preview Helpers

#if DEBUG
extension Wine {
    static let preview = Wine(
        id: "wine_preview_001",
        producer: "Opus One",
        name: "Opus One",
        vintage: 2019,
        region: "Napa Valley",
        subRegion: "Oakville",
        appellation: "Oakville AVA",
        country: "USA",
        color: .red,
        grapeVarieties: [
            GrapeVariety(name: "Cabernet Sauvignon", percentage: 84),
            GrapeVariety(name: "Merlot", percentage: 6),
            GrapeVariety(name: "Cabernet Franc", percentage: 6)
        ],
        alcohol: 14.5,
        score: 97,
        tastingNote: "Powerful and polished, with a gorgeous core of black currant, violet and dark chocolate flavors that are layered with singed alder, roasted coffee bean and warm stone notes. The finish extends, delivering echoes of dark fruit and spice as the fine-grained tannins clamp down.",
        reviewer: Reviewer(initials: "JL", name: "James Laube"),
        reviewDate: Date(),
        issueDate: Date(),
        drinkWindowStart: 2024,
        drinkWindowEnd: 2045,
        releasePrice: 425.00,
        releasePriceCurrency: "USD"
    )

    static let previewWhite = Wine(
        id: "wine_preview_002",
        producer: "Cloudy Bay",
        name: "Sauvignon Blanc",
        vintage: 2023,
        region: "Marlborough",
        subRegion: nil,
        appellation: nil,
        country: "New Zealand",
        color: .white,
        grapeVarieties: [GrapeVariety(name: "Sauvignon Blanc", percentage: 100)],
        alcohol: 13.0,
        score: 91,
        tastingNote: "Crisp and refreshing, with vibrant citrus and tropical fruit flavors.",
        reviewer: Reviewer(initials: "MG", name: nil),
        reviewDate: Date(),
        issueDate: nil,
        drinkWindowStart: 2024,
        drinkWindowEnd: 2026,
        releasePrice: 28.00,
        releasePriceCurrency: "USD"
    )
}
#endif
