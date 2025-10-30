// AuthToken.swift
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
