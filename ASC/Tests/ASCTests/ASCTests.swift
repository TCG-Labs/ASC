@testable import ASC
import Foundation
import Testing

// MARK: - NetworkRequest with Path Parameters

@Test("NetworkRequest with path parameters")
func testNetworkRequestWithPathParameters() async throws {
    let request = GetUserWithPathParamsRequest(userId: "123")

    #expect(request.path == "/users/{userId}")
    #expect(request.pathParameters == ["userId": "123"])
}

// MARK: - NetworkRequest with Path Prefix

@Test("NetworkRequest with path prefix")
func testNetworkRequestWithPathPrefix() async throws {
    let request = GetUserWithPrefixRequest(userId: "123")

    #expect(request.pathPrefix == "/api/v1")
    #expect(request.path == "/users/{userId}")
    #expect(request.pathParameters == ["userId": "123"])
}

// MARK: - File Upload Request

@Test("NetworkRequest with file upload")
func testNetworkRequestWithFileUpload() async throws {
    let testData = Data("Hello, World!".utf8)
    let request = UploadFileRequest(userId: "test", fileData: testData)

    #expect(request.files?["avatar"] == testData)
}

// MARK: - Default Values Tests

@Test("NetworkRequest default values")
func testNetworkRequestDefaults() async throws {
    let request = GetUserRequest(userId: "123")

    #expect(request.baseURL == nil)
    #expect(request.headers == nil)
    #expect(request.parameters == nil)
    #expect(request.timeout == nil)
    #expect(request.cachePolicy == nil)
    #expect(request.pathParameters == nil)
    #expect(request.pathPrefix == nil)
    #expect(request.files == nil)
}
