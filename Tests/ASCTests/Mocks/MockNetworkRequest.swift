// MockNetworkRequest.swift
// ASC - Alamofire Swift Client

// Mock network requests for testing.

import Foundation
@testable import ASC

// MARK: - Mock Response Types

/// Simple mock response for testing
struct MockResponse: Codable, Sendable, Equatable {
    let id: Int
    let name: String
}

// MARK: - Mock Requests

/// Basic mock GET request
struct MockGetRequest: NetworkRequest {
    typealias Response = MockResponse

    var baseURL: String?
    var path: String
    var method: HTTPMethod { .get }
    var headers: HTTPHeaders?
    var parameters: Parameters?
    var timeout: TimeInterval?
    var retryPolicy: Alamofire.RetryPolicy?

    init(
        path: String = "/test",
        baseURL: String? = nil,
        headers: HTTPHeaders? = nil,
        parameters: Parameters? = nil,
        timeout: TimeInterval? = nil,
        retryPolicy: Alamofire.RetryPolicy? = nil
    ) {
        self.path = path
        self.baseURL = baseURL
        self.headers = headers
        self.parameters = parameters
        self.timeout = timeout
        self.retryPolicy = retryPolicy
    }
}

/// Mock POST request with body
struct MockPostRequest: NetworkRequest {
    typealias Response = MockResponse

    struct Body: Codable, Sendable {
        let name: String
        let value: Int
    }

    var baseURL: String?
    var path: String
    var method: HTTPMethod { .post }
    var headers: HTTPHeaders?
    var parameters: Body?
    var timeout: TimeInterval?

    init(
        path: String = "/test",
        baseURL: String? = nil,
        headers: HTTPHeaders? = nil,
        parameters: Body? = nil,
        timeout: TimeInterval? = nil
    ) {
        self.path = path
        self.baseURL = baseURL
        self.headers = headers
        self.parameters = parameters
        self.timeout = timeout
    }
}

/// Mock request that requires authentication
struct MockAuthenticatedRequest: NetworkRequest {
    typealias Response = MockResponse

    var baseURL: String?
    var path: String
    var method: HTTPMethod { .get }
    var isAuthorized: Bool { true }

    init(path: String = "/secure", baseURL: String? = nil) {
        self.path = path
        self.baseURL = baseURL
    }
}

/// Mock request with empty response
struct MockEmptyRequest: NetworkRequest {
    typealias Response = ASCEmptyResponse

    var baseURL: String?
    var path: String
    var method: HTTPMethod { .delete }

    init(path: String = "/test", baseURL: String? = nil) {
        self.path = path
        self.baseURL = baseURL
    }
}

/// Mock request with custom validation
struct MockValidatedRequest: NetworkRequest {
    typealias Response = MockResponse

    var baseURL: String?
    var path: String
    var method: HTTPMethod { .get }
    var shouldFailValidation: Bool

    init(
        path: String = "/test",
        baseURL: String? = nil,
        shouldFailValidation: Bool = false
    ) {
        self.path = path
        self.baseURL = baseURL
        self.shouldFailValidation = shouldFailValidation
    }

    func validate(response: MockResponse) throws {
        if shouldFailValidation {
            throw ASCError.validationFailed("Custom validation failed")
        }
    }
}

/// Mock request with custom parameter encoder
struct MockCustomEncodedRequest: NetworkRequest {
    typealias Response = MockResponse

    struct Params: Encodable, Sendable {
        let key: String
    }

    var baseURL: String?
    var path: String
    var method: HTTPMethod { .post }
    var parameters: Params?
    var parameterEncoder: ParameterEncoder?

    init(
        path: String = "/test",
        baseURL: String? = nil,
        parameters: Params? = nil,
        encoder: ParameterEncoder? = nil
    ) {
        self.path = path
        self.baseURL = baseURL
        self.parameters = parameters
        self.parameterEncoder = encoder
    }
}
