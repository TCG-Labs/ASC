// MockTokenStorage.swift
// ASC - Alamofire Swift Client Tests

// Mock token storage for testing authentication.

import Foundation
import Synchronization
@testable import ASC

/// Mock token storage for testing authentication.
///
/// Provides thread-safe storage for testing `TokenStorage` protocol implementations.
final class MockTokenStorage: TokenStorage, @unchecked Sendable {
    private let _authToken: Mutex<AuthToken?>

    var authToken: AuthToken? {
        get { _authToken.withLock { $0 } }
        set { _authToken.withLock { $0 = newValue } }
    }

    var refreshRequest: (any NetworkRequest)? {
        nil
    }

    init(authToken: AuthToken? = nil) {
        self._authToken = Mutex(authToken)
    }

    func executeRefreshToken(with client: NetworkClient) async throws {
        // Mock implementation - does nothing
    }

    func flush() {
        _authToken.withLock { $0 = nil }
    }
}