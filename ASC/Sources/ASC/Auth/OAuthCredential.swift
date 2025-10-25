// OAuthCredential.swift
// ASC - Alamofire Swift Client

// OAuth credential conforming to Alamofire's AuthenticationCredential.

import Alamofire
import Foundation

/// OAuth credential conforming to Alamofire's AuthenticationCredential.
///
/// Represents authentication tokens used for API requests.
/// Refresh is triggered **only on 401 Unauthorized** response.
///
/// Example:
/// ```swift
/// let credential = OAuthCredential(
///     accessToken: "abc123xyz",
///     refreshToken: "refresh_token_here",
///     tokenType: .bearer
/// )
///
/// // Usage with OAuthAuthenticator
/// let authenticator = OAuthAuthenticator(
///     storage: myStorage,
///     client: networkClient
/// )
/// ```
public struct OAuthCredential: AuthenticationCredential, Sendable {
    /// Access token for API requests
    public let accessToken: String

    /// Refresh token for obtaining new access token
    ///
    /// Optional - some auth systems don't provide refresh tokens.
    public let refreshToken: String?

    /// Token type (Bearer, Basic, or custom)
    public let tokenType: TokenType

    /// Always returns `false` - refresh is triggered only on 401 error.
    ///
    /// Alamofire Authenticator will call `refresh()` only when:
    /// - Request fails with 401 Unauthorized
    /// - `didRequest(_:with:failDueToAuthenticationError:)` returns true
    public var requiresRefresh: Bool { false }

    /// Creates a new OAuth credential.
    ///
    /// - Parameters:
    ///   - accessToken: Access token string
    ///   - refreshToken: Refresh token string (optional)
    ///   - tokenType: Token type (default: .bearer)
    public init(
        accessToken: String,
        refreshToken: String? = nil,
        tokenType: TokenType = .bearer
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.tokenType = tokenType
    }
}
