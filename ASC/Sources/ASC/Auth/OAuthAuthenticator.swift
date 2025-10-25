// OAuthAuthenticator.swift
// ASC - Alamofire Swift Client

// Alamofire Authenticator for automatic token refresh on 401.

@preconcurrency import Alamofire
import Foundation

/// Alamofire Authenticator for automatic token refresh on 401.
///
/// Handles authentication lifecycle:
/// 1. Adds access token to requests
/// 2. Detects 401 Unauthorized errors
/// 3. Executes refresh request from `TokenStorage.refreshTokenRequest`
/// 4. Updates tokens in storage
/// 5. Retries failed request with new token
///
/// Example:
/// ```swift
/// let storage = KeychainTokenStorage()
/// let client = NetworkClient(baseURL: "https://api.example.com")
/// let authenticator = OAuthAuthenticator(storage: storage, client: client)
///
/// let config = NetworkClientConfiguration(
///     baseURL: "https://api.example.com",
///     interceptors: [authenticator]
/// )
/// let authClient = NetworkClient(configuration: config)
///
/// // All requests automatically include token and refresh on 401
/// let user = try await authClient.execute(GetUserRequest())
/// ```
public final class OAuthAuthenticator: Authenticator, @unchecked Sendable {
    // MARK: - Properties

    private var storage: TokenStorage
    private let client: NetworkClient

    // MARK: - Initialization

    /// Creates a new OAuth authenticator.
    ///
    /// - Parameters:
    ///   - storage: Token storage implementation
    ///   - client: Network client for executing refresh requests
    ///
    /// **Important**: Use a separate `NetworkClient` instance without authenticator
    /// to avoid infinite recursion during refresh.
    ///
    /// Example:
    /// ```swift
    /// let refreshClient = NetworkClient() // No authenticator!
    /// let authenticator = OAuthAuthenticator(
    ///     storage: storage,
    ///     client: refreshClient
    /// )
    /// ```
    public init(storage: TokenStorage, client: NetworkClient) {
        self.storage = storage
        self.client = client
    }

    // MARK: - Authenticator Protocol

    /// Applies credential to request by adding Authorization header.
    ///
    /// Format: `Authorization: {tokenType} {accessToken}`
    ///
    /// Example: `Authorization: Bearer abc123xyz`
    public func apply(
        _ credential: OAuthCredential,
        to urlRequest: inout URLRequest
    ) {
        let authValue = "\(credential.tokenType.rawValue) \(credential.accessToken)"
        urlRequest.setValue(authValue, forHTTPHeaderField: "Authorization")
    }

    /// Refreshes credential when 401 error occurs.
    ///
    /// Flow:
    /// 1. Gets `refreshTokenRequest` from storage
    /// 2. Executes request using network client
    /// 3. Parses response as `TokenRefreshResponse`
    /// 4. Updates tokens in storage
    /// 5. Creates new credential
    ///
    /// - Parameters:
    ///   - credential: Current (expired) credential
    ///   - session: Alamofire session
    ///   - completion: Completion handler with new credential or error
    public func refresh(
        _ credential: OAuthCredential,
        for session: Session,
        completion: @escaping (Result<OAuthCredential, any Error>) -> Void
    ) {
        // MARK: - Swift 6 Concurrency Note
        // Alamofire's Authenticator completion is not @Sendable, causing strict concurrency issues with Task.
        // We use DispatchQueue.global for async execution to work around this limitation.
        DispatchQueue.global(qos: .userInitiated).async { [self] in
            let task = Task {
                do {
                    // Execute refresh via storage
                    let response = try await self.storage.performRefresh(using: self.client)

                    // Update storage with new tokens
                    self.storage.accessToken = response.accessToken
                    if let newRefreshToken = response.refreshToken {
                        self.storage.refreshToken = newRefreshToken
                    }

                    // Create new credential
                    let newCredential = OAuthCredential(
                        accessToken: response.accessToken,
                        refreshToken: response.refreshToken ?? credential.refreshToken,
                        tokenType: credential.tokenType
                    )

                    completion(.success(newCredential))
                } catch {
                    // Clear tokens on refresh failure
                    self.storage.clearTokens()
                    completion(.failure(error))
                }
            }

            // Keep task alive
            _ = task
        }
    }

    /// Determines if request failed due to authentication error.
    ///
    /// Returns `true` only for 401 Unauthorized responses.
    ///
    /// - Parameters:
    ///   - urlRequest: The failed request
    ///   - response: HTTP response
    ///   - error: Error that occurred
    /// - Returns: True if error is 401 Unauthorized
    public func didRequest(
        _ urlRequest: URLRequest,
        with response: HTTPURLResponse,
        failDueToAuthenticationError error: any Error
    ) -> Bool {
        response.statusCode == HTTPStatus.unauthorized
    }

    /// Checks if request is authenticated with given credential.
    ///
    /// Compares Authorization header with expected value.
    ///
    /// - Parameters:
    ///   - urlRequest: Request to check
    ///   - credential: Credential to verify
    /// - Returns: True if request has matching Authorization header
    public func isRequest(
        _ urlRequest: URLRequest,
        authenticatedWith credential: OAuthCredential
    ) -> Bool {
        let authHeader = urlRequest.value(forHTTPHeaderField: "Authorization")
        let expectedHeader = "\(credential.tokenType.rawValue) \(credential.accessToken)"
        return authHeader == expectedHeader
    }
}

// MARK: - Errors

/// Errors that can occur during OAuth authentication.
public enum OAuthError: Error, LocalizedError {
    /// Refresh request failed
    case refreshFailed(Error)

    public var errorDescription: String? {
        switch self {
        case .refreshFailed(let error):
            return "Token refresh failed: \(error.localizedDescription)"
        }
    }
}
