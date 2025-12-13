import Foundation

final class WineAPIClient {
    // MARK: - Singleton

    static let shared = WineAPIClient()

    // MARK: - Properties

    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    // MARK: - Initialization

    private init() {
        self.baseURL = URL(string: AppConfiguration.apiBaseURL)!

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = AppConfiguration.apiTimeoutSeconds
        config.timeoutIntervalForResource = 30
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)

        self.decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        self.encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.keyEncodingStrategy = .convertToSnakeCase
    }

    // MARK: - Wine Search

    struct SearchResult {
        let wine: Wine
        let confidence: Double
    }

    func searchWines(
        query: String,
        vintage: Int? = nil,
        color: WineColor? = nil,
        minScore: Int? = nil,
        limit: Int = 10
    ) async throws -> [SearchResult] {
        var components = URLComponents(url: baseURL.appendingPathComponent("wines/search"), resolvingAgainstBaseURL: false)!

        var queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "fuzzy", value: "true"),
            URLQueryItem(name: "limit", value: String(limit))
        ]

        if let vintage = vintage {
            queryItems.append(URLQueryItem(name: "vintage", value: String(vintage)))
        }
        if let color = color {
            queryItems.append(URLQueryItem(name: "color", value: color.rawValue))
        }
        if let minScore = minScore {
            queryItems.append(URLQueryItem(name: "min_score", value: String(minScore)))
        }

        components.queryItems = queryItems

        #if DEBUG
        print("🌐 WineAPIClient.searchWines - URL: \(components.url?.absoluteString ?? "nil")")
        #endif

        let request = try await authorizedRequest(url: components.url!)
        let (data, response) = try await session.data(for: request)

        try validateResponse(response)

        #if DEBUG
        if let httpResponse = response as? HTTPURLResponse {
            print("🌐 WineAPIClient.searchWines - Response status: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("🌐 WineAPIClient.searchWines - Response data (first 500 chars): \(responseString.prefix(500))")
            }
        }
        #endif

        let apiResponse = try decoder.decode(SearchResponse.self, from: data)
        
        #if DEBUG
        print("🌐 WineAPIClient.searchWines - Decoded \(apiResponse.data.results.count) results")
        if let first = apiResponse.data.results.first {
            let w = first.wine
            print("   Sample wine: \(w.producer) \(w.name)")
            print("   - Has labelUrl: \(w.labelUrl != nil), value: \(w.labelUrl?.prefix(50) ?? "nil")")
            print("   - Has tastingNote: \(w.tastingNote != nil), length: \(w.tastingNote?.count ?? 0)")
            print("   - Has top100Rank: \(w.top100Rank != nil), value: \(w.top100Rank ?? -1)")
        }
        #endif
        
        return apiResponse.data.results.map {
            SearchResult(wine: $0.wine, confidence: $0.matchConfidence)
        }
    }

    struct BatchMatchResult {
        let wine: Wine?
        let confidence: Double
    }
    
    func batchMatch(queries: [String]) async throws -> [String: BatchMatchResult] {
        let url = baseURL.appendingPathComponent("wines/batch-match")

        var request = try await authorizedRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = BatchMatchRequest(queries: queries)
        request.httpBody = try encoder.encode(body)

        let (data, response) = try await session.data(for: request)
        try validateResponse(response)

        let apiResponse = try decoder.decode(BatchMatchResponse.self, from: data)

        var results: [String: BatchMatchResult] = [:]
        for match in apiResponse.data.matches {
            results[match.query] = BatchMatchResult(
                wine: match.matched ? match.wine : nil,
                confidence: match.confidence
            )
        }

        return results
    }

    // MARK: - Wine Details

    func getWine(id: String) async throws -> Wine {
        let url = baseURL.appendingPathComponent("wines/\(id)")
        let request = try await authorizedRequest(url: url)

        let (data, response) = try await session.data(for: request)
        try validateResponse(response)

        let apiResponse = try decoder.decode(WineDetailResponse.self, from: data)
        return apiResponse.data.wine
    }

    // MARK: - User Saved Wines

    func getSavedWines(limit: Int = 50, offset: Int = 0) async throws -> [SavedWine] {
        var components = URLComponents(url: baseURL.appendingPathComponent("users/me/wines"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset))
        ]

        let request = try await authorizedRequest(url: components.url!, requiresAuth: true)
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)

        let apiResponse = try decoder.decode(SavedWinesResponse.self, from: data)
        return apiResponse.data.wines
    }

    func saveWine(wineId: String, notes: String? = nil, context: SavedWine.SaveContext? = nil) async throws -> SavedWine {
        let url = baseURL.appendingPathComponent("users/me/wines")

        var request = try await authorizedRequest(url: url, requiresAuth: true)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = SaveWineRequest(wineId: wineId, notes: notes, context: context)
        request.httpBody = try encoder.encode(body)

        let (data, response) = try await session.data(for: request)
        try validateResponse(response)

        let apiResponse = try decoder.decode(SaveWineResponse.self, from: data)
        return apiResponse.data.savedWine
    }

    func deleteSavedWine(savedId: String) async throws {
        let url = baseURL.appendingPathComponent("users/me/wines/\(savedId)")

        var request = try await authorizedRequest(url: url, requiresAuth: true)
        request.httpMethod = "DELETE"

        let (_, response) = try await session.data(for: request)
        try validateResponse(response)
    }

    // MARK: - Subscription

    func verifySubscription(receiptData: String, transactionId: String) async throws -> Subscription {
        let url = baseURL.appendingPathComponent("subscriptions/verify")

        var request = try await authorizedRequest(url: url, requiresAuth: true)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = VerifySubscriptionRequest(
            store: "app_store",
            receiptData: receiptData,
            transactionId: transactionId
        )
        request.httpBody = try encoder.encode(body)

        let (data, response) = try await session.data(for: request)
        try validateResponse(response)

        let apiResponse = try decoder.decode(VerifySubscriptionResponse.self, from: data)
        return apiResponse.data.subscription
    }

    // MARK: - Helpers

    private func authorizedRequest(url: URL, requiresAuth: Bool = false) async throws -> URLRequest {
        var request = URLRequest(url: url)

        // Always include API key
        request.setValue(AppConfiguration.apiKey, forHTTPHeaderField: "X-API-Key")

        // Include auth token if available and required (access on MainActor)
        let token = await MainActor.run { AuthenticationService.shared.accessToken }
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else if requiresAuth {
            throw APIError.unauthorized
        }

        return request
    }

    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401:
            throw APIError.unauthorized
        case 403:
            throw APIError.forbidden
        case 404:
            throw APIError.notFound
        case 429:
            throw APIError.rateLimited
        case 500...599:
            throw APIError.serverError(httpResponse.statusCode)
        default:
            throw APIError.unknown(httpResponse.statusCode)
        }
    }

    // MARK: - Error Types

    enum APIError: Error, LocalizedError {
        case unauthorized
        case forbidden
        case notFound
        case rateLimited
        case invalidResponse
        case serverError(Int)
        case unknown(Int)

        var errorDescription: String? {
            switch self {
            case .unauthorized:
                return "Please sign in to continue"
            case .forbidden:
                return "You don't have permission to access this"
            case .notFound:
                return "The requested resource was not found"
            case .rateLimited:
                return "Too many requests. Please wait a moment."
            case .invalidResponse:
                return "Invalid server response"
            case .serverError(let code):
                return "Server error (\(code))"
            case .unknown(let code):
                return "Unexpected error (\(code))"
            }
        }
    }
}

