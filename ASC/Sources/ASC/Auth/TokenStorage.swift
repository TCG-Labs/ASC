// TokenStorage.swift
// ASC - Alamofire Swift Client

// Storage for authentication tokens.

import Foundation

/// Storage for authentication tokens.
///
/// **User-defined implementation** - you control how and where tokens are stored:
/// - Keychain (secure, persistent)
/// - UserDefaults (simple, not secure)
/// - In-memory (temporary, testing)
/// - Custom storage (database, encrypted files, etc.)
///
/// **Important**: Properties are accessed synchronously.
/// Implementations should:
/// - Use in-memory caching for performance
/// - Keep getter/setter operations fast (< 1ms recommended)
/// - Perform heavy I/O in background if needed
///
/// Example with Keychain caching:
/// ```swift
/// class KeychainStorage: TokenStorage {
///     private var cachedAccessToken: String?
///
///     var accessToken: String? {
///         get { cachedAccessToken ?? loadFromKeychain() }
///         set {
///             cachedAccessToken = newValue
///             saveToKeychain(newValue)
///         }
///     }
///
///     var refreshTokenRequest: (any NetworkRequest)? {
///         guard let refreshToken = refreshToken else { return nil }
///         return MyRefreshRequest(refreshToken: refreshToken)
///     }
/// }
/// ```
public protocol TokenStorage: Sendable {
    /// Current access token.
    ///
    /// **Getter**: Returns the stored access token, or nil if not available.
    /// **Setter**: Saves the new access token to storage.
    var accessToken: String? { get set }

    /// Current refresh token.
    ///
    /// **Getter**: Returns the stored refresh token, or nil if not available.
    /// **Setter**: Saves the new refresh token to storage.
    var refreshToken: String? { get set }

    /// Performs token refresh using provided network client.
    ///
    /// Called by `OAuthAuthenticator` when 401 error occurs.
    /// Should execute refresh request and return new tokens.
    ///
    /// Throw error if refresh is not available (no refresh token) or fails.
    ///
    /// Example:
    /// ```swift
    /// func performRefresh(using client: NetworkClient) async throws -> any TokenRefreshResponse {
    ///     guard let refreshToken = refreshToken else {
    ///         throw TokenStorageError.noRefreshToken
    ///     }
    ///
    ///     let request = RefreshTokenRequest(
    ///         refreshToken: refreshToken,
    ///         clientId: "my-client-id"
    ///     )
    ///
    ///     return try await client.execute(request)
    /// }
    /// ```
    ///
    /// - Parameter client: Network client to use for refresh request
    /// - Returns: Token refresh response with new tokens
    /// - Throws: Error if refresh fails or is not available
    func performRefresh(using client: NetworkClient) async throws -> any TokenRefreshResponse

    /// Clears all stored tokens.
    ///
    /// Called on logout or when refresh fails permanently.
    func clearTokens()
}
