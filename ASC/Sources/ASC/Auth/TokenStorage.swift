// TokenStorage.swift
// ASC - Alamofire Swift Client

// Storage for authentication tokens.

import Foundation

public protocol TokenStorage: Sendable {
    var accessToken: String? { get set }
    var refreshToken: String? { get set }
    var refreshRequest: (any NetworkRequest)? { get }

    func executeRefreshToken(with client: NetworkClient) async throws

    func clearTokens()
}

public extension TokenStorage {
    var refreshToken: String? { nil }
    var refreshRequest: (any NetworkRequest)? { nil }

    func executeRefreshToken(with client: NetworkClient) async throws { }
}
