import Foundation
import StoreKit
import Combine
import OSLog

/// Comprehensive subscription management with StoreKit 2 integration
@MainActor
public final class LicenseManager: ObservableObject {
    
    static let shared = LicenseManager()
    
    // MARK: - Properties
    private let logger = Logger(subsystem: "FitnessCoach", category: "LicenseManager")
    
    @Published public var subscriptionStatus: SubscriptionStatus = .notSubscribed
    @Published public var currentTier: SubscriptionTier = .free
    @Published public var availableProducts: [Product] = []
    @Published public var isLoading = false
    
    private var cancellables = Set<AnyCancellable>()
    private let productStore = ProductStore()
    
    // Product IDs - These should match your App Store Connect configuration
    private let productIdentifiers: [String] = [
        "fitnesscoach.monthly.pro",
        "fitnesscoach.yearly.pro",
        "fitnesscoach.monthly.premium",
        "fitnesscoach.yearly.premium",
        "fitnesscoach.lifetime.premium"
    ]
    
    // MARK: - Subscription Tiers
    public enum SubscriptionTier: String, CaseIterable {
        case free = "free"
        case pro = "pro"
        case premium = "premium"
        
        var displayName: String {
            switch self {
            case .free: return "Free"
            case .pro: return "Pro"
            case .premium: return "Premium"
            }
        }
        
        var features: [String] {
            switch self {
            case .free:
                return [
                    "Basic workout tracking",
                    "Simple nutrition logging",
                    "Progress photos (3 per month)",
                    "Basic analytics"
                ]
            case .pro:
                return [
                    "Unlimited workout creation",
                    "Advanced nutrition tracking",
                    "Unlimited progress photos",
                    "Advanced analytics",
                    "Coach certification features",
                    "Up to 10 clients"
                ]
            case .premium:
                return [
                    "Everything in Pro",
                    "Unlimited clients",
                    "White-label branding",
                    "Advanced integrations",
                    "Priority support",
                    "Beta features access"
                ]
            }
        }
        
        var clientLimit: Int {
            switch self {
            case .free: return 0
            case .pro: return 10
            case .premium: return Int.max
            }
        }
        
        var progressPhotoLimit: Int {
            switch self {
            case .free: return 3
            case .pro, .premium: return Int.max
            }
        }
        
        var hasAdvancedAnalytics: Bool {
            self != .free
        }
        
        var hasCoachFeatures: Bool {
            self != .free
        }
        
        var hasWhiteLabel: Bool {
            self == .premium
        }
    }
    
    public enum SubscriptionStatus {
        case notSubscribed
        case subscribed(Product, Transaction)
        case expired(Product, Transaction)
        case inGracePeriod(Product, Transaction)
        case inBillingRetry(Product, Transaction)
        
        var isActive: Bool {
            switch self {
            case .subscribed, .inGracePeriod:
                return true
            default:
                return false
            }
        }
    }
    
    // MARK: - Initialization
    private init() {
        setupStoreKitListener()
        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
    }
    
    // MARK: - StoreKit Setup
    
