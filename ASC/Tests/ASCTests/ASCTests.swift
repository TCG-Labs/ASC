import Testing
import Foundation
@testable import ASC

// MARK: - Test Models

struct TestUser: Codable, Sendable {
    let id: String
    let name: String
}

// MARK: - Path Parameter Tests

@Test("Path parameter substitution with single parameter")
func testPathParameterSubstitution() async throws {
    let client = NetworkClient(baseURL: "https://api.example.com")

    let path = "/users/{userId}"
    let parameters = ["userId": "123"]

    let result = client.substitutePath(path, with: parameters)

    #expect(result == "/users/123")
}

@Test("Path parameter substitution with multiple parameters")
func testMultiplePathParameters() async throws {
    let client = NetworkClient(baseURL: "https://api.example.com")

    let path = "/users/{userId}/posts/{postId}"
    let parameters = ["userId": "123", "postId": "456"]

    let result = client.substitutePath(path, with: parameters)

    #expect(result == "/users/123/posts/456")
}

@Test("Path parameter substitution with no parameters")
func testPathWithoutParameters() async throws {
    let client = NetworkClient(baseURL: "https://api.example.com")

    let path = "/users/all"
    let parameters: [String: String] = [:]

    let result = client.substitutePath(path, with: parameters)

    #expect(result == "/users/all")
}

// MARK: - NetworkRequest with Path Parameters

struct GetUserRequest: NetworkRequest {
    typealias Response = TestUser

    let userId: String

    var path: String { "/users/{userId}" }
    var method: HTTPMethod { .get }
    var pathParameters: [String: String]? { ["userId": userId] }
}

@Test("NetworkRequest with path parameters")
func testNetworkRequestWithPathParameters() async throws {
    let request = GetUserRequest(userId: "123")

    #expect(request.path == "/users/{userId}")
    #expect(request.pathParameters == ["userId": "123"])
}

// MARK: - NetworkRequest with Path Prefix

struct GetAPIUserRequest: NetworkRequest {
    typealias Response = TestUser

    let userId: String

    var pathPrefix: String? { "/api/v1" }
    var path: String { "/users/{userId}" }
    var method: HTTPMethod { .get }
    var pathParameters: [String: String]? { ["userId": userId] }
}

@Test("NetworkRequest with path prefix")
func testNetworkRequestWithPathPrefix() async throws {
    let request = GetAPIUserRequest(userId: "123")

    #expect(request.pathPrefix == "/api/v1")
    #expect(request.path == "/users/{userId}")
    #expect(request.pathParameters == ["userId": "123"])
}

// MARK: - File Upload Request

struct UploadFileRequest: NetworkRequest {
    typealias Response = EmptyResponse

    let fileData: Data
    let fileName: String

    var path: String { "/upload" }
    var method: HTTPMethod { .post }
    var files: [String: Data]? { [fileName: fileData] }
    var parameters: Parameters? { ["description": "Test file"] }
}

@Test("NetworkRequest with file upload")
func testNetworkRequestWithFileUpload() async throws {
    let testData = "Hello, World!".data(using: .utf8)!
    let request = UploadFileRequest(fileData: testData, fileName: "test.txt")

    #expect(request.files?["test.txt"] == testData)
    #expect(request.parameters?["description"] as? String == "Test file")
}

// MARK: - Default Values Tests

struct MinimalRequest: NetworkRequest {
    typealias Response = TestUser

    var path: String { "/users" }
    var method: HTTPMethod { .get }
}

@Test("NetworkRequest default values")
func testNetworkRequestDefaults() async throws {
    let request = MinimalRequest()

    #expect(request.baseURL == nil)
    #expect(request.headers == nil)
    #expect(request.parameters == nil)
    #expect(request.timeout == nil)
    #expect(request.cachePolicy == nil)
    #expect(request.pathParameters == nil)
    #expect(request.pathPrefix == nil)
    #expect(request.files == nil)
}