// MARK: - API Response Types

private struct SearchResponse: Codable {
    let success: Bool
    let data: SearchData

    struct SearchData: Codable {
        let results: [SearchResultItem]
    }

    struct SearchResultItem: Codable {
        let wine: Wine
        let matchConfidence: Double
        
        enum CodingKeys: String, CodingKey {
            case wine
            case matchConfidence = "match_confidence"
        }
    }
}

private struct BatchMatchRequest: Codable {
    let queries: [String]
}

private struct BatchMatchResponse: Codable {
    let success: Bool
    let data: BatchMatchData

    struct BatchMatchData: Codable {
        let matches: [BatchMatchItem]
    }

    struct BatchMatchItem: Codable {
        let query: String
        let matched: Bool
        let wine: Wine?
        let confidence: Double
    }
}

private struct WineDetailResponse: Codable {
    let success: Bool
    let data: WineData

    struct WineData: Codable {
        let wine: Wine
    }
}

private struct SavedWinesResponse: Codable {
    let success: Bool
    let data: SavedWinesData

    struct SavedWinesData: Codable {
        let wines: [SavedWine]
    }
}

private struct SaveWineRequest: Codable {
    let wineId: String
    let notes: String?
    let context: SavedWine.SaveContext?
}

private struct SaveWineResponse: Codable {
    let success: Bool
    let data: SaveWineData

    struct SaveWineData: Codable {
        let savedWine: SavedWine
    }
}

private struct VerifySubscriptionRequest: Codable {
    let store: String
    let receiptData: String
    let transactionId: String
}

private struct VerifySubscriptionResponse: Codable {
    let success: Bool
    let data: SubscriptionData

    struct SubscriptionData: Codable {
        let subscription: Subscription
    }
}
