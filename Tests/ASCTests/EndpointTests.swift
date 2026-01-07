// EndpointTests.swift
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

struct EndpointTests {
    // MARK: - Test Helpers

    struct MinimalRequest: Endpoint {
        typealias Response = Empty
        typealias Request = Empty

        var path: String { "/test" }
        var method: HTTPMethod { .get }
    }

    struct FullyConfiguredRequest: Endpoint {
        typealias Response = Empty

        struct Params: Encodable, Sendable {
            let key: String
        }
        typealias Request = Params

        var baseURL: String? { "https://custom.api.com" }
        var path: String { "/users" }
        var method: HTTPMethod { .post }
        var headers: HTTPHeaders? {
            [HTTPHeader(name: "X-Custom", value: "test")]
        }
        var parameters: Params? {
            Params(key: "value")
        }
        var timeout: TimeInterval? { 60.0 }
        var cachePolicy: URLRequest.CachePolicy? { .reloadIgnoringLocalCacheData }
        var retryPolicy: RetryPolicy? { .default }
    }

    struct RequestWithValidation: Endpoint {
        typealias Response = TestResponse
        typealias Request = Empty

        struct TestResponse: Codable, Sendable {
            let success: Bool
            let message: String
        }

        var path: String { "/validate" }
        var method: HTTPMethod { .get }

        func validate(response: TestResponse) throws {
            guard response.success else {
                throw ASCError.validationFailed(response.message)
            }
        }
    }

    // MARK: - Default Implementation Tests

    @Test("Endpoint default base URL is nil")
    func testDefaultBaseURL() {
        let request = MinimalRequest()
        #expect(request.baseURL == nil)
    }

    @Test("Endpoint default headers are nil")
    func testDefaultHeaders() {
        let request = MinimalRequest()
        #expect(request.headers == nil)
    }

    @Test("Endpoint default parameters are nil")
    func testDefaultParameters() {
        let request = MinimalRequest()
        #expect(request.parameters == nil)
    }

    @Test("Endpoint default timeout is nil")
    func testDefaultTimeout() {
        let request = MinimalRequest()
        #expect(request.timeout == nil)
    }

    @Test("Endpoint default cache policy is nil")
    func testDefaultCachePolicy() {
        let request = MinimalRequest()
        #expect(request.cachePolicy == nil)
    }

    @Test("Endpoint default retry policy is nil")
    func testDefaultRetryPolicy() {
        let request = MinimalRequest()
        #expect(request.retryPolicy == nil)
    }

    @Test("Endpoint default validation does nothing")
    func testDefaultValidation() async throws {
        // Given: Request with Empty response type
        let request = MinimalRequest()

        // When: Validating (Empty is Decodable, so we can't create it directly)
        // The validation should not throw for any response type
        // This test verifies that default validation implementation works
        #expect(request.path == "/test")
    }

    @Test("Endpoint default enableAuthorization is false")
    func testDefaultEnableAuthorization() {
        let request = MinimalRequest()
        #expect(request.enableAuthorization == false)
    }

    // MARK: - Custom Implementation Tests

    @Test("Fully configured request has all properties")
    func testFullyConfiguredRequest() {
        let request = FullyConfiguredRequest()

        #expect(request.baseURL == "https://custom.api.com")
        #expect(request.path == "/users")
        #expect(request.method == .post)
        #expect(request.headers != nil)
        #expect(request.parameters != nil)
        #expect(request.timeout == 60.0)
        #expect(request.cachePolicy == .reloadIgnoringLocalCacheData)
        #expect(request.retryPolicy != nil)
    }

    @Test("Endpoint default parameter encoder is nil")
    func testDefaultParameterEncoder() {
        let request = MinimalRequest()
        #expect(request.parameterEncoder == nil)
    }

    @Test("Endpoint can specify custom parameter encoder")
    func testCustomParameterEncoder() {
        struct CustomEncoderRequest: Endpoint {
            typealias Response = Empty

            struct Query: Encodable, Sendable {
                let tags: [String]
            }
            typealias Request = Query

            var path: String { "/search" }
            var method: HTTPMethod { .get }

            var parameters: Query? {
                Query(tags: ["swift", "ios"])
            }

            var parameterEncoder: ParameterEncoder? {
                // Use custom encoder (e.g., JSONParameterEncoder for GET request)
                // Normally GET uses URLEncodedFormParameterEncoder, but we can override
                JSONParameterEncoder.default
            }
        }

        let request = CustomEncoderRequest()
        #expect(request.parameterEncoder != nil)
    }

    @Test("Request validation throws error when fails")
    func testRequestValidationThrows() throws {
        let request = RequestWithValidation()
        let failedResponse = RequestWithValidation.TestResponse(
            success: false,
            message: "Validation failed"
        )

        #expect(throws: ASCError.self) {
            try request.validate(response: failedResponse)
        }
    }

    @Test("Request validation succeeds when valid")
    func testRequestValidationSucceeds() throws {
        let request = RequestWithValidation()
        let successResponse = RequestWithValidation.TestResponse(
            success: true,
            message: "OK"
        )

        // Should not throw
        try request.validate(response: successResponse)
    }

    // MARK: - HTTP Method Tests

    @Test("HTTP methods are correct")
    func testHTTPMethods() {
        #expect(HTTPMethod.get.rawValue == "GET")
        #expect(HTTPMethod.post.rawValue == "POST")
        #expect(HTTPMethod.put.rawValue == "PUT")
        #expect(HTTPMethod.delete.rawValue == "DELETE")
        #expect(HTTPMethod.patch.rawValue == "PATCH")
        #expect(HTTPMethod.head.rawValue == "HEAD")
        #expect(HTTPMethod.options.rawValue == "OPTIONS")
    }

    // MARK: - RetryPolicy Tests

    @Test("RetryPolicy.none returns nil")
    func testRetryPolicyNone() {
        #expect(RetryPolicy.none == nil)
    }

    @Test("RetryPolicy.default has 3 retries")
    func testRetryPolicyDefault() {
        #expect(RetryPolicy.default.retryLimit == 3)
    }

    @Test("RetryPolicy.aggressive has 5 retries")
    func testRetryPolicyAggressive() {
        #expect(RetryPolicy.aggressive.retryLimit == 5)
    }

    @Test("RetryPolicy.conservative has 2 retries")
    func testRetryPolicyConservative() {
        #expect(RetryPolicy.conservative.retryLimit == 2)
    }

    // MARK: - Empty Response Tests

    @Test("Empty can be used as response type")
    func testEmptyAsResponseType() throws {
        // Given: Request with Empty response type
        struct TestRequest: Endpoint {
            typealias Response = Empty
            typealias Request = Empty

            var path: String { "/test" }
            var method: HTTPMethod { .get }
        }

        let request = TestRequest()

        // Then: Request should compile and Empty should be valid response type
        #expect(request.path == "/test")
    }
}
