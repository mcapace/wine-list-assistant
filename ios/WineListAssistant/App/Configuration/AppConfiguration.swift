import Foundation

enum AppConfiguration {
    // MARK: - Environment

    enum Environment {
        case development
        case staging
        case production
    }

    #if DEBUG
    static let current: Environment = .development
    #else
    static let current: Environment = .production
    #endif

    // MARK: - API Configuration

    static var apiBaseURL: String {
        switch current {
        case .development:
            return "https://backend-theta-mauve-9kehaxzmz7.vercel.app/api"
        case .staging:
            return "https://backend-theta-mauve-9kehaxzmz7.vercel.app/api"
        case .production:
            return "https://backend-theta-mauve-9kehaxzmz7.vercel.app/api"
        }
    }

    static var apiKey: String {
        // In production, this should be loaded from a secure source
        // For now, placeholder that will be replaced during build
        return Bundle.main.object(forInfoDictionaryKey: "WLA_API_KEY") as? String ?? "wla_pk_dev_placeholder"
    }

    // MARK: - Feature Flags

    static var enableAnalytics: Bool {
        current != .development
    }

    static var enableCrashReporting: Bool {
        current != .development
    }

    // MARK: - App Info

    static var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    static var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }

    // MARK: - Subscription

    static let freeScansPerMonth = 5
    static let subscriptionGroupID = "21234567"  // App Store Connect subscription group ID

    // MARK: - Timeouts

    static let apiTimeoutSeconds: TimeInterval = 10
    static let ocrProcessingIntervalSeconds: TimeInterval = 0.5
    static let matchConfidenceThreshold: Double = 0.7
}
