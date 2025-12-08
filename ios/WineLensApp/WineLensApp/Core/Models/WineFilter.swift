import Foundation

enum WineFilter: String, CaseIterable, Identifiable {
    case score95Plus = "95+"
    case score90Plus = "90+"
    case score85Plus = "85+"
    case drinkNow = "drink_now"
    case bestValue = "best_value"
    case redOnly = "red"
    case whiteOnly = "white"
    case sparklingOnly = "sparkling"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .score95Plus: return "95+"
        case .score90Plus: return "90+"
        case .score85Plus: return "85+"
        case .drinkNow: return "Ready Now"
        case .bestValue: return "Best Value"
        case .redOnly: return "Red"
        case .whiteOnly: return "White"
        case .sparklingOnly: return "Sparkling"
        }
    }

    var iconName: String {
        switch self {
        case .score95Plus, .score90Plus, .score85Plus:
            return "star.fill"
        case .drinkNow:
            return "clock.fill"
        case .bestValue:
            return "tag.fill"
        case .redOnly:
            return "drop.fill"
        case .whiteOnly:
            return "drop"
        case .sparklingOnly:
            return "bubbles.and.sparkles"
        }
    }

    var category: FilterCategory {
        switch self {
        case .score95Plus, .score90Plus, .score85Plus:
            return .score
        case .drinkNow:
            return .timing
        case .bestValue:
            return .value
        case .redOnly, .whiteOnly, .sparklingOnly:
            return .type
        }
    }

    enum FilterCategory: String, CaseIterable {
        case score = "Score"
        case timing = "Timing"
        case value = "Value"
        case type = "Type"
    }

    func matches(_ wine: RecognizedWine) -> Bool {
        guard let matchedWine = wine.matchedWine else {
            return false
        }

        switch self {
        case .score95Plus:
            return (matchedWine.score ?? 0) >= 95
        case .score90Plus:
            return (matchedWine.score ?? 0) >= 90
        case .score85Plus:
            return (matchedWine.score ?? 0) >= 85
        case .drinkNow:
            return matchedWine.isReadyToDrink && !matchedWine.isPastPrime
        case .bestValue:
            return wine.isBestValue
        case .redOnly:
            return matchedWine.color == .red
        case .whiteOnly:
            return matchedWine.color == .white
        case .sparklingOnly:
            return matchedWine.color == .sparkling
        }
    }

    static let quickFilters: [WineFilter] = [.score90Plus, .drinkNow, .bestValue]

    static let scoreFilters: [WineFilter] = [.score95Plus, .score90Plus, .score85Plus]

    static let typeFilters: [WineFilter] = [.redOnly, .whiteOnly, .sparklingOnly]
}

struct FilterSet {
    var activeFilters: Set<WineFilter> = []

    var isEmpty: Bool {
        activeFilters.isEmpty
    }

    var count: Int {
        activeFilters.count
    }

    mutating func toggle(_ filter: WineFilter) {
        // For score filters, only allow one at a time
        if filter.category == .score {
            activeFilters = activeFilters.filter { $0.category != .score }
            activeFilters.insert(filter)
        }
        // For type filters, only allow one at a time
        else if filter.category == .type {
            activeFilters = activeFilters.filter { $0.category != .type }
            activeFilters.insert(filter)
        }
        // For other filters, toggle normally
        else if activeFilters.contains(filter) {
            activeFilters.remove(filter)
        } else {
            activeFilters.insert(filter)
        }
    }

    mutating func remove(_ filter: WineFilter) {
        activeFilters.remove(filter)
    }

    mutating func clear() {
        activeFilters.removeAll()
    }

    func contains(_ filter: WineFilter) -> Bool {
        activeFilters.contains(filter)
    }

    func apply(to wines: [RecognizedWine]) -> [RecognizedWine] {
        guard !isEmpty else { return wines }

        return wines.filter { wine in
            activeFilters.allSatisfy { filter in
                filter.matches(wine)
            }
        }
    }
}
