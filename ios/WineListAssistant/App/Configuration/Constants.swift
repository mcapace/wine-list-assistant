import Foundation

enum Constants {
    // MARK: - Storage Keys

    enum StorageKeys {
        static let onboardingComplete = "onboarding_complete"
        static let lastSyncDate = "last_sync_date"
        static let userPreferences = "user_preferences"
        static let scansThisMonth = "scans_this_month"
        static let scansMonthStart = "scans_month_start"
    }

    // MARK: - Keychain Keys

    enum KeychainKeys {
        static let accessToken = "access_token"
        static let refreshToken = "refresh_token"
        static let userId = "user_id"
    }

    // MARK: - Notification Names

    enum Notifications {
        static let subscriptionStatusChanged = Notification.Name("subscriptionStatusChanged")
        static let wineMatched = Notification.Name("wineMatched")
        static let userLoggedIn = Notification.Name("userLoggedIn")
        static let userLoggedOut = Notification.Name("userLoggedOut")
    }

    // MARK: - Score Ranges

    enum ScoreRanges {
        static let outstanding = 95...100
        static let excellent = 90...94
        static let veryGood = 85...89
        static let good = 80...84
        static let acceptable = 75...79
        static let belowAverage = 0...74
    }

    // MARK: - Animation Durations

    enum Animation {
        static let quick: Double = 0.15
        static let standard: Double = 0.3
        static let slow: Double = 0.5
    }

    // MARK: - Camera

    enum Camera {
        static let minimumZoom: CGFloat = 1.0
        static let maximumZoom: CGFloat = 5.0
        static let defaultFrameRate: Int = 30
    }
}
