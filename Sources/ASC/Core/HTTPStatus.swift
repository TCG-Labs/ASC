// HTTPStatus.swift
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

// Common HTTP status code ranges and values.

import Foundation

/// Common HTTP status code ranges and values.
///
/// Provides convenient access to standard HTTP status codes.
public enum HTTPStatus {
    // MARK: - Success (2xx)

    /// 200 OK - Request succeeded
    public static let ok = 200

    /// 201 Created - Resource created successfully
    public static let created = 201

    /// 204 No Content - Success with no response body
    public static let noContent = 204

    // MARK: - Redirection (3xx)

    /// 304 Not Modified - Cached version is still valid
    public static let notModified = 304

    // MARK: - Client Errors (4xx)

    /// 400 Bad Request - Invalid request syntax
    public static let badRequest = 400

    /// 401 Unauthorized - Authentication required
    public static let unauthorized = 401

    /// 403 Forbidden - Access denied
    public static let forbidden = 403

    /// 404 Not Found - Resource not found
    public static let notFound = 404

    /// 429 Too Many Requests - Rate limit exceeded
    public static let tooManyRequests = 429

    // MARK: - Server Errors (5xx)

    /// 500 Internal Server Error - Server error
    public static let internalServerError = 500

    /// 502 Bad Gateway - Invalid response from upstream
    public static let badGateway = 502

    /// 503 Service Unavailable - Server temporarily unavailable
    public static let serviceUnavailable = 503

    // MARK: - Helpers

    /// Check if status code is in success range (200-299)
    /// - Parameter code: HTTP status code to check
    /// - Returns: true if status code indicates success
    public static func isSuccess(_ code: HTTPStatusCode) -> Bool {
        (200...299).contains(code)
    }

    /// Check if status code is in client error range (400-499)
    /// - Parameter code: HTTP status code to check
    /// - Returns: true if status code indicates client error
    public static func isClientError(_ code: HTTPStatusCode) -> Bool {
        (400...499).contains(code)
    }

    /// Check if status code is in server error range (500-599)
    /// - Parameter code: HTTP status code to check
    /// - Returns: true if status code indicates server error
    public static func isServerError(_ code: HTTPStatusCode) -> Bool {
        (500...599).contains(code)
    }
}
