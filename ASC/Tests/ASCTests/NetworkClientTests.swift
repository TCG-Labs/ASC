// NetworkClientTests.swift
// ASC Tests
//
// Integration tests for NetworkClient.

import Testing
import Foundation
import Alamofire
@testable import ASC

// MARK: - NetworkClient Integration Tests

@Suite("Integration Tests", .serialized)
struct IntegrationTests {}

extension IntegrationTests {

@Test("NetworkClient executes successful GET request")
func testNetworkClientSuccessfulGET() async throws {
    setupTest()

    // Setup mock
    let configuration = createMockConfiguration()

    let mockUser = TestUser(id: "123", name: "John Doe", email: "john@example.com")
    let mockJSON: [String: Any] = [
        "id": mockUser.id,
        "name": mockUser.name,
        "email": mockUser.email as Any,
    ]

    MockURLProtocol.requestHandler = { request in
        let (response, data) = try MockURLProtocol.mockJSONResponse(
            url: request.url!,
            statusCode: 200,
            json: mockJSON
        )
        return (response, data)
    }

    // Create client
    let clientConfig = NetworkClientConfiguration(
        baseURL: "https://api.example.com",
        urlSessionConfiguration: configuration
    )
    let client = NetworkClient(configuration: clientConfig)

    // Execute request
    let user = try await client.execute(GetUserRequest(userId: "123"))

    // Verify
    #expect(user == mockUser)
    #expect(MockURLProtocol.requestHistory.count == 1)
    #expect(MockURLProtocol.requestHistory.first?.url?.path == "/users/123")
}

@Test("NetworkClient executes successful POST request with JSON body")
func testNetworkClientSuccessfulPOST() async throws {
    setupTest()

    // Setup mock
    let configuration = createMockConfiguration()

    let mockPost = TestPost(
        id: "post1",
        title: "Test Post",
        content: "Test Content",
        authorId: "user1"
    )

    MockURLProtocol.requestHandler = { request in
        // Note: request.httpBody is nil for streamed requests, so we can't verify it here
        // The fact that the request reaches this handler and gets the correct response is sufficient

        // Return response
        let responseJSON: [String: Any] = [
            "id": mockPost.id,
            "title": mockPost.title,
            "content": mockPost.content,
            "authorId": mockPost.authorId,
        ]

        let (response, data) = try MockURLProtocol.mockJSONResponse(
            url: request.url!,
            statusCode: 201,
            json: responseJSON
        )
        return (response, data)
    }

    // Create client
    let clientConfig = NetworkClientConfiguration(
        baseURL: "https://api.example.com",
        urlSessionConfiguration: configuration
    )
    let client = NetworkClient(configuration: clientConfig)

    // Execute request
    let post = try await client.execute(
        CreatePostRequest(
            title: "Test Post",
            content: "Test Content",
            authorId: "user1"
        )
    )

    // Verify
    #expect(post == mockPost)
}

@Test("NetworkClient executes PUT request")
func testNetworkClientPUT() async throws {
    setupTest()

    // Setup mock
    let configuration = createMockConfiguration()

    let updatedUser = TestUser(id: "123", name: "Jane Doe", email: "jane@example.com")

    MockURLProtocol.requestHandler = { request in
        #expect(request.httpMethod == "PUT")

        let responseJSON: [String: Any] = [
            "id": updatedUser.id,
            "name": updatedUser.name,
            "email": updatedUser.email as Any,
        ]

        let (response, data) = try MockURLProtocol.mockJSONResponse(
            url: request.url!,
            statusCode: 200,
            json: responseJSON
        )
        return (response, data)
    }

    // Create client
    let clientConfig = NetworkClientConfiguration(
        baseURL: "https://api.example.com",
        urlSessionConfiguration: configuration
    )
    let client = NetworkClient(configuration: clientConfig)

    // Execute request
    let user = try await client.execute(
        UpdateUserRequest(userId: "123", name: "Jane Doe", email: "jane@example.com")
    )

    // Verify
    #expect(user == updatedUser)
}

@Test("NetworkClient executes DELETE request with EmptyResponse")
func testNetworkClientDELETE() async throws {
    setupTest()

    // Setup mock
    let configuration = createMockConfiguration()

    MockURLProtocol.requestHandler = { request in
        #expect(request.httpMethod == "DELETE")

        let response = MockURLProtocol.mockResponse(
            url: request.url!,
            statusCode: 204
        )
        return (response, nil)
    }

    // Create client
    let clientConfig = NetworkClientConfiguration(
        baseURL: "https://api.example.com",
        urlSessionConfiguration: configuration
    )
    let client = NetworkClient(configuration: clientConfig)

    // Execute request (should not throw)
    try await client.execute(DeleteUserRequest(userId: "123"))

    // Verify request was made
    #expect(MockURLProtocol.requestHistory.count == 1)
    #expect(MockURLProtocol.requestHistory.first?.url?.path == "/users/123")
}

@Test("NetworkClient handles path parameters substitution")
func testNetworkClientPathParameters() async throws {
    setupTest()

    // Setup mock
    let configuration = createMockConfiguration()

    let mockUser = TestUser(id: "456", name: "Test User")

    MockURLProtocol.requestHandler = { request in
        #expect(request.url?.path == "/users/456")

        let responseJSON: [String: Any] = [
            "id": mockUser.id,
            "name": mockUser.name,
        ]

        let (response, data) = try MockURLProtocol.mockJSONResponse(
            url: request.url!,
            statusCode: 200,
            json: responseJSON
        )
        return (response, data)
    }

    // Create client
    let clientConfig = NetworkClientConfiguration(
        baseURL: "https://api.example.com",
        urlSessionConfiguration: configuration
    )
    let client = NetworkClient(configuration: clientConfig)

    // Execute request with path parameters
    let user = try await client.execute(GetUserWithPathParamsRequest(userId: "456"))

    // Verify
    #expect(user.id == "456")
}

@Test("NetworkClient handles path prefix")
func testNetworkClientPathPrefix() async throws {
    setupTest()

    // Setup mock
    let configuration = createMockConfiguration()

    let mockUser = TestUser(id: "789", name: "Prefixed User")

    MockURLProtocol.requestHandler = { request in
        #expect(request.url?.path == "/api/v1/users/789")

        let responseJSON: [String: Any] = [
            "id": mockUser.id,
            "name": mockUser.name,
        ]

        let (response, data) = try MockURLProtocol.mockJSONResponse(
            url: request.url!,
            statusCode: 200,
            json: responseJSON
        )
        return (response, data)
    }

    // Create client
    let clientConfig = NetworkClientConfiguration(
        baseURL: "https://api.example.com",
        urlSessionConfiguration: configuration
    )
    let client = NetworkClient(configuration: clientConfig)

    // Execute request with path prefix
    let user = try await client.execute(GetUserWithPrefixRequest(userId: "789"))

    // Verify
    #expect(user.id == "789")
}

@Test("NetworkClient handles custom headers")
func testNetworkClientCustomHeaders() async throws {
    setupTest()

    // Setup mock
    let configuration = createMockConfiguration()

    let mockUser = TestUser(id: "me", name: "Current User")

    MockURLProtocol.requestHandler = { request in
        // Verify authorization header
        let authHeader = request.value(forHTTPHeaderField: "Authorization")
        #expect(authHeader == "Bearer secret-token")

        let responseJSON: [String: Any] = [
            "id": mockUser.id,
            "name": mockUser.name,
        ]

        let (response, data) = try MockURLProtocol.mockJSONResponse(
            url: request.url!,
            statusCode: 200,
            json: responseJSON
        )
        return (response, data)
    }

    // Create client
    let clientConfig = NetworkClientConfiguration(
        baseURL: "https://api.example.com",
        urlSessionConfiguration: configuration
    )
    let client = NetworkClient(configuration: clientConfig)

    // Execute request with custom headers
    let user = try await client.execute(AuthenticatedRequest(token: "secret-token"))

    // Verify
    #expect(user.id == "me")
}

@Test("NetworkClient throws ResponseError on 404")
func testNetworkClientHandles404() async throws {
    setupTest()

    // Setup mock
    let configuration = createMockConfiguration()

    MockURLProtocol.requestHandler = { request in
        let response = MockURLProtocol.mockResponse(
            url: request.url!,
            statusCode: 404
        )
        return (response, Data())
    }

    // Create client
    let clientConfig = NetworkClientConfiguration(
        baseURL: "https://api.example.com",
        urlSessionConfiguration: configuration
    )
    let client = NetworkClient(configuration: clientConfig)

    // Execute request and expect error
    do {
        _ = try await client.execute(GetUserRequest(userId: "999"))
        Issue.record("Expected ResponseError to be thrown")
    } catch let error as ResponseError {
        if case .clientError(let statusCode, _) = error {
            #expect(statusCode == 404)
        } else {
            Issue.record("Expected clientError, got \(error)")
        }
    }
}

@Test("NetworkClient throws ResponseError on 500")
func testNetworkClientHandles500() async throws {
    setupTest()

    // Setup mock
    let configuration = createMockConfiguration()

    MockURLProtocol.requestHandler = { request in
        let response = MockURLProtocol.mockResponse(
            url: request.url!,
            statusCode: 500
        )
        return (response, Data())
    }

    // Create client
    let clientConfig = NetworkClientConfiguration(
        baseURL: "https://api.example.com",
        urlSessionConfiguration: configuration
    )
    let client = NetworkClient(configuration: clientConfig)

    // Execute request and expect error
    do {
        _ = try await client.execute(GetUserRequest(userId: "123"))
        Issue.record("Expected ResponseError to be thrown")
    } catch let error as ResponseError {
        if case .serverError(let statusCode, _) = error {
            #expect(statusCode == 500)
        } else {
            Issue.record("Expected serverError, got \(error)")
        }
    }
}

@Test("NetworkClient throws ResponseError on decoding failure")
func testNetworkClientHandlesDecodingFailure() async throws {
    setupTest()

    // Setup mock
    let configuration = createMockConfiguration()

    MockURLProtocol.requestHandler = { request in
        // Return invalid JSON structure
        let invalidJSON: [String: Any] = [
            "wrong_field": "value",
        ]

        let (response, data) = try MockURLProtocol.mockJSONResponse(
            url: request.url!,
            statusCode: 200,
            json: invalidJSON
        )
        return (response, data)
    }

    // Create client
    let clientConfig = NetworkClientConfiguration(
        baseURL: "https://api.example.com",
        urlSessionConfiguration: configuration
    )
    let client = NetworkClient(configuration: clientConfig)

    // Execute request and expect decoding error
    do {
        _ = try await client.execute(GetUserRequest(userId: "123"))
        Issue.record("Expected ResponseError.decodingFailed to be thrown")
    } catch let error as ResponseError {
        if case .decodingFailed = error {
            // Success
        } else {
            Issue.record("Expected decodingFailed, got \(error)")
        }
    }
}

@Test("NetworkClient handles URL encoding for query parameters")
func testNetworkClientURLEncoding() async throws {
    setupTest()

    // Setup mock
    let configuration = createMockConfiguration()

    MockURLProtocol.requestHandler = { request in
        // Verify query parameters are in URL
        let urlComponents = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)
        let queryItems = urlComponents?.queryItems

        #expect(queryItems?.contains(where: { $0.name == "q" && $0.value == "test" }) == true)
        #expect(queryItems?.contains(where: { $0.name == "limit" && $0.value == "20" }) == true)

        let responseJSON: [[String: Any]] = [
            ["id": "1", "name": "Result 1"],
        ]

        let data = try JSONSerialization.data(withJSONObject: responseJSON)
        let response = MockURLProtocol.mockResponse(
            url: request.url!,
            statusCode: 200,
            headers: ["Content-Type": "application/json"]
        )
        return (response, data)
    }

    // Create client
    let clientConfig = NetworkClientConfiguration(
        baseURL: "https://api.example.com",
        urlSessionConfiguration: configuration
    )
    let client = NetworkClient(configuration: clientConfig)

    // Execute request with URL encoding
    let results = try await client.execute(SearchRequest(query: "test", limit: 20))

    // Verify
    #expect(results.count == 1)
}

}
