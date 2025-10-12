// AdvancedNetworkTests.swift
// ASC Tests
//
// Tests for advanced networking scenarios: concurrency, retry, timeout, etc.

import Alamofire
@testable import ASC
import Foundation
import Testing

// MARK: - Retry Policy Tests

extension IntegrationTests {
@Test("RetryPolicy.default has correct values")
func testRetryPolicyDefault() {
    let policy = RetryPolicy.default

    #expect(policy.maxRetries == 3)
    #expect(policy.retryDelay == 1.0)
    #expect(policy.exponentialBackoff == true)
    #expect(policy.retryOnNetworkError == true)
    #expect(policy.retryableStatusCodes.contains(500))
    #expect(policy.retryableStatusCodes.contains(502))
    #expect(policy.retryableStatusCodes.contains(503))
}

@Test("RetryPolicy.none disables retries")
func testRetryPolicyNone() {
    let policy = RetryPolicy.none

    #expect(policy.maxRetries == 0)
}

@Test("RetryPolicy.aggressive has more retries")
func testRetryPolicyAggressive() {
    let policy = RetryPolicy.aggressive

    #expect(policy.maxRetries == 5)
    #expect(policy.retryDelay == 2.0)
}

@Test("RetryPolicy can be customized")
func testRetryPolicyCustom() {
    let customCodes: Set<HTTPStatusCode> = [408, 429]
    let policy = RetryPolicy(
        maxRetries: 2,
        retryDelay: 0.5,
        exponentialBackoff: false,
        retryableStatusCodes: customCodes,
        retryOnNetworkError: false
    )

    #expect(policy.maxRetries == 2)
    #expect(policy.retryDelay == 0.5)
    #expect(policy.exponentialBackoff == false)
    #expect(policy.retryableStatusCodes == customCodes)
    #expect(policy.retryOnNetworkError == false)
}

@Test("NetworkRequest has default retry policy")
func testNetworkRequestDefaultRetryPolicy() {
    let request = GetUserRequest(userId: "123")

    #expect(request.retryPolicy.maxRetries == 3)
}

// MARK: - Concurrent Requests Tests

@Test("NetworkClient handles concurrent requests")
func testConcurrentRequests() async throws {
    setupTest()
    // Setup mock
    let configuration = createMockConfiguration()

    var requestCount = 0
    MockURLProtocol.requestHandler = { request in
        requestCount += 1

        let userId = request.url?.lastPathComponent ?? "unknown"
        let responseJSON: [String: Any] = [
            "id": userId,
            "name": "User \(userId)"
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

    // Execute 5 concurrent requests
    let userIds = ["1", "2", "3", "4", "5"]
    let results = try await withThrowingTaskGroup(of: TestUser.self) { group in
        for userId in userIds {
            group.addTask {
                try await client.execute(GetUserRequest(userId: userId))
            }
        }

        var users: [TestUser] = []
        for try await user in group {
            users.append(user)
        }
        return users
    }

    // Verify all requests completed
    #expect(results.count == 5)
    #expect(requestCount == 5)
}

@Test("NetworkClient handles concurrent requests with different types")
func testConcurrentMixedRequests() async throws {
    setupTest()
    // Setup mock
    let configuration = createMockConfiguration()

    MockURLProtocol.requestHandler = { request in
        if request.url?.path.contains("users") == true {
            let responseJSON: [String: Any] = [
                "id": "1",
                "name": "User 1"
            ]
            let (response, data) = try MockURLProtocol.mockJSONResponse(
                url: request.url!,
                statusCode: 200,
                json: responseJSON
            )
            return (response, data)
        } else {
            let responseJSON: [String: Any] = [
                "id": "post1",
                "title": "Post",
                "content": "Content",
                "authorId": "1"
            ]
            let (response, data) = try MockURLProtocol.mockJSONResponse(
                url: request.url!,
                statusCode: 200,
                json: responseJSON
            )
            return (response, data)
        }
    }

    // Create client
    let clientConfig = NetworkClientConfiguration(
        baseURL: "https://api.example.com",
        urlSessionConfiguration: configuration
    )
    let client = NetworkClient(configuration: clientConfig)

    // Execute mixed concurrent requests
    async let user = client.execute(GetUserRequest(userId: "1"))
    async let post = client.execute(
        CreatePostRequest(title: "Post", content: "Content", authorId: "1")
    )

    let (fetchedUser, createdPost) = try await (user, post)

    // Verify
    #expect(fetchedUser.id == "1")
    #expect(createdPost.id == "post1")
}

// MARK: - Timeout Tests

@Test("NetworkClient respects custom timeout")
func testCustomTimeout() async throws {
    setupTest()
    // Setup mock with delay
    let configuration = createMockConfiguration()

    MockURLProtocol.responseDelay = 0.1 // Small delay for test speed

    MockURLProtocol.requestHandler = { request in
        let responseJSON: [String: Any] = [
            "id": "123",
            "name": "Test User"
        ]

        let (response, data) = try MockURLProtocol.mockJSONResponse(
            url: request.url!,
            statusCode: 200,
            json: responseJSON
        )
        return (response, data)
    }

    // Create client with short timeout
    let clientConfig = NetworkClientConfiguration(
        baseURL: "https://api.example.com",
        urlSessionConfiguration: configuration,
        defaultTimeout: 5.0
    )
    let client = NetworkClient(configuration: clientConfig)

    // Execute request with custom timeout
    let user = try await client.execute(SlowRequest())

    // Verify request completed
    #expect(user.id == "123")

    // Reset delay
    MockURLProtocol.responseDelay = 0.0
}

// MARK: - Multipart Upload Tests

@Test("NetworkClient handles multipart file upload")
func testMultipartFileUpload() async throws {
    setupTest()
    // Setup mock
    let configuration = createMockConfiguration()

    let testFileData = Data("Test file content".utf8)

    MockURLProtocol.requestHandler = { request in
        // Verify Content-Type is multipart/form-data
        let contentType = request.value(forHTTPHeaderField: "Content-Type")
        #expect(contentType?.contains("multipart/form-data") == true)

        // Verify method is POST
        #expect(request.httpMethod == "POST")

        let responseJSON: [String: Any] = [
            "id": "123",
            "name": "User with avatar"
        ]

        guard let url = request.url else {
            throw NSError(domain: "Test", code: -1, userInfo: nil)
        }
        let (response, data) = try MockURLProtocol.mockJSONResponse(
            url: url,
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

    // Execute upload request
    let user = try await client.execute(
        UploadFileRequest(userId: "123", fileData: testFileData)
    )

    // Verify
    #expect(user.id == "123")
}

@Test("NetworkClient handles multipart upload with EmptyResponse")
func testMultipartUploadEmptyResponse() async throws {
    setupTest()
    // Setup mock
    let configuration = createMockConfiguration()

    let testFileData = Data("Test file content".utf8)

    MockURLProtocol.requestHandler = { request in
        guard let url = request.url else {
            throw NSError(domain: "Test", code: -1, userInfo: nil)
        }
        let response = MockURLProtocol.mockResponse(
            url: url,
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

    // Define upload request with ASCEmptyResponse
    struct UploadWithoutResponseRequest: NetworkRequest {
        typealias Response = ASCEmptyResponse
        let fileData: Data

        var path: String { "/upload" }
        var method: HTTPMethod { .post }
        var files: [String: Data]? { ["file": fileData] }
    }

    // Execute upload request (should not throw)
    try await client.execute(UploadWithoutResponseRequest(fileData: testFileData))

    // Verify request was made
    #expect(MockURLProtocol.requestHistory.count == 1)
}

// MARK: - Default Headers Tests

@Test("NetworkClient uses default headers")
func testDefaultHeaders() async throws {
    setupTest()
    // Setup mock
    let configuration = createMockConfiguration()

    let mockUser = TestUser(id: "123", name: "Test User")

    MockURLProtocol.requestHandler = { request in
        // Verify custom default headers
        let customHeader = request.value(forHTTPHeaderField: "X-App-Version")
        #expect(customHeader == "1.0")

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

    // Create client with default headers
    let defaultHeaders: HTTPHeaders = [
        "X-App-Version": "1.0"
    ]
    let clientConfig = NetworkClientConfiguration(
        baseURL: "https://api.example.com",
        urlSessionConfiguration: configuration,
        defaultHeaders: defaultHeaders
    )
    let client = NetworkClient(configuration: clientConfig)

    // Execute request
    _ = try await client.execute(GetUserRequest(userId: "123"))
}

@Test("Request-specific headers override default headers")
func testHeaderOverride() async throws {
    setupTest()
    // Setup mock
    let configuration = createMockConfiguration()

    let mockUser = TestUser(id: "me", name: "Current User")

    MockURLProtocol.requestHandler = { request in
        // Verify request header overrides default
        let authHeader = request.value(forHTTPHeaderField: "Authorization")
        #expect(authHeader == "Bearer specific-token")

        // Verify default header still present
        let appVersion = request.value(forHTTPHeaderField: "X-App-Version")
        #expect(appVersion == "1.0")

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

    // Create client with default headers
    let defaultHeaders: HTTPHeaders = [
        "X-App-Version": "1.0",
        "Authorization": "Bearer default-token"
    ]
    let clientConfig = NetworkClientConfiguration(
        baseURL: "https://api.example.com",
        urlSessionConfiguration: configuration,
        defaultHeaders: defaultHeaders
    )
    let client = NetworkClient(configuration: clientConfig)

    // Execute request with specific header that overrides default
    _ = try await client.execute(AuthenticatedRequest(token: "specific-token"))
}

// MARK: - EmptyResponse Tests

@Test("ASCEmptyResponse can be created")
func testEmptyResponseCreation() {
    let emptyResponse = ASCEmptyResponse()

    // ASCEmptyResponse should be creatable - just verify it exists
    _ = emptyResponse
}

@Test("ASCEmptyResponse is Codable")
func testEmptyResponseCodable() throws {
    let emptyResponse = ASCEmptyResponse()

    // Should encode to JSON
    let encoder = JSONEncoder()
    let data = try encoder.encode(emptyResponse)
    #expect(!data.isEmpty)

    // Should decode from JSON
    let decoder = JSONDecoder()
    let decoded = try decoder.decode(ASCEmptyResponse.self, from: data)
    _ = decoded
}
}
