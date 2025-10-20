// MockResponseBuilder.swift
// ASC Tests
//
// DSL for building mock HTTP responses in tests.

@testable import ASC
import Foundation

/// Builder for creating mock HTTP responses with a fluent API.
///
/// Provides a clean DSL for configuring mock responses in tests.
///
/// Example:
/// ```swift
/// MockResponse.success(user)
///     .statusCode(200)
///     .build()
///
/// MockResponse.error("Not Found")
///     .statusCode(404)
///     .build()
/// ```
public struct MockResponseBuilder {
    // MARK: - Properties

    private let data: Data?
    private let statusCode: Int
    private let headers: [String: String]
    private let delayInterval: TimeInterval

    // MARK: - Initialization

    private init(data: Data?, statusCode: Int, headers: [String: String] = [:], delay: TimeInterval = 0) {
        self.data = data
        self.statusCode = statusCode
        self.headers = headers
        self.delayInterval = delay
    }

    // MARK: - Factory Methods

    /// Creates a successful response with a Codable model.
    ///
    /// - Parameter model: Codable model to encode as JSON
    /// - Returns: MockResponseBuilder instance
    public static func success<T: Encodable>(_ model: T) -> MockResponseBuilder {
        let encoder = JSONEncoder()
        let data = try? encoder.encode(model)
        return MockResponseBuilder(data: data, statusCode: 200)
    }

    /// Creates a successful response with multiple models.
    ///
    /// - Parameter models: Array of Codable models to encode as JSON
    /// - Returns: MockResponseBuilder instance
    public static func success<T: Encodable>(_ models: [T]) -> MockResponseBuilder {
        let encoder = JSONEncoder()
        let data = try? encoder.encode(models)
        return MockResponseBuilder(data: data, statusCode: 200)
    }

    /// Creates an empty success response (204 No Content).
    ///
    /// - Returns: MockResponseBuilder instance
    public static func emptySuccess() -> MockResponseBuilder {
        MockResponseBuilder(data: nil, statusCode: 204)
    }

    /// Creates an error response with a message.
    ///
    /// - Parameters:
    ///   - message: Error message
    ///   - code: HTTP status code (default: 400)
    /// - Returns: MockResponseBuilder instance
    public static func error(_ message: String, code: Int = 400) -> MockResponseBuilder {
        let errorDict: [String: Any] = [
            "error": "Error",
            "message": message,
            "code": code
        ]
        let data = try? JSONSerialization.data(withJSONObject: errorDict)
        return MockResponseBuilder(data: data, statusCode: code)
    }

    /// Creates a client error response (4xx).
    ///
    /// - Parameter code: HTTP status code (400-499)
    /// - Returns: MockResponseBuilder instance
    public static func clientError(_ code: Int) -> MockResponseBuilder {
        let message = HTTPURLResponse.localizedString(forStatusCode: code)
        return error(message, code: code)
    }

    /// Creates a server error response (5xx).
    ///
    /// - Parameter code: HTTP status code (500-599)
    /// - Returns: MockResponseBuilder instance
    public static func serverError(_ code: Int = 500) -> MockResponseBuilder {
        let message = HTTPURLResponse.localizedString(forStatusCode: code)
        return error(message, code: code)
    }

    /// Creates an unauthorized error response (401).
    ///
    /// - Returns: MockResponseBuilder instance
    public static func unauthorized() -> MockResponseBuilder {
        error("Unauthorized", code: 401)
    }

    /// Creates a forbidden error response (403).
    ///
    /// - Returns: MockResponseBuilder instance
    public static func forbidden() -> MockResponseBuilder {
        error("Forbidden", code: 403)
    }

    /// Creates a not found error response (404).
    ///
    /// - Returns: MockResponseBuilder instance
    public static func notFound() -> MockResponseBuilder {
        error("Not Found", code: 404)
    }

    /// Creates a response with invalid JSON data.
    ///
    /// - Returns: MockResponseBuilder instance
    public static func invalidJSON() -> MockResponseBuilder {
        let invalidData = Data("{ invalid json }".utf8)
        return MockResponseBuilder(data: invalidData, statusCode: 200)
    }

