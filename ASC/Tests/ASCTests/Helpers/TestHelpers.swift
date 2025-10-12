// TestHelpers.swift
// ASC Tests
//
// Helper functions and utilities for tests.

import Foundation
@testable import ASC

// MARK: - Test Constants

/// Constants used throughout the test suite.
public enum TestConstants {
    /// Default base URL for test clients.
    public static let defaultBaseURL = "https://api.example.com"

    /// Wait time for event monitors to process events (nanoseconds).
    public static let monitorWaitTime: UInt64 = 100_000_000 // 0.1 seconds
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
