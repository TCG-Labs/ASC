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
}