    private func setupStoreKitListener() {
        // Listen for transaction updates
        Task {
            for await result in Transaction.updates {
                do {
                    let transaction = try checkVerified(result)
                    await handleTransactionUpdate(transaction)
                } catch {
                    logger.error("Transaction verification failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func loadProducts() async {
        isLoading = true
        
        do {
            let products = try await Product.products(for: productIdentifiers)
            
            await MainActor.run {
                self.availableProducts = products.sorted { $0.price < $1.price }
                self.isLoading = false
            }
            
            logger.info("Loaded \(products.count) products from App Store")
            
        } catch {
            await MainActor.run {
                self.isLoading = false
            }
            logger.error("Failed to load products: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Subscription Management
    
    public func purchase(_ product: Product) async throws -> Transaction {
        logger.info("Attempting to purchase: \(product.id)")
        
        let result = try await product.purchase()
        
        switch result {
        case .success(let verificationResult):
            let transaction = try checkVerified(verificationResult)
            await handleTransactionUpdate(transaction)
            await updateSubscriptionStatus()
            
            logger.info("Purchase successful: \(product.id)")
            return transaction
            
        case .userCancelled:
            logger.info("User cancelled purchase")
            throw LicenseError.userCancelled
            
        case .pending:
            logger.info("Purchase pending approval")
            throw LicenseError.purchasePending
            
        @unknown default:
            logger.error("Unknown purchase result")
            throw LicenseError.unknownError
        }
    }
    
    public func restorePurchases() async throws {
        logger.info("Restoring purchases")
        
        try await AppStore.sync()
        await updateSubscriptionStatus()
        
        logger.info("Purchases restored")
    }
    
    public func updateSubscriptionStatus() async {
        var activeSubscription: (Product, Transaction)?
        
        // Check for active subscription transactions
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                // Find the corresponding product
                if let product = availableProducts.first(where: { $0.id == transaction.productID }) {
                    
                    // Check if this is the most recent/highest tier subscription
                    if activeSubscription == nil || isHigherTier(product, than: activeSubscription!.0) {
                        activeSubscription = (product, transaction)
                    }
                }
                
            } catch {
                logger.error("Failed to verify transaction: \(error.localizedDescription)")
            }
        }
        
        await MainActor.run {
            if let (product, transaction) = activeSubscription {
                self.subscriptionStatus = .subscribed(product, transaction)
                self.currentTier = self.getTier(for: product)
            } else {
                self.subscriptionStatus = .notSubscribed
                self.currentTier = .free
            }
        }
        
        logger.info("Subscription status updated: \(currentTier.displayName)")
    }
    
    private func handleTransactionUpdate(_ transaction: Transaction) async {
        logger.info("Handling transaction update: \(transaction.productID)")
        
        // Finish the transaction
        await transaction.finish()
        
        // Update subscription status
        await updateSubscriptionStatus()
        
        // Sync with server if needed
        await syncSubscriptionWithServer(transaction)
    }
    
    // MARK: - Feature Access Control
    
    public func canAccessFeature(_ feature: FeatureAccess) -> Bool {
        switch feature {
        case .basicWorkouts:
            return true // Always available
            
        case .unlimitedWorkouts:
            return currentTier != .free
            
        case .advancedNutrition:
            return currentTier != .free
            
        case .coachFeatures:
            return currentTier.hasCoachFeatures
            
        case .advancedAnalytics:
            return currentTier.hasAdvancedAnalytics
            
        case .whiteLabeling:
            return currentTier.hasWhiteLabel
            
        case .unlimitedClients:
            return currentTier == .premium
            
        case .progressPhotos(let count):
            return count <= currentTier.progressPhotoLimit
            
        case .clientLimit(let count):
            return count <= currentTier.clientLimit
        }
    }
    
    public func getFeatureLimitMessage(for feature: FeatureAccess) -> String {
        switch feature {
        case .unlimitedWorkouts:
            return "Upgrade to Pro to create unlimited workouts"
        case .advancedNutrition:
            return "Upgrade to Pro for advanced nutrition tracking"
        case .coachFeatures:
            return "Upgrade to Pro to access coach features"
        case .advancedAnalytics:
            return "Upgrade to Pro for advanced analytics"
        case .whiteLabeling:
            return "Upgrade to Premium for white-label branding"
        case .unlimitedClients:
            return "Upgrade to Premium for unlimited clients"
        case .progressPhotos(let count):
            return "Upgrade to Pro for unlimited progress photos (current limit: \(currentTier.progressPhotoLimit))"
        case .clientLimit(let count):
            return "Upgrade to increase your client limit (current: \(currentTier.clientLimit))"
        default:
            return "Upgrade to access this feature"
        }
    }
    
    // MARK: - Product Information
    
    public func getProduct(for tier: SubscriptionTier, period: SubscriptionPeriod) -> Product? {
        let productID: String
        
        switch (tier, period) {
        case (.pro, .monthly):
            productID = "fitnesscoach.monthly.pro"
        case (.pro, .yearly):
            productID = "fitnesscoach.yearly.pro"
        case (.premium, .monthly):
            productID = "fitnesscoach.monthly.premium"
        case (.premium, .yearly):
            productID = "fitnesscoach.yearly.premium"
        case (.premium, .lifetime):
            productID = "fitnesscoach.lifetime.premium"
        default:
            return nil
        }
        
        return availableProducts.first { $0.id == productID }
    }
    
    public func getRecommendedProduct() -> Product? {
        // Recommend yearly Pro as the best value
        return getProduct(for: .pro, period: .yearly)
    }
    
    public func getSavingsPercentage(yearly: Product, monthly: Product) -> Int {
        let yearlyMonthly = yearly.price / 12
        let monthlySavings = (monthly.price - yearlyMonthly) / monthly.price
        return Int(monthlySavings * 100)
    }
    
    // MARK: - Family Sharing Support
    
    public var supportsFamilySharing: Bool {
        guard case .subscribed(let product, _) = subscriptionStatus else {
            return false
        }
        return product.subscription?.familyShareable == true
    }
    
    public func manageFamilySharing() {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return
        }
        
        Task {
            try? await AppStore.showManageSubscriptions(in: scene)
        }
    }
    
    // MARK: - Subscription Management UI
    
    public func showSubscriptionManagement() {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return
        }
        
        Task {
            try? await AppStore.showManageSubscriptions(in: scene)
        }
    }
    
    // MARK: - Grace Period and Billing Issues
    
    private func checkSubscriptionIssues() async {
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                if let product = availableProducts.first(where: { $0.id == transaction.productID }),
                   let subscription = product.subscription {
                    
                    // Check for grace period or billing retry
                    if let renewalInfo = try await transaction.subscriptionStatus?.renewalInfo {
                        let verifiedRenewalInfo = try checkVerified(renewalInfo)
                        
                        if verifiedRenewalInfo.isInGracePeriod == true {
                            await MainActor.run {
                                self.subscriptionStatus = .inGracePeriod(product, transaction)
                            }
                        } else if verifiedRenewalInfo.autoRenewPreference == .on {
                            // Check if there are billing issues
                            await MainActor.run {
                                self.subscriptionStatus = .inBillingRetry(product, transaction)
                            }
                        }
                    }
                }
                
            } catch {
                logger.error("Failed to check subscription issues: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Server Synchronization
    
    private func syncSubscriptionWithServer(_ transaction: Transaction) async {
        // Implement server-side receipt validation and user status update
        logger.info("Syncing subscription with server: \(transaction.id)")
        
        // This would typically involve:
        // 1. Sending transaction receipt to your server
        // 2. Server validates with Apple
        // 3. Server updates user subscription status
        // 4. Server returns updated user permissions
        
        // For now, we'll just log this
        logger.info("Server sync completed")
    }
    
    // MARK: - Helper Methods
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw LicenseError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }
    
    private func getTier(for product: Product) -> SubscriptionTier {
        if product.id.contains("pro") {
            return .pro
        } else if product.id.contains("premium") {
            return .premium
        }
        return .free
    }
    
    private func isHigherTier(_ product1: Product, than product2: Product) -> Bool {
        let tier1 = getTier(for: product1)
        let tier2 = getTier(for: product2)
        
        let tierOrder: [SubscriptionTier] = [.free, .pro, .premium]
        
        guard let index1 = tierOrder.firstIndex(of: tier1),
              let index2 = tierOrder.firstIndex(of: tier2) else {
            return false
        }
        
        return index1 > index2
    }
    
    // MARK: - Analytics and Metrics
    
    public func trackSubscriptionEvent(_ event: SubscriptionEvent) {
        logger.info("Subscription event: \(event.rawValue)")
        
        // Send to analytics service
        // AnalyticsManager.shared.track(event: event.analyticsName, parameters: event.parameters)
    }
}

// MARK: - Supporting Types

public enum SubscriptionPeriod {
    case monthly
    case yearly
    case lifetime
}

public enum FeatureAccess {
    case basicWorkouts
    case unlimitedWorkouts
    case advancedNutrition
    case coachFeatures
    case advancedAnalytics
    case whiteLabeling
    case unlimitedClients
    case progressPhotos(count: Int)
    case clientLimit(count: Int)
}

public enum SubscriptionEvent: String {
    case purchaseStarted = "purchase_started"
    case purchaseCompleted = "purchase_completed"
    case purchaseFailed = "purchase_failed"
    case purchaseCancelled = "purchase_cancelled"
    case subscriptionRestored = "subscription_restored"
    case featureBlocked = "feature_blocked"
    case upgradeSuggested = "upgrade_suggested"
    
    var analyticsName: String {
        return "subscription_\(rawValue)"
    }
}

public enum LicenseError: LocalizedError {
    case verificationFailed
    case userCancelled
    case purchasePending
    case productNotFound
    case noActiveSubscription
    case unknownError
    
    public var errorDescription: String? {
        switch self {
        case .verificationFailed:
            return "Failed to verify purchase with Apple"
        case .userCancelled:
            return "Purchase was cancelled"
        case .purchasePending:
            return "Purchase is pending approval"
        case .productNotFound:
            return "Product not found in App Store"
        case .noActiveSubscription:
            return "No active subscription found"
        case .unknownError:
            return "An unknown error occurred"
        }
    }
}

// MARK: - Product Store Helper
private class ProductStore {
    private var products: [String: Product] = [:]
    
    func store(_ products: [Product]) {
        for product in products {
            self.products[product.id] = product
        }
    }
    
    func product(for id: String) -> Product? {
        return products[id]
    }
}