// URLBuilderTests.swift
// ASC Tests
// Tests for URLBuilder internal component.

@testable import ASC
import Foundation
import Testing

// MARK: - URLBuilder Tests

@Test("URLBuilder builds URL with baseURL and path")
func testURLBuilderBasicURL() throws {
    let builder = URLBuilder()

    struct SimpleRequest: NetworkRequest {
        typealias Response = String
        var path: String { "/users" }
        var method: HTTPMethod { .get }
    }

    let url = try builder.buildURL(
        from: SimpleRequest(),
        baseURL: "https://api.example.com"
    )

    #expect(url.absoluteString == "https://api.example.com/users")
}

@Test("URLBuilder uses request baseURL over default baseURL")
func testURLBuilderRequestBaseURLOverride() throws {
    let builder = URLBuilder()

    struct RequestWithBaseURL: NetworkRequest {
        typealias Response = String
        var baseURL: String? { "https://custom.api.com" }
        var path: String { "/data" }
        var method: HTTPMethod { .get }
    }

    let url = try builder.buildURL(
        from: RequestWithBaseURL(),
        baseURL: "https://default.com"
    )

    #expect(url.absoluteString == "https://custom.api.com/data")
}

@Test("URLBuilder applies path prefix")
func testURLBuilderPathPrefix() throws {
    let builder = URLBuilder()

    struct RequestWithPrefix: NetworkRequest {
        typealias Response = String
        var pathPrefix: String? { "/api/v1" }
        var path: String { "/users" }
        var method: HTTPMethod { .get }
    }

    let url = try builder.buildURL(
        from: RequestWithPrefix(),
        baseURL: "https://api.example.com"
    )

    #expect(url.absoluteString == "https://api.example.com/api/v1/users")
}

@Test("URLBuilder substitutes single path parameter")
func testURLBuilderSinglePathParameter() throws {
    let builder = URLBuilder()

    struct RequestWithParam: NetworkRequest {
        typealias Response = String
        let userId: String
        var path: String { "/users/{userId}" }
        var method: HTTPMethod { .get }
        var pathParameters: [String: String]? { ["userId": userId] }
    }

    let url = try builder.buildURL(
        from: RequestWithParam(userId: "123"),
        baseURL: "https://api.example.com"
    )

    #expect(url.absoluteString == "https://api.example.com/users/123")
}

@Test("URLBuilder substitutes multiple path parameters")
func testURLBuilderMultiplePathParameters() throws {
    let builder = URLBuilder()

    struct RequestWithMultipleParams: NetworkRequest {
        typealias Response = String
        let userId: String
        let postId: String
        var path: String { "/users/{userId}/posts/{postId}" }
        var method: HTTPMethod { .get }
        var pathParameters: [String: String]? {
            ["userId": userId, "postId": postId]
        }
    }

    let url = try builder.buildURL(
        from: RequestWithMultipleParams(userId: "123", postId: "456"),
        baseURL: "https://api.example.com"
    )

    #expect(url.absoluteString == "https://api.example.com/users/123/posts/456")
}

@Test("URLBuilder handles path prefix with path parameters")
func testURLBuilderPrefixWithParameters() throws {
    let builder = URLBuilder()

    struct ComplexRequest: NetworkRequest {
        typealias Response = String
        let userId: String
        var pathPrefix: String? { "/api/v2" }
        var path: String { "/users/{userId}" }
        var method: HTTPMethod { .get }
        var pathParameters: [String: String]? { ["userId": userId] }
    }

    let url = try builder.buildURL(
        from: ComplexRequest(userId: "789"),
        baseURL: "https://api.example.com"
    )

    #expect(url.absoluteString == "https://api.example.com/api/v2/users/789")
}

@Test("URLBuilder throws URLBuildError.invalidURL for malformed URL")
func testURLBuilderInvalidURL() throws {
    let builder = URLBuilder()

    struct InvalidURLRequest: NetworkRequest {
        typealias Response = String
        var path: String { "/users" }
        var method: HTTPMethod { .get }
    }

    #expect(throws: URLBuildError.self) {
        _ = try builder.buildURL(
            from: InvalidURLRequest(),
            baseURL: "ht!tp://inv@lid url with spaces and symbols"
        )
    }
}

@Test("URLBuilder URLBuildError has correct error description")
func testURLBuildErrorDescription() {
    let error = URLBuildError.invalidURL("http://bad url")
    #expect(error.errorDescription == "Invalid URL: http://bad url")
}

@Test("URLBuilder throws missingBaseURL when neither client nor request provides it")
func testURLBuilderMissingBaseURL() throws {
    let builder = URLBuilder()

    struct RequestWithoutBaseURL: NetworkRequest {
        typealias Response = String
        var path: String { "/users" }
        var method: HTTPMethod { .get }
    }

    do {
        _ = try builder.buildURL(
            from: RequestWithoutBaseURL(),
            baseURL: nil
        )
        Issue.record("Expected URLBuildError.missingBaseURL to be thrown")
    } catch let error as URLBuildError {
        if case .missingBaseURL = error {
            #expect(error.errorDescription == "Base URL is required but not provided")
            #expect(error.recoverySuggestion ==
                "Provide baseURL either in NetworkClient configuration or in the request")
        } else {
            Issue.record("Expected missingBaseURL error, got \(error)")
        }
    }
}

@Test("URLBuilder handles empty path parameters gracefully")
func testURLBuilderEmptyPathParameters() throws {
    let builder = URLBuilder()

    struct RequestWithEmptyParams: NetworkRequest {
        typealias Response = String
        var path: String { "/users" }
        var method: HTTPMethod { .get }
        var pathParameters: [String: String]? { [:] }
    }

    let url = try builder.buildURL(
        from: RequestWithEmptyParams(),
        baseURL: "https://api.example.com"
    )

    #expect(url.absoluteString == "https://api.example.com/users")
}

@Test("URLBuilder handles path with trailing slash")
func testURLBuilderTrailingSlash() throws {
    let builder = URLBuilder()

    struct RequestWithTrailingSlash: NetworkRequest {
        typealias Response = String
        var path: String { "/users/" }
        var method: HTTPMethod { .get }
    }

    let url = try builder.buildURL(
        from: RequestWithTrailingSlash(),
        baseURL: "https://api.example.com"
    )

    #expect(url.absoluteString == "https://api.example.com/users/")
}

@Test("URLBuilder substitutes same parameter multiple times")
func testURLBuilderRepeatedParameter() throws {
    let builder = URLBuilder()

    struct RequestWithRepeatedParam: NetworkRequest {
        typealias Response = String
        let id: String
        var path: String { "/compare/{id}/with/{id}" }
        var method: HTTPMethod { .get }
        var pathParameters: [String: String]? { ["id": id] }
    }

    let url = try builder.buildURL(
        from: RequestWithRepeatedParam(id: "123"),
        baseURL: "https://api.example.com"
    )

    #expect(url.absoluteString == "https://api.example.com/compare/123/with/123")
}
