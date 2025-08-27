import Foundation
import StoreKit
import CryptoKit
import OSLog

/// Server-side receipt validation with offline grace period and security measures
public final class SubscriptionValidator: ObservableObject {
    
    // MARK: - Properties
    private let logger = Logger(subsystem: "FitnessCoach", category: "SubscriptionValidator")
    
    @Published public var validationStatus: ValidationStatus = .unknown
    @Published public var isInGracePeriod: Bool = false
    
    private let gracePeriodDuration: TimeInterval = 86400 * 7 // 7 days
    private let maxOfflineDuration: TimeInterval = 86400 * 3 // 3 days
    
    // Validation endpoints
    private let productionURL = URL(string: "https://buy.itunes.apple.com/verifyReceipt")!
    private let sandboxURL = URL(string: "https://sandbox.itunes.apple.com/verifyReceipt")!
    
    // Your server endpoints for receipt validation
    private let serverValidationURL = URL(string: "https://api.fitnesscoach.app/v1/validate-receipt")!
    private let serverStatusURL = URL(string: "https://api.fitnesscoach.app/v1/subscription-status")!
    
    // Local storage keys
    private let lastValidationKey = "lastSuccessfulValidation"
    private let gracePeriodStartKey = "gracePeriodStart"
    private let offlineStartKey = "offlineValidationStart"
    
    // MARK: - Validation Status
    public enum ValidationStatus {
        case unknown
        case valid(expiresAt: Date)
        case expired(expiredAt: Date)
        case invalid
        case gracePeriod(originalExpiry: Date, graceEndDate: Date)
        case networkError
        case validationError(Error)
    }
    
    // MARK: - Receipt Validation
    
    /// Validates subscription with server-side verification
    public func validateSubscription(force: Bool = false) async -> ValidationStatus {
        logger.info("Starting subscription validation (force: \(force))")
        
        // Check if we can use cached validation
        if !force, let cachedStatus = getCachedValidationStatus() {
            logger.info("Using cached validation status")
            await MainActor.run {
                self.validationStatus = cachedStatus
                self.isInGracePeriod = self.isStatusInGracePeriod(cachedStatus)
            }
            return cachedStatus
        }
        
        // Try server validation first
        if let serverStatus = await validateWithServer() {
            await updateValidationStatus(serverStatus)
            return serverStatus
        }
        
        // Fallback to direct Apple validation
        if let appleStatus = await validateWithApple() {
            await updateValidationStatus(appleStatus)
            return appleStatus
        }
        
        // Fallback to offline validation
        let offlineStatus = await performOfflineValidation()
        await updateValidationStatus(offlineStatus)
        return offlineStatus
    }
    
