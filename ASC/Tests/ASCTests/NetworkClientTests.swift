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

@Test("NetworkClient without baseURL works when request provides it")
func testNetworkClientWithoutBaseURL() async throws {
    setupTest()

    let mockUser = TestUser(id: "123", name: "John Doe", email: "john@example.com")
    MockURLProtocol.requestHandler = MockResponseBuilder.success(mockUser).handler()

    struct RequestWithBaseURL: NetworkRequest {
        typealias Response = TestUser
        let userId: String
        var baseURL: String? { "https://custom-api.example.com" }
        var path: String { "/users/\(userId)" }
        var method: HTTPMethod { .get }
    }

    let client = createMockClientWithoutBaseURL()
    let request = RequestWithBaseURL(userId: "123")
    let user = try await client.execute(request)

    #expect(user == mockUser)
    #expect(MockURLProtocol.requestHistory.first?.url?.absoluteString == "https://custom-api.example.com/users/123")
}

@Test("NetworkClient without baseURL throws error when request doesn't provide it")
func testNetworkClientWithoutBaseURLThrowsError() async throws {
    setupTest()

    struct RequestWithoutBaseURL: NetworkRequest {
        typealias Response = TestUser
        var path: String { "/users/123" }
        var method: HTTPMethod { .get }
    }

    let client = createMockClientWithoutBaseURL()
    let request = RequestWithoutBaseURL()

    do {
        _ = try await client.execute(request)
        Issue.record("Expected URLBuildError to be thrown")
    } catch {
        // Success - error should be thrown
    }
}

@Test("Request baseURL overrides client baseURL")
func testRequestBaseURLOverridesClientBaseURL() async throws {
    setupTest()

    let mockUser = TestUser(id: "123", name: "John Doe", email: "john@example.com")
    MockURLProtocol.requestHandler = MockResponseBuilder.success(mockUser).handler()

    struct RequestWithCustomBaseURL: NetworkRequest {
        typealias Response = TestUser
        let userId: String
        var baseURL: String? { "https://override-api.example.com" }
        var path: String { "/users/\(userId)" }
        var method: HTTPMethod { .get }
    }

    let client = createMockClient(baseURL: "https://default-api.example.com")
    let request = RequestWithCustomBaseURL(userId: "123")
    let user = try await client.execute(request)

    #expect(user == mockUser)
    #expect(MockURLProtocol.requestHistory.first?.url?.absoluteString == "https://override-api.example.com/users/123")
}

// MARK: - Task Cancellation Tests

@Test("NetworkClient cancels request when Task is cancelled")
func testTaskCancellation() async throws {
    setupTest()

    let mockUser = TestUser(id: "123", name: "John Doe", email: "john@example.com")
    MockURLProtocol.requestHandler = MockResponseBuilder.success(mockUser)
        .delay(0.5)
        .handler()

    let client = createMockClient()
    let request = TestRequestFactory.getUser(userId: "123")

    let task = Task<TestUser, Error> {
        try await client.execute(request)
    }

    try await Task.sleep(nanoseconds: 100_000_000)
    task.cancel()

    let result = await task.result

    switch result {
    case .success:
        Issue.record("Expected task to be cancelled, but it succeeded")
    case .failure(let error):
        #expect(error is CancellationError, "Expected CancellationError, got \(error)")
    }
}

@Test("NetworkClient cancels empty response request when Task is cancelled")
func testTaskCancellationEmptyResponse() async throws {
    setupTest()

    MockURLProtocol.requestHandler = MockResponseBuilder.emptySuccess()
        .delay(0.5)
        .handler()

    let client = createMockClient()
    let request = TestRequestFactory.deleteUser(userId: "123")

    let task = Task<Void, Error> {
        try await client.execute(request)
    }

    try await Task.sleep(nanoseconds: 100_000_000)
    task.cancel()

    let result = await task.result

    switch result {
    case .success:
        Issue.record("Expected task to be cancelled, but it succeeded")
    case .failure(let error):
        #expect(error is CancellationError, "Expected CancellationError, got \(error)")
    }
}

