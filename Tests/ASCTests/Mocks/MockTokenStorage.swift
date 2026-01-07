// MockTokenStorage.swift
// ASC - Alamofire Swift Client Tests
//
//  Copyright (c) 2025 TCG Labs
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

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