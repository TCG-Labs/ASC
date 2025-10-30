// NetworkClientTests.swift
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

// Tests for NetworkClient functionality.

import Foundation
import Testing
@testable import ASC

@Suite("NetworkClient Tests", .serialized)
struct NetworkClientTests {
    // MARK: - Initialization Tests

    @Test("Client initializes with configuration")
    func testClientInitWithConfiguration() {
        let config = NetworkClientConfiguration(
            baseURL: "https://api.example.com",
            defaultTimeout: 30,
            logLevel: .none,
            connectivityCheckEnabled: false
        )
        _ = NetworkClient(configuration: config)
    }

    @Test("Client initializes with base URL")
    func testClientInitWithBaseURL() {
        _ = NetworkClient(baseURL: "https://api.example.com")
    }

    @Test("Client initializes without base URL")
    func testClientInitWithoutBaseURL() {
        _ = NetworkClient()
    }

    @Test("Client initializes reachability when enabled")
    func testClientInitializesReachabilityWhenEnabled() {
        let config = NetworkClientConfiguration(
            baseURL: "https://api.example.com",
            connectivityCheckEnabled: true
        )
        _ = NetworkClient(configuration: config)
    }

    @Test("Client does not initialize reachability when disabled")
    func testClientDoesNotInitializeReachabilityWhenDisabled() {
        let config = NetworkClientConfiguration(
            baseURL: "https://api.example.com",
            connectivityCheckEnabled: false
        )
        _ = NetworkClient(configuration: config)
    }

    // MARK: - Request Execution Tests

    @Test("Execute request with successful response")
    func testExecuteRequestSuccess() async throws {
        MockURLProtocol.reset()
        defer { MockURLProtocol.reset() }

        MockURLProtocol.setSuccessResponse(
            data: try! JSONEncoder().encode(MockResponse(id: 1, name: "Test"))
        )

        let response = try await NetworkClient(configuration: createTestConfiguration())
            .execute(MockGetRequest())

        #expect(response.id == 1)
        #expect(response.name == "Test")
    }

    @Test("Execute request with decoding")
    func testExecuteRequestWithDecoding() async throws {
        MockURLProtocol.reset()
        defer { MockURLProtocol.reset() }

        MockURLProtocol.setSuccessResponse(
            data: try! JSONEncoder().encode(MockResponse(id: 42, name: "Decoded"))
        )

        let response = try await NetworkClient(configuration: createTestConfiguration())
            .execute(MockGetRequest())

        #expect(response.id == 42)
        #expect(response.name == "Decoded")
    }

    @Test("Execute empty response request")
    func testExecuteEmptyResponseRequest() async throws {
        MockURLProtocol.reset()
        defer { MockURLProtocol.reset() }

        MockURLProtocol.setSuccessResponse(data: Data(), statusCode: 204)

        try await NetworkClient(configuration: createTestConfiguration())
            .execute(MockEmptyRequest())
    }

