// TokenStorage.swift
// ASC - Alamofire Swift Client

// Storage for authentication tokens.

import Foundation

/// Storage for authentication tokens.
///
/// Implement this protocol to provide custom token storage (Keychain, UserDefaults, etc.).
public protocol TokenStorage: Sendable {
    /// Current access token
    var accessToken: String? { get set }

    /// Current refresh token
    var refreshToken: String? { get set }

    var tokenType: TokenType { get }

    /// Network request for refreshing tokens
    var refreshRequest: (any NetworkRequest)? { get }

    /// Executes token refresh using the provided client
    func executeRefreshToken(with client: NetworkClient) async throws

    /// Clears all stored tokens
    func clearTokens()
}

public extension TokenStorage {
    /// Default refresh token is nil.
    var refreshToken: String? { nil }

    /// Default token type is Bearer.
    var tokenType: TokenType { .bearer }

    /// Default refresh request is nil.
    var refreshRequest: (any NetworkRequest)? { nil }

    /// Default implementation does nothing.
    func executeRefreshToken(with client: NetworkClient) async throws { }
}
