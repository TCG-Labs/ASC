// MockTokenStorage.swift
// ASC - Alamofire Swift Client

// Mock token storage for testing authentication.

import Foundation
import Synchronization
@testable import ASC

/// Mock token storage for testing
final class MockTokenStorage: TokenStorage, @unchecked Sendable {
    private let _accessToken: Mutex<String?>
    private let _refreshToken: Mutex<String?>
    private let _tokenType: Mutex<TokenType>

    var accessToken: String? {
        get { _accessToken.withLock { $0 } }
        set { _accessToken.withLock { $0 = newValue } }
    }

    var refreshToken: String? {
        get { _refreshToken.withLock { $0 } }
        set { _refreshToken.withLock { $0 = newValue } }
    }

    var tokenType: TokenType {
        get { _tokenType.withLock { $0 } }
        set { _tokenType.withLock { $0 = newValue } }
    }

    init(
        accessToken: String? = nil,
        refreshToken: String? = nil,
        tokenType: TokenType = .bearer
    ) {
        self._accessToken = Mutex(accessToken)
        self._refreshToken = Mutex(refreshToken)
        self._tokenType = Mutex(tokenType)
    }

    func clearTokens() {
        _accessToken.withLock { $0 = nil }
        _refreshToken.withLock { $0 = nil }
    }
}
