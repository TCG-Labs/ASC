// NetworkRequestTests.swift
// ASC - Alamofire Swift Client Tests

import Testing
import Foundation
@testable import ASC

struct NetworkRequestTests {
    // MARK: - Test Helpers

    struct MinimalRequest: NetworkRequest {
        typealias Response = EmptyResponse
        typealias Parameters = EmptyParameters

        var path: String { "/test" }
        var method: HTTPMethod { .get }
    }

    struct FullyConfiguredRequest: NetworkRequest {
        typealias Response = EmptyResponse

        struct Params: Encodable, Sendable {
            let key: String
        }
        typealias Parameters = Params

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

    struct RequestWithValidation: NetworkRequest {
        typealias Response = TestResponse
        typealias Parameters = EmptyParameters

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

    @Test("NetworkRequest default base URL is nil")
    func testDefaultBaseURL() {
        let request = MinimalRequest()
        #expect(request.baseURL == nil)
    }

    @Test("NetworkRequest default headers are nil")
    func testDefaultHeaders() {
        let request = MinimalRequest()
        #expect(request.headers == nil)
    }

    @Test("NetworkRequest default parameters are nil")
    func testDefaultParameters() {
        let request = MinimalRequest()
        #expect(request.parameters == nil)
    }

    @Test("NetworkRequest default timeout is nil")
    func testDefaultTimeout() {
        let request = MinimalRequest()
        #expect(request.timeout == nil)
    }

    @Test("NetworkRequest default cache policy is nil")
    func testDefaultCachePolicy() {
        let request = MinimalRequest()
        #expect(request.cachePolicy == nil)
    }

    @Test("NetworkRequest default retry policy is nil")
    func testDefaultRetryPolicy() {
        let request = MinimalRequest()
        #expect(request.retryPolicy == nil)
    }

    @Test("NetworkRequest default validation does nothing")
    func testDefaultValidation() throws {
        let request = MinimalRequest()
        let response = ASCEmptyResponse()

        // Should not throw
        try request.validate(response: response)
    }

    @Test("NetworkRequest default isAuthorized is false")
    func testDefaultIsAuthorized() {
        let request = MinimalRequest()
        #expect(request.isAuthorized == false)
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

    @Test("NetworkRequest default parameter encoder is nil")
    func testDefaultParameterEncoder() {
        let request = MinimalRequest()
        #expect(request.parameterEncoder == nil)
    }

    @Test("NetworkRequest can specify custom parameter encoder")
    func testCustomParameterEncoder() {
        struct CustomEncoderRequest: NetworkRequest {
            typealias Response = EmptyResponse

            struct Query: Encodable, Sendable {
                let tags: [String]
            }
            typealias Parameters = Query

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

    // MARK: - EmptyResponse Tests

    @Test("EmptyResponse can be created")
    func testEmptyResponse() {
        let response = ASCEmptyResponse()
        // Successfully created
        #expect(true)
    }

    @Test("EmptyResponse is Codable")
    func testEmptyResponseCodable() throws {
        let response = ASCEmptyResponse()
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(response)
        let decoded = try decoder.decode(ASCEmptyResponse.self, from: data)

        // Successfully decoded
        #expect(true)
    }

    @Test("EmptyResponse type alias works")
    func testEmptyResponseTypeAlias() {
        let _: ASCEmptyResponse = .init()
        let _: EmptyResponse = .init()

        // Type aliases work
        #expect(true)
    }
}
