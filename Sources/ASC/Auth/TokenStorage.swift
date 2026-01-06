// TokenStorage.swift
// ASC - Alamofire Swift Client
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

// Storage for authentication tokens.

import Foundation
import JWTDecode

// MARK: - TokenStorage
/// Storage for authentication tokens.
///
/// Implement this protocol to provide custom token storage (Keychain, UserDefaults, etc.).
public protocol TokenStorage: Sendable {
    var authToken: AuthToken? { get }

    /// Flushes the storage state (clears all stored tokens)
    func flush()
}

public extension TokenStorage {
    /// Default auth token is nil.
    var authToken: AuthToken? { nil }
}

// MARK: - OAuthTokenStorage
public protocol OAuthTokenStorage: TokenStorage {
    func getAuthCredential() -> OAuthCredential?

    /// Executes token refresh
    func executeRefreshToken() async throws
}

extension OAuthTokenStorage {
    public func getAuthCredential() -> OAuthCredential? {
        if let authToken {
            .init(authToken: authToken)
        } else {
            nil
        }
    }

    /// Default implementation does nothing.
    public func executeRefreshToken() async throws { }
}
