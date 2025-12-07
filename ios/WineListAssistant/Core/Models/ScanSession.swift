import Foundation
import CoreGraphics

struct ScanSession: Identifiable, Codable {
    let id: UUID
    let startTime: Date
    var wines: [RecognizedWine]
    var location: String? // Restaurant name if provided
    
    var endTime: Date?
    var topScore: Int? {
        wines.compactMap { $0.matchedWine?.score }.max()
    }
    
    var matchedCount: Int {
        wines.filter { $0.isMatched }.count
    }
    
    init(id: UUID = UUID(), startTime: Date = Date(), wines: [RecognizedWine] = [], location: String? = nil, endTime: Date? = nil) {
        self.id = id
        self.startTime = startTime
        self.wines = wines
        self.location = location
        self.endTime = endTime
    }
}

// MARK: - Codable Support for RecognizedWine

extension RecognizedWine: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case originalText
        case boundingBox
        case ocrConfidence
        case matchedWine
        case matchConfidence
        case matchedVintage
        case matchType
        case listPrice
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        originalText = try container.decode(String.self, forKey: .originalText)
        
        // Decode boundingBox (CGFloat values stored as Double for Codable)
        let boxData = try container.decode([String: Double].self, forKey: .boundingBox)
        boundingBox = CGRect(
            x: boxData["x"] ?? 0,
            y: boxData["y"] ?? 0,
            width: boxData["width"] ?? 0,
            height: boxData["height"] ?? 0
        )
        
        ocrConfidence = try container.decode(Float.self, forKey: .ocrConfidence)
        matchedWine = try container.decodeIfPresent(Wine.self, forKey: .matchedWine)
        matchConfidence = try container.decode(Double.self, forKey: .matchConfidence)
        matchedVintage = try container.decodeIfPresent(Int.self, forKey: .matchedVintage)
        matchType = try container.decode(MatchType.self, forKey: .matchType)
        
        // Decode listPrice
        if let priceString = try container.decodeIfPresent(String.self, forKey: .listPrice) {
            listPrice = Decimal(string: priceString)
        } else {
            listPrice = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(originalText, forKey: .originalText)
        
        // Encode boundingBox (convert CGFloat to Double for Codable)
        let boxData: [String: Double] = [
            "x": Double(boundingBox.origin.x),
            "y": Double(boundingBox.origin.y),
            "width": Double(boundingBox.width),
            "height": Double(boundingBox.height)
        ]
        try container.encode(boxData, forKey: .boundingBox)
        
        try container.encode(ocrConfidence, forKey: .ocrConfidence)
        try container.encodeIfPresent(matchedWine, forKey: .matchedWine)
        try container.encode(matchConfidence, forKey: .matchConfidence)
        try container.encodeIfPresent(matchedVintage, forKey: .matchedVintage)
        try container.encode(matchType, forKey: .matchType)
        
        // Encode listPrice
        if let price = listPrice {
            try container.encode(String(describing: price), forKey: .listPrice)
        }
    }
}

extension RecognizedWine.MatchType: Codable {}

