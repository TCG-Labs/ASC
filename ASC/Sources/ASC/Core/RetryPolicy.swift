// RetryPolicy.swift
// ASC - Alamofire Swift Client

// Retry policy configuration for failed requests.

import Foundation

/// Configuration for request retry behavior.
///
/// Defines how and when failed requests should be retried.
/// Use this to implement resilient network communication with
/// automatic retry on transient failures.
public struct RetryPolicy: Sendable {
    /// Maximum number of retry attempts.
    ///
    /// After this many retries, the request will fail permanently.
    /// Set to 0 to disable retries.
    public let maxRetries: Int

    /// Base delay between retries in seconds.
    ///
    /// The actual delay may be longer if exponential backoff is enabled.
    public let retryDelay: TimeInterval

    /// Whether to use exponential backoff for retry delays.
    ///
    /// When enabled, each subsequent retry waits longer:
    /// - 1st retry: retryDelay
    /// - 2nd retry: retryDelay * 2
    /// - 3rd retry: retryDelay * 4
    /// - etc.
    public let exponentialBackoff: Bool

    /// HTTP status codes that should trigger a retry.
    ///
    /// Common retryable codes: 408 (Request Timeout), 429 (Too Many Requests),
    /// 500 (Internal Server Error), 502 (Bad Gateway), 503 (Service Unavailable), 504 (Gateway Timeout)
    public let retryableStatusCodes: Set<HTTPStatusCode>

    /// Whether to retry on network errors (no connection, timeout, etc.)
    public let retryOnNetworkError: Bool

    /// Creates a new retry policy.
    ///
    /// - Parameters:
    ///   - maxRetries: Maximum number of retry attempts (default: 3)
    ///   - retryDelay: Base delay between retries in seconds (default: 1.0)
    ///   - exponentialBackoff: Use exponential backoff (default: true)
    ///   - retryableStatusCodes: Status codes that trigger retry (default: 408, 429, 500, 502, 503, 504)
    ///   - retryOnNetworkError: Retry on network errors (default: true)
    public init(
        maxRetries: Int = 3,
        retryDelay: TimeInterval = 1.0,
        exponentialBackoff: Bool = true,
        retryableStatusCodes: Set<HTTPStatusCode> = [408, 429, 500, 502, 503, 504],
        retryOnNetworkError: Bool = true
    ) {
        self.maxRetries = maxRetries
        self.retryDelay = retryDelay
        self.exponentialBackoff = exponentialBackoff
        self.retryableStatusCodes = retryableStatusCodes
        self.retryOnNetworkError = retryOnNetworkError
    }

    /// Default retry policy with sensible defaults.
    ///
    /// - 3 retry attempts
    /// - 1 second base delay
    /// - Exponential backoff enabled
    /// - Retries on common server errors and network failures
    public static let `default` = RetryPolicy()

    /// No retry policy - fail immediately on errors.
    public static let none = RetryPolicy(maxRetries: 0)

    /// Aggressive retry policy for critical requests.
    ///
    /// - 5 retry attempts
    /// - 2 second base delay
    /// - Exponential backoff enabled
    public static let aggressive = RetryPolicy(
        maxRetries: 5,
        retryDelay: 2.0
    )
}

/// Extension to add retry policy to NetworkRequest.
public extension NetworkRequest {
    /// Retry policy for this request.
    ///
    /// Override this to customize retry behavior for specific requests.
    /// Default is `.default` (3 retries with exponential backoff).
    var retryPolicy: RetryPolicy { .default }
}
