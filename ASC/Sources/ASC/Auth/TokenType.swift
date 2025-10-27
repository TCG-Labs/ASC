// TokenType.swift
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
///     tokenType: .bearer
/// )
/// // Authorization: Bearer abc123
/// ```
public enum TokenType: Sendable, Equatable {
    /// Bearer token authentication (most common for OAuth 2.0)
    ///
    /// Format: `Authorization: Bearer {token}`
    case bearer

    /// Basic authentication
    ///
    /// Format: `Authorization: Basic {token}`
    case basic

    /// Custom token type
    ///
    /// Format: `Authorization: {rawValue} {token}`
    case custom(String)

    /// Raw string value for Authorization header
    public var rawValue: String {
        switch self {
        case .bearer:
            return "Bearer"

        case .basic:
            return "Basic"

        case .custom(let value):
            return value
        }
    }
}

public extension HTTPHeader {
    /// Authentication required marker header.
    ///
    /// This header marks requests that require authentication.
    /// When present, `AuthInterceptor` will inject the access token.
    static var authenticationRequired: Self {
        .init(name: "X-ASC-Auth-Required", value: "true")
    }
}
