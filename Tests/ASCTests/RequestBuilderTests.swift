// RequestBuilderTests.swift
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

struct RequestBuilderTests {
    // MARK: - Test Helpers

    struct TestRequest: NetworkRequest {
        typealias Response = EmptyResponse
        typealias Parameters = EmptyParameters

        var baseURL: String?
        var path: String
        var method: HTTPMethod { .get }
    }

    private func makeBuilder() -> RequestBuilder {
        RequestBuilder(
            baseURL: nil,
            defaultHeaders: HTTPHeaders(),
            defaultTimeout: 30.0,
            defaultCachePolicy: .useProtocolCachePolicy,
            defaultDecoder: JSONDecoder()
        )
    }

    // MARK: - URL Building Tests

    @Test("Build URL with base URL from configuration")
    func testBuildURLWithConfigBaseURL() throws {
        let builder = RequestBuilder(
            baseURL: "https://api.example.com",
            defaultHeaders: HTTPHeaders(),
            defaultTimeout: 30.0,
            defaultCachePolicy: .useProtocolCachePolicy,
            defaultDecoder: JSONDecoder()
        )
        let request = TestRequest(baseURL: nil, path: "/users")
        let urlRequest = try builder.buildURLRequest(from: request)

        #expect(urlRequest.url?.absoluteString == "https://api.example.com/users")
    }

    @Test("Build URL with base URL from request")
    func testBuildURLWithRequestBaseURL() throws {
        let builder = makeBuilder()
        let request = TestRequest(baseURL: "https://custom.api.com", path: "/data")
        let urlRequest = try builder.buildURLRequest(from: request)

        #expect(urlRequest.url?.absoluteString == "https://custom.api.com/data")
    }

    @Test("Build URL with query parameters in path")
    func testBuildURLWithQueryParams() throws {
        let builder = RequestBuilder(
            baseURL: "https://api.example.com",
            defaultHeaders: HTTPHeaders(),
            defaultTimeout: 30.0,
            defaultCachePolicy: .useProtocolCachePolicy,
            defaultDecoder: JSONDecoder()
        )
        let request = TestRequest(baseURL: nil, path: "/search?q=swift&page=1")
        let urlRequest = try builder.buildURLRequest(from: request)

        #expect(urlRequest.url?.absoluteString == "https://api.example.com/search?q=swift&page=1")
    }

    @Test("Throw error when base URL is missing")
    func testThrowErrorWhenBaseURLMissing() {
        let builder = makeBuilder()
        let request = TestRequest(baseURL: nil, path: "/users")

        #expect(throws: RequestBuildError.self) {
            _ = try builder.buildURLRequest(from: request)
        }
    }

    @Test("Build URL with special characters")
    func testBuildURLWithSpecialCharacters() throws {
        let builder = RequestBuilder(
            baseURL: "https://api.example.com",
            defaultHeaders: HTTPHeaders(),
            defaultTimeout: 30.0,
            defaultCachePolicy: .useProtocolCachePolicy,
            defaultDecoder: JSONDecoder()
        )
        let request = TestRequest(baseURL: nil, path: "/users/john@example.com")
        let urlRequest = try builder.buildURLRequest(from: request)

        #expect(urlRequest.url?.absoluteString.contains("/users/john@example.com") == true)
    }

    @Test("Build URL with HTTPS scheme")
    func testBuildURLWithHTTPS() throws {
        let builder = makeBuilder()
        let request = TestRequest(baseURL: "https://secure.api.com", path: "/data")
        let urlRequest = try builder.buildURLRequest(from: request)

        #expect(urlRequest.url?.scheme == "https")
    }

    @Test("Build URL with HTTP scheme")
    func testBuildURLWithHTTP() throws {
        let builder = makeBuilder()
        let request = TestRequest(baseURL: "http://localhost:8080", path: "/test")
        let urlRequest = try builder.buildURLRequest(from: request)

        #expect(urlRequest.url?.scheme == "http")
        #expect(urlRequest.url?.host == "localhost")
        #expect(urlRequest.url?.port == 8080)
    }

    // MARK: - Request Building Tests

    @Test("Request has correct HTTP method")
    func testRequestHasCorrectHTTPMethod() throws {
        struct PostRequest: NetworkRequest {
            typealias Response = EmptyResponse
            typealias Parameters = EmptyParameters

            var baseURL: String? { "https://api.example.com" }
            var path: String { "/posts" }
            var method: HTTPMethod { .post }
        }

        let builder = makeBuilder()
        let request = PostRequest()
        let urlRequest = try builder.buildURLRequest(from: request)

        #expect(urlRequest.httpMethod == "POST")
    }

    @Test("Request uses default timeout")
    func testRequestUsesDefaultTimeout() throws {
        let builder = RequestBuilder(
            baseURL: "https://api.example.com",
            defaultHeaders: HTTPHeaders(),
            defaultTimeout: 60.0,
            defaultCachePolicy: .useProtocolCachePolicy,
            defaultDecoder: JSONDecoder()
        )
        let request = TestRequest(baseURL: nil, path: "/test")
        let urlRequest = try builder.buildURLRequest(from: request)

        #expect(urlRequest.timeoutInterval == 60.0)
    }

    @Test("Request uses default cache policy")
    func testRequestUsesDefaultCachePolicy() throws {
        let builder = RequestBuilder(
            baseURL: "https://api.example.com",
            defaultHeaders: HTTPHeaders(),
            defaultTimeout: 30.0,
            defaultCachePolicy: .reloadIgnoringLocalCacheData,
            defaultDecoder: JSONDecoder()
        )
        let request = TestRequest(baseURL: nil, path: "/test")
        let urlRequest = try builder.buildURLRequest(from: request)

        #expect(urlRequest.cachePolicy == .reloadIgnoringLocalCacheData)
    }
}

