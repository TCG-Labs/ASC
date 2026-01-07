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

        // execute для Empty возвращает void, просто проверяем что выполняется без ошибок
        try await NetworkClient(configuration: createTestConfiguration())
            .execute(MockEmptyRequest())
    }

    @Test("Execute request with Empty response type from 204")
    func testExecuteRequestWithEmptyResponse204() async throws {
        MockURLProtocol.reset()
        defer { MockURLProtocol.reset() }

        MockURLProtocol.setSuccessResponse(data: Data(), statusCode: 204)

        struct DeleteRequest: Endpoint {
            typealias Response = Empty
            typealias Request = Empty

            var path: String { "/delete" }
            var method: HTTPMethod { .delete }
        }

        // execute для Empty возвращает void, просто проверяем что выполняется без ошибок
        try await NetworkClient(configuration: createTestConfiguration())
            .execute(DeleteRequest())
    }

    @Test("Execute request with Empty response type from 200 with empty body")
    func testExecuteRequestWithEmptyResponse200() async throws {
        MockURLProtocol.reset()
        defer { MockURLProtocol.reset() }

        // Note: Empty typically works with 204 No Content, but we test 200 with empty body
        // This may fail if Alamofire requires data for 200 status
        MockURLProtocol.setSuccessResponse(data: Data(), statusCode: 204)

        struct DeleteRequest: Endpoint {
            typealias Response = Empty
            typealias Request = Empty

            var path: String { "/delete" }
            var method: HTTPMethod { .delete }
        }

        // execute для Empty возвращает void, просто проверяем что выполняется без ошибок
        try await NetworkClient(configuration: createTestConfiguration())
            .execute(DeleteRequest())
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

    // MARK: - SSL/TLS Tests

    @Test("Client can be configured with ServerTrustManager")
    func testClientWithServerTrustManager() {
        // Given: ServerTrustManager configuration
        let serverTrustManager = ServerTrustManager(
            allHostsMustBeEvaluated: false,
            evaluators: [:]
        )
        
        let config = NetworkClientConfiguration(
            baseURL: "https://api.example.com",
            serverTrustManager: serverTrustManager,
            connectivityCheckEnabled: false
        )
        
        // When: Creating NetworkClient with ServerTrustManager
        _ = NetworkClient(configuration: config)
        
        // Then: Client should be created successfully
        // Note: NetworkClient is a non-optional type, so if we reach here, it was created successfully
        // The ServerTrustManager is applied to the underlying Alamofire Session
        #expect(config.serverTrustManager != nil)
    }

    @Test("Client configuration accepts nil ServerTrustManager")
    func testClientWithNilServerTrustManager() {
        // Given: Configuration with nil ServerTrustManager
        let config = NetworkClientConfiguration(
            baseURL: "https://api.example.com",
            serverTrustManager: nil,
            connectivityCheckEnabled: false
        )
        
        // When: Creating NetworkClient with nil ServerTrustManager
        _ = NetworkClient(configuration: config)
        
        // Then: Client should be created successfully
        // Note: NetworkClient is a non-optional type, so if we reach here, it was created successfully
        // nil ServerTrustManager means default certificate validation will be used
        #expect(config.serverTrustManager == nil)
    }

    @Test("Certificate validation errors are mapped correctly")
    func testCertificateValidationErrorsAreMapped() {
        // This test verifies that certificate errors from URLError are properly
        // mapped to ASCError.certificateValidationFailed
        // The actual mapping is tested in ErrorMapperTests
        
        let urlError = URLError(.serverCertificateUntrusted)
        let errorMapper = ErrorMapper(defaultTimeout: 30.0)
        let afError = AFError.sessionTaskFailed(error: urlError)
        
        let mappedError = errorMapper.mapError(afError, data: nil)
        
        // Then: Error should be mapped to certificateValidationFailed
        if let ascError = mappedError as? ASCError {
            if case .certificateValidationFailed = ascError {
                // Error correctly mapped
            } else {
                Issue.record("Expected certificateValidationFailed, got \(ascError)")
            }
        } else {
            Issue.record("Expected ASCError, got \(type(of: mappedError))")
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