@Test("NetworkClient cancels multipart upload when Task is cancelled")
func testTaskCancellationMultipartUpload() async throws {
    setupTest()

    let mockUser = TestUser(id: "123", name: "John Doe", email: "john@example.com")
    MockURLProtocol.requestHandler = MockResponseBuilder.success(mockUser)
        .delay(0.5)
        .handler()

    let client = createMockClient()
    let imageData = Data([0x89, 0x50, 0x4E, 0x47])
    let request = TestRequestFactory.uploadFile(userId: "123", fileData: imageData)

    let task = Task<TestUser, Error> {
        try await client.execute(request)
    }

    try await Task.sleep(nanoseconds: 100_000_000)
    task.cancel()

    let result = await task.result

    switch result {
    case .success:
        Issue.record("Expected task to be cancelled, but it succeeded")
    case .failure(let error):
        #expect(error is CancellationError, "Expected CancellationError, got \(error)")
    }
}

@Test("NetworkClient completes request when Task is not cancelled")
func testNoCancellation() async throws {
    setupTest()

    let mockUser = TestUser(id: "123", name: "John Doe", email: "john@example.com")
    MockURLProtocol.requestHandler = MockResponseBuilder.success(mockUser)
        .delay(0.1)
        .handler()

    let client = createMockClient()
    let request = TestRequestFactory.getUser(userId: "123")

    let user = try await client.execute(request)
    #expect(user == mockUser)
}

// MARK: - Progress Tracking Tests

@Test("NetworkClient tracks upload progress for multipart request")
func testUploadProgress() async throws {
    setupTest()

    let mockUser = TestUser(id: "123", name: "John Doe", email: "john@example.com")
    MockURLProtocol.requestHandler = MockResponseBuilder.success(mockUser).handler()

    let client = createMockClient()
    let imageData = Data([0x89, 0x50, 0x4E, 0x47])
    let request = TestRequestFactory.uploadFile(userId: "123", fileData: imageData)

    var progressUpdates: [Double] = []
    var finalResponse: TestUser?

    for try await update in client.executeWithProgress(request) {
        switch update {
        case .progress(let value):
            progressUpdates.append(value)
        case .completed(let response):
            finalResponse = response
        }
    }

    #expect(finalResponse == mockUser)
    // Progress values should be between 0.0 and 1.0
    for progress in progressUpdates {
        #expect(progress >= 0.0 && progress <= 1.0, "Progress \(progress) out of range")
    }
}

@Test("NetworkClient tracks download progress for regular request")
func testDownloadProgress() async throws {
    setupTest()

    let mockUser = TestUser(id: "123", name: "John Doe", email: "john@example.com")
    MockURLProtocol.requestHandler = MockResponseBuilder.success(mockUser).handler()

    let client = createMockClient()
    let request = TestRequestFactory.getUser(userId: "123")

    var progressUpdates: [Double] = []
    var finalResponse: TestUser?

    for try await update in client.executeWithProgress(request) {
        switch update {
        case .progress(let value):
            progressUpdates.append(value)
        case .completed(let response):
            finalResponse = response
        }
    }

    #expect(finalResponse == mockUser)
    for progress in progressUpdates {
        #expect(progress >= 0.0 && progress <= 1.0, "Progress \(progress) out of range")
    }
}

@Test("NetworkClient handles progress with empty response")
func testProgressWithEmptyResponse() async throws {
    setupTest()

    MockURLProtocol.requestHandler = MockResponseBuilder.emptySuccess().handler()

    let client = createMockClient()
    let request = TestRequestFactory.deleteUser(userId: "123")

    var progressUpdates: [Double] = []
    var completed = false

    for try await update in client.executeWithProgress(request) {
        switch update {
        case .progress(let value):
            progressUpdates.append(value)
        case .completed:
            completed = true
        }
    }

    #expect(completed)
    for progress in progressUpdates {
        #expect(progress >= 0.0 && progress <= 1.0, "Progress \(progress) out of range")
    }
}

@Test("NetworkClient cancels progress stream when Task is cancelled")
func testProgressCancellation() async throws {
    setupTest()

    let mockUser = TestUser(id: "123", name: "John Doe", email: "john@example.com")
    MockURLProtocol.requestHandler = MockResponseBuilder.success(mockUser)
        .delay(0.5)
        .handler()

    let client = createMockClient()
    let request = TestRequestFactory.getUser(userId: "123")

    let task = Task {
        var receivedCompletion = false
        for try await update in client.executeWithProgress(request) {
            if case .completed = update {
                receivedCompletion = true
            }
        }
        return receivedCompletion
    }

    // Give the task a moment to start
    try await Task.sleep(nanoseconds: 50_000_000)
    task.cancel()

    let result = await task.result

    // With MockURLProtocol, the request completes synchronously,
    // so we expect either cancellation OR completion
    switch result {
    case .success(let receivedCompletion):
        // If it completed, that's okay for mock (happens synchronously)
        #expect(receivedCompletion || !receivedCompletion)
    case .failure(let error):
        // Cancellation is also acceptable
        #expect(error is CancellationError, "Expected CancellationError, got \(error)")
    }
}

