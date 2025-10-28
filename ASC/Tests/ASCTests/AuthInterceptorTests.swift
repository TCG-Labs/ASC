// AuthInterceptorTests.swift
// ASC - Alamofire Swift Client Tests

import Testing
import Foundation
@testable import ASC

struct AuthInterceptorTests {
    // MARK: - Test Helpers

    final class MockTokenStorage: TokenStorage, @unchecked Sendable {
        var accessToken: String?
        var refreshToken: String?
        var tokenType: TokenType = .bearer

        var refreshRequest: (any NetworkRequest)? {
            nil
        }

        func clearTokens() {
            accessToken = nil
            refreshToken = nil
        }
    }

    // MARK: - Tests

    @Test("Token type enum raw values")
    func testTokenTypeRawValues() {
        #expect(TokenType.bearer.rawValue == "Bearer")
        #expect(TokenType.basic.rawValue == "Basic")
        #expect(TokenType.custom("MyAuth").rawValue == "MyAuth")
    }

    @Test("Token storage clear tokens")
    func testClearTokens() {
        let storage = MockTokenStorage()
        storage.accessToken = "test-token"
        storage.refreshToken = "refresh-token"

        #expect(storage.accessToken != nil)
        #expect(storage.refreshToken != nil)

        storage.clearTokens()

        #expect(storage.accessToken == nil)
        #expect(storage.refreshToken == nil)
    }

    @Test("Default token storage implementations")
    func testDefaultTokenStorageImplementations() {
        final class MinimalTokenStorage: TokenStorage, @unchecked Sendable {
            var accessToken: String?
            var refreshToken: String?

            func clearTokens() {
                accessToken = nil
                refreshToken = nil
            }
        }

        let storage = MinimalTokenStorage()
        storage.accessToken = "token"

        // Test default implementations
        #expect(storage.refreshToken == nil)
        #expect(storage.tokenType == .bearer)
        #expect(storage.refreshRequest == nil)

        // Test default executeRefreshToken does nothing
        Task {
            let client = NetworkClient(baseURL: "https://api.example.com")
            try await storage.executeRefreshToken(with: client)
            // Should not throw
        }
    }

    // MARK: - AuthInterceptor Tests

    @Test("AuthInterceptor adds Authorization header when authentication required")
    func testAuthInterceptorAddsAuthorizationHeader() async throws {
        let storage = MockTokenStorage()
        storage.accessToken = "test-access-token"
        storage.tokenType = .bearer

        let interceptor = AuthInterceptor(storage: storage)

        var urlRequest = URLRequest(url: URL(string: "https://api.example.com/test")!)
        urlRequest.headers.add(.authenticationRequired)

        let adaptedRequest = try await withCheckedThrowingContinuation { continuation in
            interceptor.adapt(urlRequest, for: Session()) { result in
                continuation.resume(with: result)
            }
        }

        #expect(adaptedRequest.headers["Authorization"] == "Bearer test-access-token")
    }

    @Test("AuthInterceptor skips when authentication not required")
    func testAuthInterceptorSkipsWhenNotRequired() async throws {
        let storage = MockTokenStorage()
        storage.accessToken = "test-access-token"

        let interceptor = AuthInterceptor(storage: storage)

        let urlRequest = URLRequest(url: URL(string: "https://api.example.com/test")!)

        let adaptedRequest = try await withCheckedThrowingContinuation { continuation in
            interceptor.adapt(urlRequest, for: Session()) { result in
                continuation.resume(with: result)
            }
        }

        #expect(adaptedRequest.headers["Authorization"] == nil)
    }

    @Test("AuthInterceptor fails when no token available")
    func testAuthInterceptorFailsWhenNoToken() async {
        let storage = MockTokenStorage()
        storage.accessToken = nil

        let interceptor = AuthInterceptor(storage: storage)

        var urlRequest = URLRequest(url: URL(string: "https://api.example.com/test")!)
        urlRequest.headers.add(.authenticationRequired)

        let session = Session()

        await #expect(throws: ASCError.self) {
            try await withCheckedThrowingContinuation { continuation in
                interceptor.adapt(urlRequest, for: session) { result in
                    continuation.resume(with: result)
                }
            }
        }
    }

    @Test("AuthInterceptor uses Bearer token type by default")
    func testAuthInterceptorUsesBearerTokenType() async throws {
        let storage = MockTokenStorage()
        storage.accessToken = "my-token"
        storage.tokenType = .bearer

        let interceptor = AuthInterceptor(storage: storage)

        var urlRequest = URLRequest(url: URL(string: "https://api.example.com/test")!)
        urlRequest.headers.add(.authenticationRequired)

        let adaptedRequest = try await withCheckedThrowingContinuation { continuation in
            interceptor.adapt(urlRequest, for: Session()) { result in
                continuation.resume(with: result)
            }
        }

        #expect(adaptedRequest.headers["Authorization"] == "Bearer my-token")
    }

    @Test("AuthInterceptor uses custom token type")
    func testAuthInterceptorUsesCustomTokenType() async throws {
        let storage = MockTokenStorage()
        storage.accessToken = "custom-token-value"
        storage.tokenType = .custom("CustomAuth")

        let interceptor = AuthInterceptor(storage: storage)

        var urlRequest = URLRequest(url: URL(string: "https://api.example.com/test")!)
        urlRequest.headers.add(.authenticationRequired)

        let adaptedRequest = try await withCheckedThrowingContinuation { continuation in
            interceptor.adapt(urlRequest, for: Session()) { result in
                continuation.resume(with: result)
            }
        }

        #expect(adaptedRequest.headers["Authorization"] == "CustomAuth custom-token-value")
    }

    @Test("AuthInterceptor uses Basic token type")
    func testAuthInterceptorUsesBasicTokenType() async throws {
        let storage = MockTokenStorage()
        storage.accessToken = "base64-encoded-credentials"
        storage.tokenType = .basic

        let interceptor = AuthInterceptor(storage: storage)

        var urlRequest = URLRequest(url: URL(string: "https://api.example.com/test")!)
        urlRequest.headers.add(.authenticationRequired)

        let adaptedRequest = try await withCheckedThrowingContinuation { continuation in
            interceptor.adapt(urlRequest, for: Session()) { result in
                continuation.resume(with: result)
            }
        }

        #expect(adaptedRequest.headers["Authorization"] == "Basic base64-encoded-credentials")
    }
}
