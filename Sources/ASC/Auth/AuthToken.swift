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
/// let token = AuthToken.bearer(token: "abc123")
/// // Generates: Authorization: Bearer abc123
///
/// let basicAuth = AuthToken.basic(username: "user", password: "pass")
/// // Generates: Authorization: Basic dXNlcjpwYXNz (base64 encoded)
/// ```
public enum AuthToken: Sendable, Equatable {
    /// Bearer token authentication (most common for OAuth 2.0)
    ///
    /// Format: `Authorization: Bearer {token}`
    case bearer(token: String)

    /// Basic authentication
    ///
    /// Format: `Authorization: Basic {base64(username:password)}`
    case basic(username: String, password: String)

    /// Custom token type
    ///
    /// Format: `Authorization: {token}`
    case custom(token: String)

    public var header: HTTPHeader {
        switch self {
        case let .bearer(token):
            return .authorization(bearerToken: token)

        case let .basic(username, password):
            return .authorization(username: username, password: password)

        case let .custom(token):
            return .authorization(token)
        }
    }
}
