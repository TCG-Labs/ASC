// URLBuilderTests.swift
// ASC - Alamofire Swift Client Tests

import Testing
import Foundation
@testable import ASC

struct URLBuilderTests {
    // MARK: - Test Helpers

    struct TestRequest: NetworkRequest {
        typealias Response = EmptyResponse

        var baseURL: String?
        var path: String
        var method: HTTPMethod { .get }
    }

    // MARK: - Tests

    @Test("Build URL with base URL from configuration")
    func testBuildURLWithConfigBaseURL() throws {
        let builder = URLBuilder()
        let request = TestRequest(baseURL: nil, path: "/users")
        let url = try builder.buildURL(from: request, baseURL: "https://api.example.com")

        #expect(url.absoluteString == "https://api.example.com/users")
    }

    @Test("Build URL with base URL from request")
    func testBuildURLWithRequestBaseURL() throws {
        let builder = URLBuilder()
        let request = TestRequest(baseURL: "https://custom.api.com", path: "/data")
        let url = try builder.buildURL(from: request, baseURL: "https://api.example.com")

        #expect(url.absoluteString == "https://custom.api.com/data")
    }

    @Test("Build URL without leading slash in path")
    func testBuildURLWithoutLeadingSlash() throws {
        let builder = URLBuilder()
        let request = TestRequest(baseURL: nil, path: "users/123")
        let url = try builder.buildURL(from: request, baseURL: "https://api.example.com/")

        #expect(url.absoluteString == "https://api.example.com/users/123")
    }

    @Test("Build URL with trailing slash in base URL")
    func testBuildURLWithTrailingSlash() throws {
        let builder = URLBuilder()
        let request = TestRequest(baseURL: "https://api.example.com/", path: "/users")
        let url = try builder.buildURL(from: request, baseURL: nil)

        #expect(url.absoluteString == "https://api.example.com//users")
    }

    @Test("Build URL with query parameters in path")
    func testBuildURLWithQueryParams() throws {
        let builder = URLBuilder()
        let request = TestRequest(baseURL: nil, path: "/search?q=swift&page=1")
        let url = try builder.buildURL(from: request, baseURL: "https://api.example.com")

        #expect(url.absoluteString == "https://api.example.com/search?q=swift&page=1")
    }

    @Test("Throw error when base URL is missing")
    func testThrowErrorWhenBaseURLMissing() {
        let builder = URLBuilder()
        let request = TestRequest(baseURL: nil, path: "/users")

        #expect(throws: URLBuildError.self) {
            _ = try builder.buildURL(from: request, baseURL: nil)
        }
    }

    @Test("Build URL with special characters")
    func testBuildURLWithSpecialCharacters() throws {
        let builder = URLBuilder()
        let request = TestRequest(baseURL: nil, path: "/users/john@example.com")
        let url = try builder.buildURL(from: request, baseURL: "https://api.example.com")

        #expect(url.absoluteString.contains("/users/john@example.com"))
    }

    @Test("Build URL with Unicode characters in path")
    func testBuildURLWithUnicode() throws {
        let builder = URLBuilder()
        let request = TestRequest(baseURL: nil, path: "/users/名前")
        let url = try builder.buildURL(from: request, baseURL: "https://api.example.com")

        #expect(url.absoluteString.contains("api.example.com"))
    }

    @Test("Build URL with HTTPS scheme")
    func testBuildURLWithHTTPS() throws {
        let builder = URLBuilder()
        let request = TestRequest(baseURL: "https://secure.api.com", path: "/data")
        let url = try builder.buildURL(from: request, baseURL: nil)

        #expect(url.scheme == "https")
    }

    @Test("Build URL with HTTP scheme")
    func testBuildURLWithHTTP() throws {
        let builder = URLBuilder()
        let request = TestRequest(baseURL: "http://localhost:8080", path: "/test")
        let url = try builder.buildURL(from: request, baseURL: nil)

        #expect(url.scheme == "http")
        #expect(url.host == "localhost")
        #expect(url.port == 8080)
    }
}
