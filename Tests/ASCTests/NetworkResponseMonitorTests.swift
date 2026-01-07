// NetworkResponseMonitorTests.swift
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

// Tests for NetworkResponseMonitor functionality.

import Alamofire
import Foundation
import Synchronization
import Testing
@testable import ASC

// MARK: - Mock Handler

/// Mock handler for testing network response notifications.
final class MockNetworkResponseHandler: NetworkResponseHandler, @unchecked Sendable {
    private let _receivedInfo = Mutex<[NetworkResponseInfo]>([])
    var receivedInfo: [NetworkResponseInfo] {
        _receivedInfo.withLock { $0 }
    }

    private let _callCount = Mutex<Int>(0)
    var callCount: Int {
        _callCount.withLock { $0 }
    }

    func onResponseReceived(_ info: NetworkResponseInfo) {
        _callCount.withLock { $0 += 1 }
        _receivedInfo.withLock { $0.append(info) }
    }

    func reset() {
        _callCount.withLock { $0 = 0 }
        _receivedInfo.withLock { $0 = [] }
    }
}

// MARK: - Test Suite

@Suite("NetworkResponseMonitor Tests", .serialized)
struct NetworkResponseMonitorTests {
    // MARK: - Setup

    /// Creates a test configuration with mock URL protocol.
    func createTestConfiguration(
        handler: (any NetworkResponseHandler)? = nil
    ) -> NetworkClientConfiguration {
        let urlConfig = URLSessionConfiguration.ephemeral
        urlConfig.protocolClasses = [MockURLProtocol.self]

        return NetworkClientConfiguration(
            baseURL: "https://api.example.com",
            sessionType: .custom(urlConfig),
            networkResponseHandler: handler,
            connectivityCheckEnabled: false
        )
    }

    // MARK: - Monitor Initialization Tests

    @Test("Monitor initializes with handler")
    func testMonitorInitializesWithHandler() {
        let handler = MockNetworkResponseHandler()
        let monitor = NetworkResponseMonitor(handler: handler)

        // Queue is always initialized
        let _ = monitor.queue
    }

    @Test("Monitor initializes without handler")
    func testMonitorInitializesWithoutHandler() {
        let monitor = NetworkResponseMonitor(handler: nil)

        // Queue is always initialized
        let _ = monitor.queue
    }

    // MARK: - Response Notification Tests

    @Test("Monitor notifies handler for all status codes")
    func testMonitorNotifiesHandlerForAllStatusCodes() async throws {
        MockURLProtocol.reset()
        defer { MockURLProtocol.reset() }

        let handler = MockNetworkResponseHandler()
        let config = createTestConfiguration(handler: handler)
        let client = NetworkClient(configuration: config)

        // Test various status codes
        let statusCodes = [200, 201, 400, 401, 403, 404, 500, 503]

        for statusCode in statusCodes {
            handler.reset()

            MockURLProtocol.setSuccessResponse(
                data: try JSONEncoder().encode(MockResponse(id: 1, name: "Test")),
                statusCode: statusCode
            )

            do {
                _ = try await client.execute(MockGetRequest())
            } catch {
                // Expected for error status codes
            }

            // Wait a bit for async notification
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

            #expect(handler.callCount == 1, "Should notify for status code \(statusCode)")
            #expect(handler.receivedInfo.count == 1)
            #expect(handler.receivedInfo.first?.response.statusCode == statusCode)
        }
    }

    @Test("Monitor notifies handler for 401 status")
    func testMonitorNotifiesHandlerFor401() async throws {
        MockURLProtocol.reset()
        defer { MockURLProtocol.reset() }

        let handler = MockNetworkResponseHandler()
        let config = createTestConfiguration(handler: handler)
        let client = NetworkClient(configuration: config)

        // Set up 401 response
        let errorData = try JSONEncoder().encode(["error": "Unauthorized"])
        MockURLProtocol.setSuccessResponse(data: errorData, statusCode: 401)

        // Execute request that will return 401
        do {
            _ = try await client.execute(MockGetRequest())
        } catch {
            // Expected to throw error
        }

        // Wait a bit for async notification
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        #expect(handler.callCount == 1)
        #expect(handler.receivedInfo.count == 1)
        #expect(handler.receivedInfo.first?.response.statusCode == 401)
    }