    /// Validates receipt with your server (recommended approach)
    private func validateWithServer() async -> ValidationStatus? {
        logger.info("Validating with server")
        
        guard let appStoreReceiptData = await getAppStoreReceiptData() else {
            logger.error("No App Store receipt data available")
            return nil
        }
        
        do {
            var request = URLRequest(url: serverValidationURL)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(getAuthorizationHeader(), forHTTPHeaderField: "Authorization")
            
            let requestBody = ServerValidationRequest(
                receiptData: appStoreReceiptData.base64EncodedString(),
                deviceId: await getDeviceIdentifier(),
                bundleId: Bundle.main.bundleIdentifier ?? "",
                appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
            )
            
            request.httpBody = try JSONEncoder().encode(requestBody)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ValidationError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                logger.error("Server validation failed with status: \(httpResponse.statusCode)")
                return nil
            }
            
            let validationResponse = try JSONDecoder().decode(ServerValidationResponse.self, from: data)
            
            logger.info("Server validation successful")
            return parseServerValidationResponse(validationResponse)
            
        } catch {
            logger.error("Server validation error: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Validates receipt directly with Apple (backup method)
    private func validateWithApple() async -> ValidationStatus? {
        logger.info("Validating with Apple directly")
        
        guard let receiptData = await getAppStoreReceiptData() else {
            return nil
        }
        
        // Try production first, then sandbox
        let urls = [productionURL, sandboxURL]
        
        for url in urls {
            if let status = await validateWithApple(receiptData: receiptData, url: url) {
                logger.info("Apple validation successful with \(url == productionURL ? "production" : "sandbox")")
                return status
            }
        }
        
        logger.error("Apple validation failed")
        return nil
    }
    
    private func validateWithApple(receiptData: Data, url: URL) async -> ValidationStatus? {
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let requestBody: [String: Any] = [
                "receipt-data": receiptData.base64EncodedString(),
                "password": getSharedSecret(), // Your App Store shared secret
                "exclude-old-transactions": true
            ]
            
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return nil
            }
            
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let status = json["status"] as? Int else {
                return nil
            }
            
            return parseAppleValidationResponse(json, status: status)
            
        } catch {
            logger.error("Apple validation error: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Performs offline validation using cached data and grace periods
    private func performOfflineValidation() async -> ValidationStatus {
        logger.info("Performing offline validation")
        
        let now = Date()
        
        // Check if we have a cached validation
        if let lastValidation = UserDefaults.standard.object(forKey: lastValidationKey) as? Date {
            let offlineStart = UserDefaults.standard.object(forKey: offlineStartKey) as? Date ?? now
            let timeSinceLastValidation = now.timeIntervalSince(lastValidation)
            let offlineDuration = now.timeIntervalSince(offlineStart)
            
            // If we're within the allowed offline duration
            if offlineDuration < maxOfflineDuration {
                logger.info("Within offline grace period")
                
                // Calculate estimated expiry based on last known status
                let estimatedExpiry = lastValidation.addingTimeInterval(gracePeriodDuration)
                
                if now < estimatedExpiry {
                    return .valid(expiresAt: estimatedExpiry)
                } else {
                    // Start grace period
                    let graceEndDate = estimatedExpiry.addingTimeInterval(gracePeriodDuration)
                    if now < graceEndDate {
                        return .gracePeriod(originalExpiry: estimatedExpiry, graceEndDate: graceEndDate)
                    } else {
                        return .expired(expiredAt: estimatedExpiry)
                    }
                }
            }
        }
        
        // No valid offline state
        logger.warning("No valid offline validation state")
        return .networkError
    }
    
    // MARK: - Response Parsing
    
    private func parseServerValidationResponse(_ response: ServerValidationResponse) -> ValidationStatus {
        switch response.status {
        case .valid:
            if let expiresAt = response.expiresAt {
                return .valid(expiresAt: expiresAt)
            }
            return .invalid
            
        case .expired:
            if let expiredAt = response.expiredAt {
                return .expired(expiredAt: expiredAt)
            }
            return .invalid
            
        case .gracePeriod:
            if let originalExpiry = response.expiredAt,
               let graceEndDate = response.graceEndDate {
                return .gracePeriod(originalExpiry: originalExpiry, graceEndDate: graceEndDate)
            }
            return .invalid
            
        case .invalid:
            return .invalid
        }
    }
    
    private func parseAppleValidationResponse(_ json: [String: Any], status: Int) -> ValidationStatus? {
        guard status == 0 else {
            logger.error("Apple validation failed with status: \(status)")
            return nil
        }
        
        guard let receipt = json["receipt"] as? [String: Any],
              let inAppArray = receipt["in_app"] as? [[String: Any]] else {
            return .invalid
        }
        
        // Find the latest subscription
        var latestSubscription: [String: Any]?
        var latestExpiryDate: Date?
        
        for inApp in inAppArray {
            if let productId = inApp["product_id"] as? String,
               isSubscriptionProduct(productId),
               let expiresDateString = inApp["expires_date"] as? String,
               let expiresDate = parseAppleDateString(expiresDateString) {
                
                if latestExpiryDate == nil || expiresDate > latestExpiryDate! {
                    latestSubscription = inApp
                    latestExpiryDate = expiresDate
                }
            }
        }
        
        guard let expiryDate = latestExpiryDate else {
            return .invalid
        }
        
        let now = Date()
        if now < expiryDate {
            return .valid(expiresAt: expiryDate)
        } else {
            // Check if we should enter grace period
            let gracePeriodEnd = expiryDate.addingTimeInterval(gracePeriodDuration)
            if now < gracePeriodEnd {
                return .gracePeriod(originalExpiry: expiryDate, graceEndDate: gracePeriodEnd)
            } else {
                return .expired(expiredAt: expiryDate)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func getAppStoreReceiptData() async -> Data? {
        guard let receiptURL = Bundle.main.appStoreReceiptURL else {
            logger.error("No App Store receipt URL")
            return nil
        }
        
        do {
            return try Data(contentsOf: receiptURL)
        } catch {
            logger.error("Failed to load receipt data: \(error.localizedDescription)")
            
            // Try to refresh receipt
            await refreshReceipt()
            
            // Try again after refresh
            do {
                return try Data(contentsOf: receiptURL)
            } catch {
                logger.error("Failed to load receipt data after refresh: \(error.localizedDescription)")
                return nil
            }
        }
    }
    
    private func refreshReceipt() async {
        logger.info("Refreshing App Store receipt")
        
        do {
            try await AppStore.sync()
        } catch {
            logger.error("Failed to refresh receipt: \(error.localizedDescription)")
        }
    }
    
    private func getDeviceIdentifier() async -> String {
        // Create a consistent device identifier
        if let storedId = UserDefaults.standard.string(forKey: "deviceIdentifier") {
            return storedId
        }
        
        let deviceId = UUID().uuidString
        UserDefaults.standard.set(deviceId, forKey: "deviceIdentifier")
        return deviceId
    }
    
    private func getAuthorizationHeader() -> String {
        // Implement your server authentication
        return "Bearer your-api-key"
    }
    
    private func getSharedSecret() -> String {
        // Your App Store Connect shared secret
        return "your-shared-secret"
    }
    
    private func isSubscriptionProduct(_ productId: String) -> Bool {
        return productId.contains("pro") || productId.contains("premium")
    }
    
    private func parseAppleDateString(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss VV"
        return formatter.date(from: dateString)
    }
    
    // MARK: - Caching and State Management
    
    private func updateValidationStatus(_ status: ValidationStatus) async {
        await MainActor.run {
            self.validationStatus = status
            self.isInGracePeriod = self.isStatusInGracePeriod(status)
        }
        
        // Cache successful validations
        if case .valid = status {
            UserDefaults.standard.set(Date(), forKey: lastValidationKey)
            UserDefaults.standard.removeObject(forKey: offlineStartKey)
        } else {
            // Start offline timer if not already started
            if UserDefaults.standard.object(forKey: offlineStartKey) == nil {
                UserDefaults.standard.set(Date(), forKey: offlineStartKey)
            }
        }
    }
    
    private func getCachedValidationStatus() -> ValidationStatus? {
        guard let lastValidation = UserDefaults.standard.object(forKey: lastValidationKey) as? Date else {
            return nil
        }
        
        let now = Date()
        let cacheAge = now.timeIntervalSince(lastValidation)
        
        // Cache is valid for 1 hour for online validation
        if cacheAge < 3600 {
            // Return cached valid status with estimated expiry
            return .valid(expiresAt: lastValidation.addingTimeInterval(86400 * 30)) // Estimate 30 days
        }
        
        return nil
    }
    
    private func isStatusInGracePeriod(_ status: ValidationStatus) -> Bool {
        if case .gracePeriod = status {
            return true
        }
        return false
    }
    
    // MARK: - Security Measures
    
    /// Validates the integrity of the receipt data
    private func validateReceiptIntegrity(_ receiptData: Data) -> Bool {
        // Implement receipt signature validation
        // This is a simplified version - in production, you'd want more sophisticated checks
        
        // Check minimum receipt size
        guard receiptData.count > 100 else {
            return false
        }
        
        // Check for receipt format markers
        let receiptString = receiptData.base64EncodedString()
        guard receiptString.contains("MII") else { // ASN.1 DER format marker
            return false
        }
        
        return true
    }
    
    /// Detects potential receipt tampering or jailbreak
    private func performSecurityChecks() -> Bool {
        // Check for jailbreak indicators
        let jailbreakPaths = [
            "/Applications/Cydia.app",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt"
        ]
        
        for path in jailbreakPaths {
            if FileManager.default.fileExists(atPath: path) {
                logger.warning("Potential jailbreak detected")
                return false
            }
        }
        
        return true
    }
    
    // MARK: - Public Interface
    
    /// Quick check if subscription is currently active
    public var isSubscriptionActive: Bool {
        switch validationStatus {
        case .valid, .gracePeriod:
            return true
        default:
            return false
        }
    }
    
    /// Get subscription expiry date if available
    public var subscriptionExpiryDate: Date? {
        switch validationStatus {
        case .valid(let expiresAt):
            return expiresAt
        case .gracePeriod(let originalExpiry, _):
            return originalExpiry
        case .expired(let expiredAt):
            return expiredAt
        default:
            return nil
        }
    }
    
    /// Get grace period end date if in grace period
    public var gracePeriodEndDate: Date? {
        if case .gracePeriod(_, let graceEndDate) = validationStatus {
            return graceEndDate
        }
        return nil
    }
    
    /// Force a fresh validation (bypassing cache)
    public func forceValidation() async {
        _ = await validateSubscription(force: true)
    }
}

// MARK: - Supporting Types

private struct ServerValidationRequest: Codable {
    let receiptData: String
    let deviceId: String
    let bundleId: String
    let appVersion: String
}

private struct ServerValidationResponse: Codable {
    let status: SubscriptionStatus
    let expiresAt: Date?
    let expiredAt: Date?
    let graceEndDate: Date?
    let message: String?
    
    enum SubscriptionStatus: String, Codable {
        case valid = "valid"
        case expired = "expired"
        case gracePeriod = "grace_period"
        case invalid = "invalid"
    }
}

public enum ValidationError: LocalizedError {
    case noReceipt
    case invalidResponse
    case networkError
    case securityCheckFailed
    case serverError(Int)
    
    public var errorDescription: String? {
        switch self {
        case .noReceipt:
            return "No App Store receipt found"
        case .invalidResponse:
            return "Invalid response from validation server"
        case .networkError:
            return "Network error during validation"
        case .securityCheckFailed:
            return "Security validation failed"
        case .serverError(let code):
            return "Server error: \(code)"
        }
    }
}