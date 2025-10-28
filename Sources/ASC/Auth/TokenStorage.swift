// TokenStorage.swift
// ASC - Alamofire Swift Client

// Storage for authentication tokens.

import Foundation

/// Storage for authentication tokens.
///
/// Implement this protocol to provide custom token storage (Keychain, UserDefaults, etc.).
public protocol TokenStorage: Sendable {
    var authToken: AuthToken? { get }

    /// Network request for refreshing tokens
    var refreshRequest: (any NetworkRequest)? { get }

    /// Executes token refresh using the provided client
    func executeRefreshToken(with client: NetworkClient) async throws

    /// Flushes the storage state (clears all stored tokens)
    func flush()
}

public extension TokenStorage {
    /// Default auth token is nil.
    var authToken: AuthToken? { nil }

    /// Default refresh request is nil.
    var refreshRequest: (any NetworkRequest)? { nil }

    /// Default implementation does nothing.
    func executeRefreshToken(with client: NetworkClient) async throws { }
}