    /// Creates a response with custom data.
    ///
    /// - Parameters:
    ///   - data: Response data
    ///   - statusCode: HTTP status code (default: 200)
    /// - Returns: MockResponseBuilder instance
    public static func custom(data: Data?, statusCode: Int = 200) -> MockResponseBuilder {
        MockResponseBuilder(data: data, statusCode: statusCode)
    }

    // MARK: - Builder Methods

    /// Sets the HTTP status code.
    ///
    /// - Parameter code: HTTP status code
    /// - Returns: Updated MockResponseBuilder
    public func statusCode(_ code: Int) -> MockResponseBuilder {
        MockResponseBuilder(data: data, statusCode: code, headers: headers, delay: delayInterval)
    }

    /// Adds a header to the response.
    ///
    /// - Parameters:
    ///   - name: Header name
    ///   - value: Header value
    /// - Returns: Updated MockResponseBuilder
    public func header(_ name: String, _ value: String) -> MockResponseBuilder {
        var newHeaders = headers
        newHeaders[name] = value
        return MockResponseBuilder(data: data, statusCode: statusCode, headers: newHeaders, delay: delayInterval)
    }

    /// Adds multiple headers to the response.
    ///
    /// - Parameter headers: Dictionary of header name-value pairs
    /// - Returns: Updated MockResponseBuilder
    public func headers(_ headers: [String: String]) -> MockResponseBuilder {
        var newHeaders = self.headers
        for (key, value) in headers {
            newHeaders[key] = value
        }
        return MockResponseBuilder(data: data, statusCode: statusCode, headers: newHeaders, delay: delayInterval)
    }

    /// Sets a delay before the response is returned.
    ///
    /// Useful for testing timeout and cancellation behavior.
    ///
    /// - Parameter interval: Delay in seconds
    /// - Returns: Updated MockResponseBuilder
    public func delay(_ interval: TimeInterval) -> MockResponseBuilder {
        MockResponseBuilder(data: data, statusCode: statusCode, headers: headers, delay: interval)
    }

    // MARK: - Build

    /// Builds the final mock response.
    ///
    /// - Parameter url: URL for the response
    /// - Returns: Tuple of HTTPURLResponse and Data
    /// - Throws: Error if URL is invalid
    public func build(url: URL) throws -> (HTTPURLResponse, Data?) {
        guard let response = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: headers
        ) else {
            throw NSError(
                domain: "MockResponseBuilder",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to create HTTPURLResponse"]
            )
        }

        return (response, data)
    }
}

// MARK: - Convenience Extensions

extension MockResponseBuilder {
    /// Creates a mock handler for MockURLProtocol.
    ///
    /// - Returns: Request handler closure
    public func handler() -> (URLRequest) throws -> (HTTPURLResponse, Data?) {
        { request in
            if self.delayInterval > 0 {
                Thread.sleep(forTimeInterval: self.delayInterval)
            }
            return try self.build(url: request.url!)
        }
    }
}

// MARK: - TestUser Factory Extension

extension MockResponseBuilder {
    /// Creates a success response with a default TestUser.
    ///
    /// - Parameters:
    ///   - id: User ID (default: from TestRequestFactory)
    ///   - name: User name (default: from TestRequestFactory)
    ///   - email: User email (optional)
    /// - Returns: MockResponseBuilder instance
    public static func user(
        id: String = TestRequestFactory.defaultUserId,
        name: String = TestRequestFactory.defaultUserName,
        email: String? = TestRequestFactory.defaultEmail
    ) -> MockResponseBuilder {
        let user = TestUser(id: id, name: name, email: email)
        return success(user)
    }

    /// Creates a success response with a default TestPost.
    ///
    /// - Parameters:
    ///   - id: Post ID (default: "post-123")
    ///   - title: Post title (default: from TestRequestFactory)
    ///   - content: Post content (default: from TestRequestFactory)
    ///   - authorId: Author ID (default: from TestRequestFactory)
    /// - Returns: MockResponseBuilder instance
    public static func post(
        id: String = "post-123",
        title: String = TestRequestFactory.defaultPostTitle,
        content: String = TestRequestFactory.defaultPostContent,
        authorId: String = TestRequestFactory.defaultUserId
    ) -> MockResponseBuilder {
        let post = TestPost(id: id, title: title, content: content, authorId: authorId)
        return success(post)
    }
}
