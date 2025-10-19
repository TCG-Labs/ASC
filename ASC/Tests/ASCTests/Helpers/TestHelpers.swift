// TestHelpers.swift
// ASC Tests
//
// Helper functions and utilities for tests.

@testable import ASC
import Foundation

// MARK: - Test Constants

/// Constants used throughout the test suite.
public enum TestConstants {
    // MARK: - URLs

    /// Default base URL for test clients.
    public static let defaultBaseURL = "https://api.example.com"

    // MARK: - Timing

    /// Wait time for event monitors to process events (nanoseconds).
    public static let monitorWaitTime: UInt64 = 100_000_000 // 0.1 seconds

    /// Timeout constants for various test scenarios.
    public enum Timeout {
        /// Short timeout for quick operations (1 second).
        public static let short: TimeInterval = 1.0

        /// Normal timeout for standard operations (5 seconds).
        public static let normal: TimeInterval = 5.0

        /// Long timeout for slow operations (10 seconds).
        public static let long: TimeInterval = 10.0
    }

    // MARK: - HTTP Headers

    /// Common HTTP header field names.
    public enum Header {
        /// Authorization header field name.
        public static let authorization = "Authorization"

        /// Content-Type header field name.
        public static let contentType = "Content-Type"

        /// Accept header field name.
        public static let accept = "Accept"

        /// User-Agent header field name.
        public static let userAgent = "User-Agent"
    }

    // MARK: - Test Data

    /// Test data constants.
    public enum Data {
        /// Test user ID.
        public static let userId = "123"

        /// Test post ID.
        public static let postId = "456"

        /// Test bearer token.
        public static let bearerToken = "test_token_abc123"

        /// Test JSON content type.
        public static let jsonContentType = "application/json"

        /// Test API version prefix.
        public static let apiV1Prefix = "/api/v1"

        /// Test API v2 version prefix.
        public static let apiV2Prefix = "/api/v2"
    }
}

// MARK: - Setup Functions

/// Sets up a clean test environment before each test.
public func setupTest() {
    MockURLProtocol.reset()
}

/// Cleans up test environment after each test.
public func teardownTest() {
    MockURLProtocol.reset()
}

/// Creates a test configuration with MockURLProtocol.
public func createMockConfiguration() -> URLSessionConfiguration {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [MockURLProtocol.self]
    configuration.urlCache = nil // Disable URL caching
    return configuration
}

/// Creates a NetworkClient with mock configuration.
public func createMockClient(baseURL: String = TestConstants.defaultBaseURL) -> NetworkClient {
    let config = NetworkClientConfiguration(
        baseURL: baseURL,
        urlSessionConfiguration: createMockConfiguration()
    )
    return NetworkClient(configuration: config)
}

/// Creates a NetworkClient with custom configuration.
public func createMockClient(
    baseURL: String = TestConstants.defaultBaseURL,
    interceptors: [any RequestInterceptor] = [],
    eventMonitors: [any EventMonitor] = []
) -> NetworkClient {
    let config = NetworkClientConfiguration(
        baseURL: baseURL,
        urlSessionConfiguration: createMockConfiguration(),
        interceptors: interceptors,
        eventMonitors: eventMonitors
    )
    return NetworkClient(configuration: config)
}