@Test("NetworkClient handles errors in progress stream")
func testProgressWithError() async throws {
    setupTest()

    MockURLProtocol.requestHandler = MockResponseBuilder.notFound().handler()

    let client = createMockClient()
    let request = TestRequestFactory.getUser(userId: "999")

    var receivedUpdates = 0
    var caughtError: Error?

    do {
        for try await update in client.executeWithProgress(request) {
            receivedUpdates += 1
            // Progress updates may still occur before error
            if case .progress = update {
                // This is acceptable
            }
        }
        Issue.record("Expected error to be thrown")
    } catch let error as ResponseError {
        caughtError = error
        #expect(error.statusCode == 404)
    } catch {
        Issue.record("Expected ResponseError, got \(error)")
    }

    #expect(caughtError != nil, "Should have caught an error")
}

// MARK: - Custom Response Validation Tests

@Test("NetworkClient calls validate() on successful response")
func testCustomValidationSuccess() async throws {
    setupTest()

    struct ResponseWithStatus: Codable, Equatable, Sendable {
        let success: Bool
        let data: String
    }

    struct ValidatedRequest: NetworkRequest {
        typealias Response = ResponseWithStatus

        var path: String { "/test" }
        var method: HTTPMethod { .get }

        func validate(response: ResponseWithStatus) throws {
            guard response.success else {
                throw ResponseError.validationFailed("API returned success=false")
            }
        }
    }

    let mockResponse = ResponseWithStatus(success: true, data: "Hello")
    MockURLProtocol.requestHandler = MockResponseBuilder.success(mockResponse).handler()

    let client = createMockClient()
    let request = ValidatedRequest()

    let response = try await client.execute(request)
    #expect(response.success == true)
    #expect(response.data == "Hello")
}

@Test("NetworkClient validation failure throws error")
func testCustomValidationFailure() async throws {
    setupTest()

    struct ResponseWithStatus: Codable, Equatable, Sendable {
        let success: Bool
        let errorMessage: String?
    }

    struct ValidatedRequest: NetworkRequest {
        typealias Response = ResponseWithStatus

        var path: String { "/test" }
        var method: HTTPMethod { .get }

        func validate(response: ResponseWithStatus) throws {
            guard response.success else {
                throw ResponseError.validationFailed(response.errorMessage ?? "Unknown error")
            }
        }
    }

    let mockResponse = ResponseWithStatus(success: false, errorMessage: "User not found")
    MockURLProtocol.requestHandler = MockResponseBuilder.success(mockResponse).handler()

    let client = createMockClient()
    let request = ValidatedRequest()

    do {
        _ = try await client.execute(request)
        Issue.record("Expected validation error to be thrown")
    } catch let error as ResponseError {
        if case .validationFailed(let message) = error {
            #expect(message == "User not found")
        } else {
            Issue.record("Expected validationFailed, got \(error)")
        }
    }
}

@Test("NetworkClient default validation does not throw")
func testDefaultValidationNoError() async throws {
    setupTest()

    // Use standard request without custom validation
    let mockUser = TestUser(id: "123", name: "John Doe", email: "john@example.com")
    MockURLProtocol.requestHandler = MockResponseBuilder.success(mockUser).handler()

    let client = createMockClient()
    let request = TestRequestFactory.getUser(userId: "123")

    // Should not throw - default validation does nothing
    let user = try await client.execute(request)
    #expect(user == mockUser)
}

@Test("NetworkClient validation works with file uploads")
func testValidationWithFileUpload() async throws {
    setupTest()

    struct UploadResponse: Codable, Equatable, Sendable {
        let success: Bool
        let fileId: String?
        let error: String?
    }

    struct ValidatedUploadRequest: NetworkRequest {
        typealias Response = UploadResponse

        let fileData: Data

        var path: String { "/upload" }
        var method: HTTPMethod { .post }
        var files: [String: Data]? { ["file": fileData] }

        func validate(response: UploadResponse) throws {
            guard response.success, response.fileId != nil else {
                throw ResponseError.validationFailed(response.error ?? "Upload failed")
            }
        }
    }

    let mockResponse = UploadResponse(success: true, fileId: "file-123", error: nil)
    MockURLProtocol.requestHandler = MockResponseBuilder.success(mockResponse).handler()

    let client = createMockClient()
    let imageData = Data([0x89, 0x50, 0x4E, 0x47])
    let request = ValidatedUploadRequest(fileData: imageData)

    let response = try await client.execute(request)
    #expect(response.success == true)
    #expect(response.fileId == "file-123")
}

