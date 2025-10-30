// AuthInterceptorTests.swift
// ASC - Alamofire Swift Client Tests
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

import Testing
import Foundation
@testable import ASC

struct AuthInterceptorTests {
    // MARK: - Tests

    @Test("AuthToken header generation")
    func testAuthTokenHeaderGeneration() {
        // Test Bearer token
        let bearer = AuthToken.bearer(token: "test-bearer-token")
        let bearerHeader = bearer.header
        #expect(bearerHeader.name == "Authorization")
        #expect(bearerHeader.value == "Bearer test-bearer-token")

        // Test Basic authentication
        let basic = AuthToken.basic(username: "testuser", password: "testpass")
        let basicHeader = basic.header
        #expect(basicHeader.name == "Authorization")
        let expectedBasic = "Basic \(Data("testuser:testpass".utf8).base64EncodedString())"
        #expect(basicHeader.value == expectedBasic)

        // Test Custom token
        let custom = AuthToken.custom(token: "custom-token")
        let customHeader = custom.header
        #expect(customHeader.name == "Authorization")
        #expect(customHeader.value == "custom-token")
    }

    @Test("Token storage flush")
    func testFlush() {
        let storage = MockTokenStorage(authToken: .bearer(token: "test-token"))

        #expect(storage.authToken != nil)

        storage.flush()

        #expect(storage.authToken == nil)
    }

    @Test("Default token storage implementations")
    func testDefaultTokenStorageImplementations() async throws {
        final class MinimalTokenStorage: TokenStorage, @unchecked Sendable {
            func flush() {}
        }

        let storage = MinimalTokenStorage()

        // Test default implementations
        #expect(storage.authToken == nil)
        #expect(storage.refreshRequest == nil)

        // Test default executeRefreshToken does nothing
        let client = NetworkClient(baseURL: "https://api.example.com")
        try await storage.executeRefreshToken(with: client)
        // Should not throw
    }

    // MARK: - AuthInterceptor Tests

    @Test("AuthInterceptor adds Bearer Authorization header")
    func testAuthInterceptorAddsBearerAuthorizationHeader() async throws {
        // Given: Storage with bearer token
        let storage = MockTokenStorage(authToken: .bearer(token: "test-access-token"))
        let interceptor = AuthInterceptor(storage: storage)

        var urlRequest = URLRequest(url: URL(string: "https://api.example.com/test")!)
        urlRequest.headers.add(.authenticationRequired)

        // When: Interceptor adapts the request
        let adaptedRequest = try await withCheckedThrowingContinuation { continuation in
            interceptor.adapt(urlRequest, for: Session()) { result in
                continuation.resume(with: result)
            }
        }

        // Then: Authorization header is added
        #expect(adaptedRequest.headers["Authorization"] == "Bearer test-access-token")
    }

    @Test("AuthInterceptor skips when authentication not required")
    func testAuthInterceptorSkipsWhenNotRequired() async throws {
        // Given: Storage with token but request without auth requirement
        let storage = MockTokenStorage(authToken: .bearer(token: "test-token"))
        let interceptor = AuthInterceptor(storage: storage)

        let urlRequest = URLRequest(url: URL(string: "https://api.example.com/test")!)
        // Note: No .authenticationRequired header

        // When: Interceptor adapts the request
        let adaptedRequest = try await withCheckedThrowingContinuation { continuation in
            interceptor.adapt(urlRequest, for: Session()) { result in
                continuation.resume(with: result)
            }
        }

        // Then: No Authorization header is added
        #expect(adaptedRequest.headers["Authorization"] == nil)
    }

    @Test("AuthInterceptor fails when no token available")
    func testAuthInterceptorFailsWhenNoToken() async {
        // Given: Storage without token
        let storage = MockTokenStorage(authToken: nil)
        let interceptor = AuthInterceptor(storage: storage)

        var urlRequest = URLRequest(url: URL(string: "https://api.example.com/test")!)
        urlRequest.headers.add(.authenticationRequired)

        // When/Then: Interceptor throws error
        await #expect(throws: ASCError.self) {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<URLRequest, Error>) in
                interceptor.adapt(urlRequest, for: Session()) { result in
                    continuation.resume(with: result)
                }
            }
        }
    }

    @Test("AuthInterceptor uses Basic authentication")
    func testAuthInterceptorUsesBasicAuth() async throws {
        // Given: Storage with basic auth
        let storage = MockTokenStorage(
            authToken: .basic(username: "testuser", password: "testpass")
        )
        let interceptor = AuthInterceptor(storage: storage)

        var urlRequest = URLRequest(url: URL(string: "https://api.example.com/test")!)
        urlRequest.headers.add(.authenticationRequired)

        // When: Interceptor adapts the request
        let adaptedRequest = try await withCheckedThrowingContinuation { continuation in
            interceptor.adapt(urlRequest, for: Session()) { result in
                continuation.resume(with: result)
            }
        }

        // Then: Basic Authorization header is added
        let expectedValue = "Basic \(Data("testuser:testpass".utf8).base64EncodedString())"
        #expect(adaptedRequest.headers["Authorization"] == expectedValue)
    }

    @Test("AuthInterceptor uses custom token")
    func testAuthInterceptorUsesCustomToken() async throws {
        // Given: Storage with custom token
        let storage = MockTokenStorage(authToken: .custom(token: "custom-token-value"))
        let interceptor = AuthInterceptor(storage: storage)

        var urlRequest = URLRequest(url: URL(string: "https://api.example.com/test")!)
        urlRequest.headers.add(.authenticationRequired)

        // When: Interceptor adapts the request
        let adaptedRequest = try await withCheckedThrowingContinuation { continuation in
            interceptor.adapt(urlRequest, for: Session()) { result in
                continuation.resume(with: result)
            }
        }

        // Then: Custom Authorization header is added
        #expect(adaptedRequest.headers["Authorization"] == "custom-token-value")
    }
}
