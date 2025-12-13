import Foundation

struct SavedWine: Identifiable, Codable {
    let id: String
    let wine: Wine
    let addedAt: Date
    var notes: String?
    var context: SaveContext?

    struct SaveContext: Codable {
        var restaurant: String?
        var pricePaid: Decimal?
        var date: Date?
        var rating: Int?  // User's personal rating 1-5

        var pricePaidDisplay: String? {
            guard let price = pricePaid else { return nil }
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = "USD"
            return formatter.string(from: price as NSDecimalNumber)
        }

        enum CodingKeys: String, CodingKey {
            case restaurant
            case pricePaid
            case date
            case rating
        }
    }

    enum CodingKeys: String, CodingKey {
        case id
        case wine
        case addedAt
        case notes
        case context
    }
}

// MARK: - Preview Helpers

#if DEBUG
extension SavedWine {
    static let preview = SavedWine(
        id: "saved_preview_001",
        wine: Wine.preview,
        addedAt: Date(),
        notes: "Had this at Michael's birthday dinner. Absolutely stunning!",
        context: SavedWine.SaveContext(
            restaurant: "The French Laundry",
            pricePaid: 650.00,
            date: Date(),
            rating: 5
        )
    )
}
#endif