    @Test("Monitor notifies handler for successful responses")
    func testMonitorNotifiesHandlerForSuccess() async throws {
        MockURLProtocol.reset()
        defer { MockURLProtocol.reset() }

        let handler = MockNetworkResponseHandler()
        let config = createTestConfiguration(handler: handler)
        let client = NetworkClient(configuration: config)

        // Set up 200 response
        MockURLProtocol.setSuccessResponse(
            data: try JSONEncoder().encode(MockResponse(id: 1, name: "Test"))
        )

        let response = try await client.execute(MockGetRequest())

        // Wait a bit for async notification
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        #expect(handler.callCount == 1)
        #expect(handler.receivedInfo.count == 1)
        #expect(handler.receivedInfo.first?.response.statusCode == 200)
        #expect(response.id == 1)
    }

    // MARK: - Error Message Extraction Tests

    @Test("Monitor extracts error message from response data")
    func testMonitorExtractsErrorMessage() async throws {
        MockURLProtocol.reset()
        defer { MockURLProtocol.reset() }

        let handler = MockNetworkResponseHandler()
        let config = createTestConfiguration(handler: handler)
        let client = NetworkClient(configuration: config)

        // Set up 401 response with error message
        let errorData = try JSONEncoder().encode(["error": "Token expired"])
        MockURLProtocol.setSuccessResponse(data: errorData, statusCode: 401)

        do {
            _ = try await client.execute(MockGetRequest())
        } catch {
            // Expected
        }

        // Wait for async notification
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        let info = handler.receivedInfo.first
        #expect(info != nil)
        #expect(info?.errorMessage == "Token expired")
    }

    @Test("Monitor extracts error message from nested JSON")
    func testMonitorExtractsErrorMessageFromNestedJSON() async throws {
        MockURLProtocol.reset()
        defer { MockURLProtocol.reset() }

        let handler = MockNetworkResponseHandler()
        let config = createTestConfiguration(handler: handler)
        let client = NetworkClient(configuration: config)

        // Set up 401 response with nested error message
        let errorData = try JSONEncoder().encode([
            "error": [
                "message": "Session expired"
            ]
        ])
        MockURLProtocol.setSuccessResponse(data: errorData, statusCode: 401)

        do {
            _ = try await client.execute(MockGetRequest())
        } catch {
            // Expected
        }

        // Wait for async notification
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        let info = handler.receivedInfo.first
        #expect(info != nil)
        #expect(info?.errorMessage == "Session expired")
    }

    // MARK: - Integration Tests

    @Test("Monitor works with NetworkClientConfiguration")
    func testMonitorWorksWithConfiguration() async throws {
        MockURLProtocol.reset()
        defer { MockURLProtocol.reset() }

        let handler = MockNetworkResponseHandler()

        let urlConfig = URLSessionConfiguration.ephemeral
        urlConfig.protocolClasses = [MockURLProtocol.self]

        let config = NetworkClientConfiguration(
            baseURL: "https://api.example.com",
            sessionType: .custom(urlConfig),
            networkResponseHandler: handler,
            connectivityCheckEnabled: false
        )

        // Verify monitor was added
        #expect(config.eventMonitors.contains { $0 is NetworkResponseMonitor })

        let client = NetworkClient(configuration: config)

        // Set up 200 response
        MockURLProtocol.setSuccessResponse(
            data: try JSONEncoder().encode(MockResponse(id: 1, name: "Test"))
        )

        _ = try await client.execute(MockGetRequest())

        // Wait for async notification
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        #expect(handler.callCount == 1)
    }

    @Test("Monitor is not created when no handler provided")
    func testMonitorNotCreatedWithoutHandler() {
        let config = NetworkClientConfiguration(
            baseURL: "https://api.example.com",
            networkResponseHandler: nil,
            connectivityCheckEnabled: false
        )

        // Verify monitor was not added
        let hasMonitor = config.eventMonitors.contains { $0 is NetworkResponseMonitor }
        #expect(hasMonitor == false)
    }
}
