import Foundation

struct User: Identifiable, Codable {
    let id: String
    let email: String
    let firstName: String?
    let lastName: String?
    let subscription: Subscription
    let stats: UserStats
    let preferences: UserPreferences
    let createdAt: Date

    var displayName: String {
        if let firstName = firstName {
            if let lastName = lastName {
                return "\(firstName) \(lastName)"
            }
            return firstName
        }
        return email
    }

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case firstName = "first_name"
        case lastName = "last_name"
        case subscription
        case stats
        case preferences
        case createdAt = "created_at"
    }
}

struct Subscription: Codable {
    let tier: SubscriptionTier
    let status: SubscriptionStatus
    let expiresAt: Date?
    let autoRenew: Bool
    let store: PurchaseStore?
    let productId: String?

    var isActive: Bool {
        status == .active
    }

    var isPremium: Bool {
        tier == .premium && isActive
    }

    enum CodingKeys: String, CodingKey {
        case tier
        case status
        case expiresAt = "expires_at"
        case autoRenew = "auto_renew"
        case store
        case productId = "product_id"
    }
}

enum SubscriptionTier: String, Codable {
    case free
    case premium
    case business

    var displayName: String {
        switch self {
        case .free: return "Free"
        case .premium: return "Premium"
        case .business: return "Business"
        }
    }

    var scansPerMonth: Int? {
        switch self {
        case .free: return AppConfiguration.freeScansPerMonth
        case .premium: return nil  // Unlimited
        case .business: return nil
        }
    }
}

enum SubscriptionStatus: String, Codable {
    case active
    case expired
    case cancelled
    case pending

    var displayName: String {
        switch self {
        case .active: return "Active"
        case .expired: return "Expired"
        case .cancelled: return "Cancelled"
        case .pending: return "Pending"
        }
    }
}

enum PurchaseStore: String, Codable {
    case appStore = "app_store"
    case playStore = "play_store"
    case web
}

struct UserStats: Codable {
    let winesSaved: Int
    let scansThisMonth: Int
    let totalScans: Int
    let memberSince: Date

    enum CodingKeys: String, CodingKey {
        case winesSaved = "wines_saved"
        case scansThisMonth = "scans_this_month"
        case totalScans = "total_scans"
        case memberSince = "member_since"
    }
}

struct UserPreferences: Codable {
    var preferredRegions: [String]
    var minScoreFilter: Int?
    var notificationsEnabled: Bool
    var hapticFeedbackEnabled: Bool
    var autoFilterEnabled: Bool

    enum CodingKeys: String, CodingKey {
        case preferredRegions = "preferred_regions"
        case minScoreFilter = "min_score_filter"
        case notificationsEnabled = "notifications_enabled"
        case hapticFeedbackEnabled = "haptic_feedback_enabled"
        case autoFilterEnabled = "auto_filter_enabled"
    }

    static let `default` = UserPreferences(
        preferredRegions: [],
        minScoreFilter: nil,
        notificationsEnabled: true,
        hapticFeedbackEnabled: true,
        autoFilterEnabled: false
    )
}

// MARK: - Preview Helpers

#if DEBUG
extension User {
    static let preview = User(
        id: "user_preview_001",
        email: "wine.lover@example.com",
        firstName: "Michael",
        lastName: "Wine",
        subscription: Subscription(
            tier: .premium,
            status: .active,
            expiresAt: Calendar.current.date(byAdding: .month, value: 6, to: Date()),
            autoRenew: true,
            store: .appStore,
            productId: "com.winespec.winelens.premium.yearly"
        ),
        stats: UserStats(
            winesSaved: 47,
            scansThisMonth: 12,
            totalScans: 156,
            memberSince: Calendar.current.date(byAdding: .year, value: -1, to: Date())!
        ),
        preferences: .default,
        createdAt: Calendar.current.date(byAdding: .year, value: -1, to: Date())!
    )

    static let previewFree = User(
        id: "user_preview_002",
        email: "casual@example.com",
        firstName: "Jane",
        lastName: nil,
        subscription: Subscription(
            tier: .free,
            status: .active,
            expiresAt: nil,
            autoRenew: false,
            store: nil,
            productId: nil
        ),
        stats: UserStats(
            winesSaved: 5,
            scansThisMonth: 3,
            totalScans: 8,
            memberSince: Date()
        ),
        preferences: .default,
        createdAt: Date()
    )
}
#endif
