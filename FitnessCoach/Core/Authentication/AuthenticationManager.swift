import Foundation
import AuthenticationServices
import Combine

@MainActor
public class AuthenticationManager: NSObject, ObservableObject {
    @Published public var isAuthenticated = true  // Auto-login for iCloud users
    @Published public var currentUser: AuthUser?
    @Published public var userRole: UserRole = .user
    @Published public var isLoading = false
    @Published public var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    public override init() {
        super.init()
        // Immediately set up iCloud user
        setupICloudUser()
    }
    
    public func signInWithApple() {
        isLoading = true
        errorMessage = nil
        
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    public func signOut() {
        isAuthenticated = false
        currentUser = nil
        userRole = .user
        
        // Clear stored credentials
        UserDefaults.standard.removeObject(forKey: "user_identifier")
        UserDefaults.standard.removeObject(forKey: "user_role")
    }
    
    private func setupICloudUser() {
        // Get iCloud user info immediately
        let hostName = ProcessInfo.processInfo.hostName.components(separatedBy: ".").first ?? "User"
        
        currentUser = AuthUser(
            id: "icloud_user",
            userIdentifier: "icloud_\(UUID().uuidString)",
            email: "user@icloud.com",
            firstName: hostName.capitalized,
            lastName: "",
            role: .user,
            createdAt: Date(),
            isActive: true
        )
        isAuthenticated = true
        isLoading = false
    }
    
    private func checkAuthenticationState() {
        guard let userIdentifier = UserDefaults.standard.string(forKey: "user_identifier") else {
            setupICloudUser()
            return
        }
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        appleIDProvider.getCredentialState(forUserID: userIdentifier) { [weak self] credentialState, error in
            DispatchQueue.main.async {
                switch credentialState {
                case .authorized:
                    self?.loadUserProfile(userIdentifier: userIdentifier)
                case .revoked, .notFound:
                    self?.signOut()
                default:
                    break
                }
            }
        }
    }
    
    private func loadUserProfile(userIdentifier: String) {
        isLoading = true
        
        // For now, create a mock user - later integrate with CloudKit when entitlements are set up
        let roleString = UserDefaults.standard.string(forKey: "user_role") ?? "user"
        let user = AuthUser(
            id: userIdentifier,
            userIdentifier: userIdentifier,
            email: "demo@fitnesscoach.com",
            firstName: "Demo",
            lastName: "User",
            role: UserRole(rawValue: roleString) ?? .user,
            createdAt: Date(),
            isActive: true
        )
        
        self.currentUser = user
        self.userRole = user.role
        self.isAuthenticated = true
        self.isLoading = false
    }
    
    private func createMockUser(userIdentifier: String, fullName: PersonNameComponents?, email: String?) -> AuthUser {
        return AuthUser(
            id: userIdentifier,
            userIdentifier: userIdentifier,
            email: email ?? "demo@fitnesscoach.com",
            firstName: fullName?.givenName ?? "Demo",
            lastName: fullName?.familyName ?? "User",
            role: .user,
            createdAt: Date(),
            isActive: true
        )
    }
    
    public func hasPermission(_ permission: Permission) -> Bool {
        return userRole.permissions.contains(permission)
    }
}

// MARK: - ASAuthorizationControllerDelegate
extension AuthenticationManager: ASAuthorizationControllerDelegate {
    public func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            let userIdentifier = appleIDCredential.user
            
            UserDefaults.standard.set(userIdentifier, forKey: "user_identifier")
            
            // For now, create a mock user - later integrate with CloudKit when entitlements are set up
            let user = createMockUser(
                userIdentifier: userIdentifier,
                fullName: appleIDCredential.fullName,
                email: appleIDCredential.email
            )
            
            self.currentUser = user
            self.userRole = user.role
            self.isAuthenticated = true
            self.isLoading = false
            
            UserDefaults.standard.set(user.role.rawValue, forKey: "user_role")
        }
    }
    
    public func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        isLoading = false
        errorMessage = "Authentication failed: \(error.localizedDescription)"
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding
extension AuthenticationManager: ASAuthorizationControllerPresentationContextProviding {
    public func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            fatalError("No window found")
        }
        return window
    }
}

public enum AuthenticationError: Error {
    case userNotFound
    case invalidCredentials
    case networkError
}

// MARK: - User Model
public struct AuthUser: Codable {
    public let id: String
    public let userIdentifier: String
    public let email: String
    public let firstName: String
    public let lastName: String
    public let role: UserRole
    public let createdAt: Date
    public let isActive: Bool
    
    public var fullName: String {
        "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
    }
    
    public init(id: String, userIdentifier: String, email: String, firstName: String, lastName: String, role: UserRole, createdAt: Date, isActive: Bool) {
        self.id = id
        self.userIdentifier = userIdentifier
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.role = role
        self.createdAt = createdAt
        self.isActive = isActive
    }
}