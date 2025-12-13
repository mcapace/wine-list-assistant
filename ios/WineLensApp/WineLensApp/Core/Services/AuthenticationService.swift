import Foundation
import AuthenticationServices
import Combine

@MainActor
final class AuthenticationService: ObservableObject {
    // MARK: - Singleton

    static let shared = AuthenticationService()

    // MARK: - Published Properties

    @Published private(set) var isAuthenticated: Bool = false
    @Published private(set) var currentUser: User?
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var error: AuthError?

    // MARK: - Token Storage

    private let keychain = KeychainManager.shared

    var accessToken: String? {
        keychain.get(Constants.KeychainKeys.accessToken)
    }

    var refreshToken: String? {
        keychain.get(Constants.KeychainKeys.refreshToken)
    }

    // MARK: - Initialization

    private init() {
        // Check for existing authentication
        Task {
            await checkExistingAuth()
        }
    }

    // MARK: - Authentication Methods

    func checkExistingAuth() async {
        guard let token = accessToken else {
            isAuthenticated = false
            return
        }

        // Validate token by fetching user profile
        isLoading = true
        defer { isLoading = false }

        do {
            let user = try await fetchCurrentUser(token: token)
            currentUser = user
            isAuthenticated = true
        } catch {
            // Token invalid, try refresh
            if let refreshToken = refreshToken {
                do {
                    try await refreshAccessToken(refreshToken)
                } catch {
                    // Refresh failed, clear auth
                    await signOut()
                }
            } else {
                await signOut()
            }
        }
    }

    func signIn(email: String, password: String) async throws {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let response = try await performSignIn(email: email, password: password)
            await storeTokens(response.tokens)
            currentUser = response.user
            isAuthenticated = true

            NotificationCenter.default.post(name: Constants.Notifications.userLoggedIn, object: nil)
        } catch {
            self.error = error as? AuthError ?? .unknown
            throw error
        }
    }

    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws {
        isLoading = true
        error = nil
        defer { isLoading = false }

        guard let identityToken = credential.identityToken,
              let identityTokenString = String(data: identityToken, encoding: .utf8),
              let authorizationCode = credential.authorizationCode,
              let authCodeString = String(data: authorizationCode, encoding: .utf8) else {
            throw AuthError.invalidCredentials
        }

        do {
            let response = try await performAppleSignIn(
                identityToken: identityTokenString,
                authorizationCode: authCodeString,
                email: credential.email,
                fullName: credential.fullName
            )

            await storeTokens(response.tokens)
            currentUser = response.user
            isAuthenticated = true

            NotificationCenter.default.post(name: Constants.Notifications.userLoggedIn, object: nil)
        } catch {
            self.error = error as? AuthError ?? .unknown
            throw error
        }
    }

    func signUp(email: String, password: String, firstName: String?, lastName: String?) async throws {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let response = try await performSignUp(
                email: email,
                password: password,
                firstName: firstName,
                lastName: lastName
            )

            await storeTokens(response.tokens)
            currentUser = response.user
            isAuthenticated = true

            NotificationCenter.default.post(name: Constants.Notifications.userLoggedIn, object: nil)
        } catch {
            self.error = error as? AuthError ?? .unknown
            throw error
        }
    }

    func signOut() async {
        keychain.delete(Constants.KeychainKeys.accessToken)
        keychain.delete(Constants.KeychainKeys.refreshToken)
        keychain.delete(Constants.KeychainKeys.userId)

        currentUser = nil
        isAuthenticated = false

        NotificationCenter.default.post(name: Constants.Notifications.userLoggedOut, object: nil)
    }

    func refreshAccessToken(_ refreshToken: String) async throws {
        let response = try await performTokenRefresh(refreshToken)
        await storeTokens(response.tokens)
    }

    // MARK: - Private Methods

    private func storeTokens(_ tokens: AuthTokens) async {
        keychain.set(tokens.accessToken, forKey: Constants.KeychainKeys.accessToken)
        if let refresh = tokens.refreshToken {
            keychain.set(refresh, forKey: Constants.KeychainKeys.refreshToken)
        }
    }

    // MARK: - API Calls (Placeholder implementations)

    private func performSignIn(email: String, password: String) async throws -> AuthResponse {
        // TODO: Implement actual API call
        throw AuthError.notImplemented
    }

    private func performAppleSignIn(
        identityToken: String,
        authorizationCode: String,
        email: String?,
        fullName: PersonNameComponents?
    ) async throws -> AuthResponse {
        // TODO: Implement actual API call
        throw AuthError.notImplemented
    }

    private func performSignUp(
        email: String,
        password: String,
        firstName: String?,
        lastName: String?
    ) async throws -> AuthResponse {
        // TODO: Implement actual API call
        throw AuthError.notImplemented
    }

    private func performTokenRefresh(_ refreshToken: String) async throws -> AuthResponse {
        // TODO: Implement actual API call
        throw AuthError.notImplemented
    }

    private func fetchCurrentUser(token: String) async throws -> User {
        // TODO: Implement actual API call
        throw AuthError.notImplemented
    }

    // MARK: - Types

    struct AuthResponse {
        let user: User
        let tokens: AuthTokens
    }

    struct AuthTokens {
        let accessToken: String
        let refreshToken: String?
        let expiresIn: Int
    }

    enum AuthError: Error, LocalizedError {
        case invalidCredentials
        case emailAlreadyExists
        case weakPassword
        case networkError
        case notImplemented
        case unknown

        var errorDescription: String? {
            switch self {
            case .invalidCredentials:
                return "Invalid email or password"
            case .emailAlreadyExists:
                return "An account with this email already exists"
            case .weakPassword:
                return "Password must be at least 8 characters"
            case .networkError:
                return "Network error. Please check your connection."
            case .notImplemented:
                return "This feature is not yet available"
            case .unknown:
                return "An unexpected error occurred"
            }
        }
    }
}
