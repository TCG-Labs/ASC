// AuthToken.swift
// ASC - Alamofire Swift Client

// HTTP authentication token type.

import Foundation

/// HTTP authentication token type.
///
/// Defines the scheme used in the `Authorization` header.
///
/// Example:
/// ```swift
/// let credential = OAuthCredential(
///     accessToken: "abc123",
///     authToken: .bearer(token: "abc123")
/// )
/// // Authorization: Bearer abc123
/// ```
public enum AuthToken: Sendable, Equatable {
    /// Bearer token authentication (most common for OAuth 2.0)
    ///
    /// Format: `Authorization: Bearer {token}`
    case bearer(token: String)

    /// Basic authentication
    ///
    /// Format: `Authorization: Basic {token}`
    case basic(username: String, password: String)

    /// Custom token type
    ///
    /// Format: `Authorization: {rawValue} {token}`
    case custom(token: String)

    public var header: HTTPHeader {
        switch self {
        case .bearer(let token):
            return .authorization(bearerToken: token)

        case .basic(let username, let password):
            return .authorization(username: username, password: password)

        case .custom(let token):
            return .authorization(token)
        }
    }
}
