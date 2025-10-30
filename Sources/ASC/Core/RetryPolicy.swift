// RetryPolicy.swift
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

// Convenient extensions for Alamofire's RetryPolicy.

import Foundation

/// Extension providing convenient preset retry policies.
///
/// Instead of creating a custom wrapper, we extend Alamofire's RetryPolicy
/// with convenient factory methods for common use cases.
public extension Alamofire.RetryPolicy {
    /// No retry policy - fail immediately on errors.
    ///
    /// Use this for requests that should not be retried, or in tests
    /// to avoid unexpected retry behavior.
    static var none: Alamofire.RetryPolicy? {
        nil
    }

    /// Default retry policy with sensible defaults.
    ///
    /// Configuration:
    /// - 3 retry attempts (retryLimit: 3)
    /// - Exponential backoff (base: 2, scale: 0.5)
    /// - Retries on common server errors (408, 500, 502, 503, 504)
    /// - Retries on network failures
    /// - All idempotent HTTP methods
    ///
    /// Retry delays: 0.5s, 1.0s, 2.0s
    static var `default`: Alamofire.RetryPolicy {
        Alamofire.RetryPolicy(
            retryLimit: 3,
            exponentialBackoffBase: 2,
            exponentialBackoffScale: 0.5
        )
    }

    /// Aggressive retry policy for critical requests.
    ///
    /// Configuration:
    /// - 5 retry attempts (retryLimit: 5)
    /// - Exponential backoff (base: 2, scale: 1.0)
    /// - Retries on common server errors (408, 500, 502, 503, 504)
    /// - Retries on network failures
    /// - All idempotent HTTP methods
    ///
    /// Retry delays: 1.0s, 2.0s, 4.0s, 8.0s, 16.0s
    static var aggressive: Alamofire.RetryPolicy {
        Alamofire.RetryPolicy(
            retryLimit: 5,
            exponentialBackoffBase: 2,
            exponentialBackoffScale: 1.0
        )
    }

    /// Conservative retry policy for non-critical requests.
    ///
    /// Configuration:
    /// - 2 retry attempts (retryLimit: 2)
    /// - Exponential backoff (base: 2, scale: 0.5)
    /// - Retries on common server errors (408, 500, 502, 503, 504)
    /// - Retries on network failures
    /// - All idempotent HTTP methods
    ///
    /// Retry delays: 0.5s, 1.0s
    static var conservative: Alamofire.RetryPolicy {
        Alamofire.RetryPolicy(
            retryLimit: 2,
            exponentialBackoffBase: 2,
            exponentialBackoffScale: 0.5
        )
    }
}

/// Extension to add retry policy to NetworkRequest.
public extension NetworkRequest {
    /// Retry policy for this request.
    ///
    /// Override this to customize retry behavior for specific requests.
    /// Default is `nil` (no retries) to avoid unexpected behavior in tests.
    ///
    /// Example:
    /// ```swift
    /// struct MyRequest: NetworkRequest {
    ///     var retryPolicy: Alamofire.RetryPolicy? { .default }
    /// }
    /// ```
    var retryPolicy: Alamofire.RetryPolicy? { nil }
}