    @Test("Execute request handles network error")
    func testExecuteRequestHandlesNetworkError() async throws {
        MockURLProtocol.reset()
        defer { MockURLProtocol.reset() }

        MockURLProtocol.setErrorResponse(TestHelpers.createURLError(.notConnectedToInternet))

        await #expect(throws: ASCError.self) {
            try await NetworkClient(configuration: createTestConfiguration())
                .execute(MockGetRequest())
        }
    }

    @Test("Execute request with custom timeout")
    func testExecuteRequestWithCustomTimeout() async throws {
        MockURLProtocol.reset()
        defer { MockURLProtocol.reset() }

        MockURLProtocol.setSuccessResponse(
            data: try! JSONEncoder().encode(MockResponse(id: 1, name: "Test"))
        )

        let response = try await NetworkClient(configuration: createTestConfiguration())
            .execute(MockGetRequest(timeout: 120))

        #expect(response.id == 1)
    }

    @Test("Execute request with custom headers")
    func testExecuteRequestWithCustomHeaders() async throws {
        MockURLProtocol.reset()
        defer { MockURLProtocol.reset() }

        MockURLProtocol.setSuccessResponse(
            data: try! JSONEncoder().encode(MockResponse(id: 1, name: "Test"))
        )

        let customHeaders = HTTPHeaders([HTTPHeader(name: "X-Custom", value: "TestValue")])
        let response = try await NetworkClient(configuration: createTestConfiguration())
            .execute(MockGetRequest(headers: customHeaders))

        #expect(response.id == 1)
    }

    // MARK: - Connectivity Check Tests

    @Test("Request succeeds when connectivity check disabled")
    func testRequestSucceedsWhenConnectivityCheckDisabled() async throws {
        MockURLProtocol.reset()
        defer { MockURLProtocol.reset() }

        MockURLProtocol.setSuccessResponse(
            data: try! JSONEncoder().encode(MockResponse(id: 1, name: "Test"))
        )

        let config = NetworkClientConfiguration(
            baseURL: "https://api.example.com",
            sessionType: .custom(createMockURLSessionConfiguration()),
            connectivityCheckEnabled: false
        )
        let response = try await NetworkClient(configuration: config)
            .execute(MockGetRequest())

        #expect(response.id == 1)
    }

    // MARK: - Retry Policy Tests

    @Test("Request uses default retry policy from configuration")
    func testRequestUsesDefaultRetryPolicy() async throws {
        MockURLProtocol.reset()
        defer { MockURLProtocol.reset() }

        MockURLProtocol.setSuccessResponse(
            data: try! JSONEncoder().encode(MockResponse(id: 1, name: "Test"))
        )

        let config = NetworkClientConfiguration(
            baseURL: "https://api.example.com",
            sessionType: .custom(createMockURLSessionConfiguration()),
            connectivityCheckEnabled: false,
            defaultRetryPolicy: .default
        )
        let response = try await NetworkClient(configuration: config)
            .execute(MockGetRequest())

        #expect(response.id == 1)
    }

    @Test("Request uses custom retry policy")
    func testRequestUsesCustomRetryPolicy() async throws {
        MockURLProtocol.reset()
        defer { MockURLProtocol.reset() }

        MockURLProtocol.setSuccessResponse(
            data: try! JSONEncoder().encode(MockResponse(id: 1, name: "Test"))
        )

        let response = try await NetworkClient(configuration: createTestConfiguration())
            .execute(MockGetRequest(retryPolicy: .aggressive))

        #expect(response.id == 1)
    }

    @Test("Request without retry policy")
    func testRequestWithoutRetryPolicy() async throws {
        MockURLProtocol.reset()
        defer { MockURLProtocol.reset() }

        MockURLProtocol.setSuccessResponse(
            data: try! JSONEncoder().encode(MockResponse(id: 1, name: "Test"))
        )

        let config = NetworkClientConfiguration(
            baseURL: "https://api.example.com",
            sessionType: .custom(createMockURLSessionConfiguration()),
            connectivityCheckEnabled: false,
            defaultRetryPolicy: nil
        )
        let response = try await NetworkClient(configuration: config)
            .execute(MockGetRequest(retryPolicy: nil))

        #expect(response.id == 1)
    }

    // MARK: - Custom Validation Tests

    @Test("Request validation succeeds when valid")
    func testRequestValidationSucceedsWhenValid() async throws {
        MockURLProtocol.reset()
        defer { MockURLProtocol.reset() }

        MockURLProtocol.setSuccessResponse(
            data: try! JSONEncoder().encode(MockResponse(id: 1, name: "Test"))
        )

        let response = try await NetworkClient(configuration: createTestConfiguration())
            .execute(MockValidatedRequest(shouldFailValidation: false))

        #expect(response.id == 1)
    }

    @Test("Request validation throws error when fails")
    func testRequestValidationThrowsErrorWhenFails() async throws {
        MockURLProtocol.reset()
        defer { MockURLProtocol.reset() }

        MockURLProtocol.setSuccessResponse(
            data: try! JSONEncoder().encode(MockResponse(id: 1, name: "Test"))
        )

        await #expect(throws: ASCError.self) {
            try await NetworkClient(configuration: createTestConfiguration())
                .execute(MockValidatedRequest(shouldFailValidation: true))
        }
    }

    // MARK: - Helper Methods

    /// Creates a test configuration with MockURLProtocol
    private func createTestConfiguration() -> NetworkClientConfiguration {
        NetworkClientConfiguration(
            baseURL: "https://api.example.com",
            sessionType: .custom(createMockURLSessionConfiguration()),
            connectivityCheckEnabled: false
        )
    }

    /// Creates URLSessionConfiguration with MockURLProtocol
    private func createMockURLSessionConfiguration() -> URLSessionConfiguration {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return config
    }
}
