import StoreKit
import Foundation
import Combine

@MainActor
final class SubscriptionService: ObservableObject {
    // MARK: - Singleton

    static let shared = SubscriptionService()

    // MARK: - Published Properties

    @Published private(set) var subscriptionStatus: SubscriptionStatus = .unknown
    @Published private(set) var products: [Product] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var error: SubscriptionError?

    // MARK: - Product IDs

    enum ProductID: String, CaseIterable {
        case monthlyPremium = "com.winespectator.wla.premium.monthly"
        case yearlyPremium = "com.winespectator.wla.premium.yearly"

        var displayName: String {
            switch self {
            case .monthlyPremium: return "Monthly Premium"
            case .yearlyPremium: return "Yearly Premium"
            }
        }
    }

    // MARK: - Status

    enum SubscriptionStatus: Equatable {
        case unknown
        case notSubscribed
        case subscribed(expirationDate: Date?, productId: String)
        case expired

        var isActive: Bool {
            if case .subscribed = self {
                return true
            }
            return false
        }

        var canScan: Bool {
            isActive || self == .notSubscribed  // Free tier has limited scans
        }
    }

    // MARK: - Private Properties

    private var updateTask: Task<Void, Never>?
    private var transactionListener: Task<Void, Never>?

    // MARK: - Initialization

    private init() {
        transactionListener = listenForTransactions()
    }

    deinit {
        updateTask?.cancel()
        transactionListener?.cancel()
    }

    // MARK: - Public Methods

    func loadProducts() async {
        // Check for cancellation
        try? await Task.checkCancellation()
        
        isLoading = true
        defer { isLoading = false }

        do {
            let productIDs = ProductID.allCases.map(\.rawValue)
            products = try await Product.products(for: productIDs)
                .sorted { $0.price < $1.price }
        } catch {
            // Don't set error if task was cancelled
            if !Task.isCancelled {
                self.error = .failedToLoadProducts
                print("Failed to load products: \(error)")
            }
        }
    }

    func purchase(_ product: Product) async throws -> Bool {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await updateSubscriptionStatus()
                await transaction.finish()

                // Verify with our backend
                await verifyWithBackend(transaction)

                return true

            case .userCancelled:
                return false

            case .pending:
                // Transaction is pending approval (e.g., Ask to Buy)
                return false

            @unknown default:
                return false
            }
        } catch StoreKitError.userCancelled {
            return false
        } catch {
            self.error = .purchaseFailed
            throw error
        }
    }

    func restorePurchases() async throws {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
        } catch {
            self.error = .restoreFailed
            throw error
        }
    }

    func updateSubscriptionStatus() async {
        // Check for cancellation
        try? await Task.checkCancellation()
        
        var foundSubscription = false

        for await result in Transaction.currentEntitlements {
            // Check for cancellation in the loop
            if Task.isCancelled {
                return
            }
            
            guard case .verified(let transaction) = result else {
                continue
            }

            if transaction.productType == .autoRenewable &&
               ProductID.allCases.map(\.rawValue).contains(transaction.productID) {

                subscriptionStatus = .subscribed(
                    expirationDate: transaction.expirationDate,
                    productId: transaction.productID
                )
                foundSubscription = true
                break
            }
        }

        if !Task.isCancelled && !foundSubscription {
            subscriptionStatus = .notSubscribed
        }

        NotificationCenter.default.post(
            name: Constants.Notifications.subscriptionStatusChanged,
            object: nil
        )
    }

    // MARK: - Scan Limit Management

    func canPerformScan() -> Bool {
        if subscriptionStatus.isActive {
            return true
        }

        #if DEBUG
        // In development, allow unlimited scans for testing
        return true
        #endif

        // Check free tier limit
        let scansThisMonth = getScansThisMonth()
        return scansThisMonth < AppConfiguration.freeScansPerMonth
    }

    func recordScan() {
        guard !subscriptionStatus.isActive else { return }

        let scans = getScansThisMonth() + 1
        UserDefaults.standard.set(scans, forKey: Constants.StorageKeys.scansThisMonth)
    }

    func getScansThisMonth() -> Int {
        // Check if we need to reset for new month
        let lastReset = UserDefaults.standard.object(forKey: Constants.StorageKeys.scansMonthStart) as? Date
        let now = Date()

        if let lastReset = lastReset {
            let calendar = Calendar.current
            if !calendar.isDate(lastReset, equalTo: now, toGranularity: .month) {
                // New month, reset counter
                UserDefaults.standard.set(0, forKey: Constants.StorageKeys.scansThisMonth)
                UserDefaults.standard.set(now, forKey: Constants.StorageKeys.scansMonthStart)
                return 0
            }
        } else {
            UserDefaults.standard.set(now, forKey: Constants.StorageKeys.scansMonthStart)
        }

        return UserDefaults.standard.integer(forKey: Constants.StorageKeys.scansThisMonth)
    }

    func remainingFreeScans() -> Int {
        if subscriptionStatus.isActive {
            return Int.max
        }
        
        #if DEBUG
        // In development, show unlimited for testing
        return 999
        #endif
        
        return max(0, AppConfiguration.freeScansPerMonth - getScansThisMonth())
    }
    
    // MARK: - Development Helpers
    
    #if DEBUG
    /// Reset scan count for development/testing
    func resetScanCount() {
        UserDefaults.standard.set(0, forKey: Constants.StorageKeys.scansThisMonth)
        UserDefaults.standard.set(Date(), forKey: Constants.StorageKeys.scansMonthStart)
    }
    #endif

    // MARK: - Private Methods

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard case .verified(let transaction) = result else {
                    continue
                }

                await self?.updateSubscriptionStatus()
                await transaction.finish()
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.verificationFailed
        case .verified(let value):
            return value
        }
    }

    private func verifyWithBackend(_ transaction: Transaction) async {
        // Get the receipt data
        guard let appStoreReceiptURL = Bundle.main.appStoreReceiptURL,
              let receiptData = try? Data(contentsOf: appStoreReceiptURL) else {
            return
        }

        let receiptString = receiptData.base64EncodedString()

        do {
            _ = try await WineAPIClient.shared.verifySubscription(
                receiptData: receiptString,
                transactionId: String(transaction.id)
            )
        } catch {
            print("Backend verification failed: \(error)")
            // Subscription is still valid locally via StoreKit
        }
    }

    // MARK: - Error Types

    enum SubscriptionError: Error, LocalizedError {
        case failedToLoadProducts
        case purchaseFailed
        case restoreFailed
        case verificationFailed

        var errorDescription: String? {
            switch self {
            case .failedToLoadProducts:
                return "Unable to load subscription options"
            case .purchaseFailed:
                return "Purchase could not be completed"
            case .restoreFailed:
                return "Unable to restore purchases"
            case .verificationFailed:
                return "Purchase verification failed"
            }
        }
    }
}