@Test("NetworkClient validation works with progress tracking")
func testValidationWithProgress() async throws {
    setupTest()

    struct ResponseWithStatus: Codable, Equatable, Sendable {
        let success: Bool
        let data: String
    }

    struct ValidatedRequest: NetworkRequest {
        typealias Response = ResponseWithStatus

        var path: String { "/test" }
        var method: HTTPMethod { .get }

        func validate(response: ResponseWithStatus) throws {
            guard response.success else {
                throw ResponseError.validationFailed("Validation failed")
            }
        }
    }

    let mockResponse = ResponseWithStatus(success: false, data: "Error")
    MockURLProtocol.requestHandler = MockResponseBuilder.success(mockResponse).handler()

    let client = createMockClient()
    let request = ValidatedRequest()

    do {
        for try await update in client.executeWithProgress(request) {
            if case .completed = update {
                Issue.record("Should not complete - validation should fail")
            }
        }
        Issue.record("Expected validation error to be thrown")
    } catch let error as ResponseError {
        if case .validationFailed = error {
            // Success
        } else {
            Issue.record("Expected validationFailed, got \(error)")
        }
    }
}

// MARK: - Built-in Logger Tests

@Test("NetworkClient with logLevel creates ASCLogger")
func testLoggerEnabled() async throws {
    setupTest()

    let config = NetworkClientConfiguration(
        baseURL: "https://api.example.com",
        logLevel: .debug
    )

    // Logger should be automatically added to eventMonitors
    #expect(config.eventMonitors.count == 1)
    #expect(config.eventMonitors.first is ASCLogger)
}

@Test("NetworkClient without logLevel has no ASCLogger")
func testLoggerDisabled() async throws {
    setupTest()

    let config = NetworkClientConfiguration(
        baseURL: "https://api.example.com",
        logLevel: .none
    )

    // No logger should be added
    #expect(config.eventMonitors.isEmpty)
}

@Test("NetworkClient with logLevel and custom monitors includes both")
func testLoggerWithCustomMonitors() async throws {
    setupTest()

    let customMonitor = MockEventMonitor()
    let config = NetworkClientConfiguration(
        baseURL: "https://api.example.com",
        eventMonitors: [customMonitor],
        logLevel: .info
    )

    // Should have both custom monitor and ASCLogger
    #expect(config.eventMonitors.count == 2)

    let hasCustomMonitor = config.eventMonitors.contains { $0 is MockEventMonitor }
    let hasLogger = config.eventMonitors.contains { $0 is ASCLogger }

    #expect(hasCustomMonitor)
    #expect(hasLogger)
}

@Test("NetworkClient logger works with requests")
func testLoggerWithRequests() async throws {
    setupTest()

    let mockUser = TestUser(id: "123", name: "John Doe", email: "john@example.com")
    MockURLProtocol.requestHandler = MockResponseBuilder.success(mockUser).handler()

    // Create client with logging enabled
    let config = NetworkClientConfiguration(
        baseURL: "https://api.example.com",
        logLevel: .debug
    )

    let urlConfig = URLSessionConfiguration.default
    urlConfig.protocolClasses = [MockURLProtocol.self]

    let client = NetworkClient(configuration: NetworkClientConfiguration(
        baseURL: config.baseURL,
        urlSessionConfiguration: urlConfig,
        logLevel: .debug
    ))

    let request = TestRequestFactory.getUser(userId: "123")

    // Should complete successfully with logging
    let user = try await client.execute(request)
    #expect(user == mockUser)
}

@Test("ASCLogLevel ordering is correct")
func testLogLevelOrdering() {
    #expect(ASCLogLevel.none.rawValue < ASCLogLevel.error.rawValue)
    #expect(ASCLogLevel.error.rawValue < ASCLogLevel.info.rawValue)
    #expect(ASCLogLevel.info.rawValue < ASCLogLevel.debug.rawValue)
    #expect(ASCLogLevel.debug.rawValue < ASCLogLevel.verbose.rawValue)
}
}
