// NetworkClientTests.swift
// ASC Tests
//
// Integration tests for NetworkClient.

import Alamofire
@testable import ASC
import Foundation
import Testing

// MARK: - NetworkClient Integration Tests

@Suite("Integration Tests", .serialized)
struct IntegrationTests {}

extension IntegrationTests {
@Test("NetworkClient executes successful GET request")
func testNetworkClientSuccessfulGET() async throws {
    setupTest()

    // Setup mock response
    let mockUser = TestUser(id: "123", name: "John Doe", email: "john@example.com")
    MockURLProtocol.requestHandler = MockResponseBuilder.success(mockUser).handler()

    // Execute request
    let client = createMockClient()
    let request = TestRequestFactory.getUser(userId: "123")
    let user = try await client.execute(request)

    // Verify
    #expect(user == mockUser)
    #expect(MockURLProtocol.requestHistory.count == 1)
    #expect(MockURLProtocol.requestHistory.first?.url?.path == "/users/123")
}

@Test("NetworkClient executes successful POST request with JSON body")
func testNetworkClientSuccessfulPOST() async throws {
    setupTest()

    // Setup mock response
    let mockPost = TestPost(id: "post1", title: "Test Post", content: "Test Content", authorId: "user1")
    MockURLProtocol.requestHandler = MockResponseBuilder.success(mockPost).statusCode(201).handler()

    // Execute request
    let client = createMockClient()
    let request = TestRequestFactory.createPost(title: "Test Post", content: "Test Content", authorId: "user1")
    let post = try await client.execute(request)

    // Verify
    #expect(post == mockPost)
}

@Test("NetworkClient executes PUT request")
func testNetworkClientPUT() async throws {
    setupTest()

    // Setup mock response
    let updatedUser = TestUser(id: "123", name: "Jane Doe", email: "jane@example.com")
    MockURLProtocol.requestHandler = { request in
        #expect(request.httpMethod == "PUT")
        return try MockResponseBuilder.success(updatedUser).build(url: request.url!)
    }

    // Execute request
    let client = createMockClient()
    let request = TestRequestFactory.updateUser(userId: "123", name: "Jane Doe", email: "jane@example.com")
    let user = try await client.execute(request)

    // Verify
    #expect(user == updatedUser)
}

@Test("NetworkClient executes DELETE request with EmptyResponse")
func testNetworkClientDELETE() async throws {
    setupTest()

    // Setup mock response
    MockURLProtocol.requestHandler = { request in
        #expect(request.httpMethod == "DELETE")
        return try MockResponseBuilder.emptySuccess().build(url: request.url!)
    }

    // Execute request
    let client = createMockClient()
    let request = TestRequestFactory.deleteUser(userId: "123")
    try await client.execute(request)

    // Verify
    #expect(MockURLProtocol.requestHistory.count == 1)
    #expect(MockURLProtocol.requestHistory.first?.url?.path == "/users/123")
}

@Test("NetworkClient handles path parameters substitution")
func testNetworkClientPathParameters() async throws {
    setupTest()

    // Setup mock response
    let mockUser = TestUser(id: "456", name: "Test User")
    MockURLProtocol.requestHandler = { request in
        #expect(request.url?.path == "/users/456")
        return try MockResponseBuilder.success(mockUser).build(url: request.url!)
    }

    // Execute request
    let client = createMockClient()
    let request = TestRequestFactory.getUserWithPathParams(userId: "456")
    let user = try await client.execute(request)

    // Verify
    #expect(user.id == "456")
}

@Test("NetworkClient handles path prefix")
func testNetworkClientPathPrefix() async throws {
    setupTest()

    // Setup mock response
    let mockUser = TestUser(id: "789", name: "Prefixed User")
    MockURLProtocol.requestHandler = { request in
        #expect(request.url?.path == "/api/v1/users/789")
        return try MockResponseBuilder.success(mockUser).build(url: request.url!)
    }

    // Execute request
    let client = createMockClient()
    let request = TestRequestFactory.getUserWithPrefix(userId: "789")
    let user = try await client.execute(request)

    // Verify
    #expect(user.id == "789")
}

@Test("NetworkClient handles custom headers")
func testNetworkClientCustomHeaders() async throws {
    setupTest()

    // Setup mock response
    let mockUser = TestUser(id: "me", name: "Current User")
    MockURLProtocol.requestHandler = { request in
        // Verify authorization header
        let authHeader = request.value(forHTTPHeaderField: "Authorization")
        #expect(authHeader == "Bearer secret-token")
        return try MockResponseBuilder.success(mockUser).build(url: request.url!)
    }

    // Execute request
    let client = createMockClient()
    let request = TestRequestFactory.authenticated(token: "secret-token")
    let user = try await client.execute(request)

    // Verify
    #expect(user.id == "me")
}

@Test("NetworkClient throws ResponseError on 404")
func testNetworkClientHandles404() async throws {
    setupTest()

    // Setup mock error response
    MockURLProtocol.requestHandler = MockResponseBuilder.notFound().handler()

    // Execute request and expect error
    let client = createMockClient()
    let request = TestRequestFactory.getUser(userId: "999")

    do {
        _ = try await client.execute(request)
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

    // Setup mock error response
    MockURLProtocol.requestHandler = MockResponseBuilder.serverError().handler()

    // Execute request and expect error
    let client = createMockClient()
    let request = TestRequestFactory.getUser()

    do {
        _ = try await client.execute(request)
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

    // Setup mock response with invalid JSON structure
    MockURLProtocol.requestHandler = { request in
        // Return JSON with wrong fields
        let invalidJSON: [String: Any] = ["wrong_field": "value"]
        let (response, data) = try MockURLProtocol.mockJSONResponse(
            url: request.url!,
            statusCode: 200,
            json: invalidJSON
        )
        return (response, data)
    }

    // Execute request and expect decoding error
    let client = createMockClient()
    let request = TestRequestFactory.getUser()

    do {
        _ = try await client.execute(request)
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

    // Setup mock response
    MockURLProtocol.requestHandler = { request in
        // Verify query parameters are in URL
        let urlComponents = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)
        let queryItems = urlComponents?.queryItems

        #expect(queryItems?.contains { $0.name == "q" && $0.value == "test" } == true)
        #expect(queryItems?.contains { $0.name == "limit" && $0.value == "20" } == true)

        let resultUser = TestUser(id: "1", name: "Result 1")
        let data = try JSONEncoder().encode([resultUser])
        let response = MockURLProtocol.mockResponse(url: request.url!, statusCode: 200)
        return (response, data)
    }

    // Execute request
    let client = createMockClient()
    let request = TestRequestFactory.search(query: "test", limit: 20)
    let results = try await client.execute(request)

    // Verify
    #expect(results.count == 1)
}

@Test("NetworkClient convenience init with baseURL")
func testNetworkClientConvenienceInit() async throws {
    setupTest()

    // Setup mock response
    let mockUser = TestUser(id: "123", name: "Test User")
    MockURLProtocol.requestHandler = { request in
        // Verify that the convenience init sets the correct baseURL
        #expect(request.url?.host == "api.example.com")
        #expect(request.url?.scheme == "https")

        let responseJSON: [String: Any] = [
            "id": mockUser.id,
            "name": mockUser.name
        ]
        let (response, data) = try MockURLProtocol.mockJSONResponse(
            url: request.url!,
            statusCode: 200,
            json: responseJSON
        )
        return (response, data)
    }

    // Create client using convenience init with mock configuration
    let config = NetworkClientConfiguration(
        baseURL: "https://api.example.com",
        urlSessionConfiguration: createMockConfiguration()
    )
    let client = NetworkClient(configuration: config)

    // Verify the client works by executing a request
    let user = try await client.execute(GetUserRequest(userId: "123"))

    // Verify the request was successful and used the correct baseURL
    #expect(user.id == "123")
    #expect(user.name == "Test User")
    #expect(MockURLProtocol.requestHistory.count == 1)
    #expect(MockURLProtocol.requestHistory.first?.url?.absoluteString.hasPrefix("https://api.example.com") == true)
}

@Test("NetworkClient throws ResponseError.missingData when response value is nil")
func testNetworkClientMissingData() async throws {
    setupTest()

    // Setup mock response with empty data
    MockURLProtocol.requestHandler = { request in
        let response = MockURLProtocol.mockResponse(url: request.url!, statusCode: 200)
        // Return empty data which will cause decoding to fail and value to be nil
        return (response, Data())
    }

    // Execute request and expect error
    let client = createMockClient()
    let request = TestRequestFactory.getUser()

    do {
        _ = try await client.execute(request)
        Issue.record("Expected ResponseError to be thrown")
    } catch let error as ResponseError {
        // Should get missingData or decodingFailed error
        if case .missingData = error {
            // Success - this is expected
        } else if case .decodingFailed = error {
            // Also acceptable
        } else {
            Issue.record("Expected decodingFailed or missingData, got \(error)")
        }
    }
}

@Test("NetworkClient handles error in empty response request")
func testNetworkClientEmptyResponseError() async throws {
    setupTest()

    // Setup mock error response
    MockURLProtocol.requestHandler = MockResponseBuilder.serverError().handler()

    // Execute request and expect error
    let client = createMockClient()
    let request = TestRequestFactory.deleteUser(userId: "123")

    do {
        try await client.execute(request)
        Issue.record("Expected ResponseError to be thrown")
    } catch let error as ResponseError {
        if case .serverError = error {
            // Success
        } else {
            Issue.record("Expected serverError, got \(error)")
        }
    }
}

@Test("NetworkClient handles error in multipart upload")
func testNetworkClientMultipartUploadError() async throws {
    setupTest()

    // Setup mock error response
    MockURLProtocol.requestHandler = MockResponseBuilder.serverError().handler()

    // Execute upload request and expect error
    let client = createMockClient()
    let fileData = Data("Test file content".utf8)

    struct UploadRequest: NetworkRequest {
        typealias Response = TestUser
        let fileData: Data
        var path: String { "/upload" }
        var method: HTTPMethod { .post }
        var files: [String: Data]? { ["file": fileData] }
    }

    let request = UploadRequest(fileData: fileData)

    do {
        _ = try await client.execute(request)
        Issue.record("Expected ResponseError to be thrown")
    } catch let error as ResponseError {
        if case .serverError = error {
            // Success
        } else {
            Issue.record("Expected serverError, got \(error)")
        }
    }
}

@Test("NetworkClient handles error in multipart empty response")
func testNetworkClientMultipartEmptyResponseError() async throws {
    setupTest()

    // Setup mock error response
    MockURLProtocol.requestHandler = MockResponseBuilder.notFound().handler()

    // Execute upload request and expect error
    let client = createMockClient()
    let fileData = Data("Test file content".utf8)

    struct UploadEmptyRequest: NetworkRequest {
        typealias Response = ASCEmptyResponse
        let fileData: Data
        var path: String { "/upload" }
        var method: HTTPMethod { .post }
        var files: [String: Data]? { ["file": fileData] }
    }

    let request = UploadEmptyRequest(fileData: fileData)

    do {
        try await client.execute(request)
        Issue.record("Expected ResponseError to be thrown")
    } catch let error as ResponseError {
        if case .clientError = error {
            // Success
        } else {
            Issue.record("Expected clientError, got \(error)")
        }
    }
}

@Test("NetworkClient throws ResponseError.missingData in multipart when value is nil")
func testNetworkClientMultipartMissingData() async throws {
    setupTest()

    // Setup mock response with empty data
    MockURLProtocol.requestHandler = { request in
        let response = MockURLProtocol.mockResponse(url: request.url!, statusCode: 200)
        // Return empty data which will cause value to be nil
        return (response, Data())
    }

    // Execute request and expect error
    let client = createMockClient()
    let fileData = Data("Test file content".utf8)

    struct UploadRequest: NetworkRequest {
        typealias Response = TestUser
        let fileData: Data
        var path: String { "/upload" }
        var method: HTTPMethod { .post }
        var files: [String: Data]? { ["file": fileData] }
    }

    let request = UploadRequest(fileData: fileData)

    do {
        _ = try await client.execute(request)
        Issue.record("Expected ResponseError to be thrown")
    } catch let error as ResponseError {
        // Should get missingData or decodingFailed error
        if case .missingData = error {
            // Success - this is expected
        } else if case .decodingFailed = error {
            // Also acceptable
        } else {
            Issue.record("Expected decodingFailed or missingData, got \(error)")
        }
    }
}
}
