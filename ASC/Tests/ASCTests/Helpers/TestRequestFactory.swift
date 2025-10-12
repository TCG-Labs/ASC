// TestRequestFactory.swift
// ASC Tests
//
// Factory for creating test requests with sensible defaults.

import Foundation
@testable import ASC

/// Factory for creating test requests with default values.
///
/// Simplifies test setup by providing pre-configured request instances.
public enum TestRequestFactory {
    // MARK: - Default Test Data

    /// Default test user ID.
    public static let defaultUserId = "test-user-123"

    /// Default test user name.
    public static let defaultUserName = "Test User"

    /// Default test email.
    public static let defaultEmail = "test@example.com"

    /// Default test post title.
    public static let defaultPostTitle = "Test Post"

    /// Default test post content.
    public static let defaultPostContent = "This is a test post content."

    /// Default test token.
    public static let defaultToken = "test-token-abc123"

    /// Default test file data.
    public static let defaultFileData = "Test file content".data(using: .utf8)!

    // MARK: - GET Requests

    /// Creates a basic GET user request.
    ///
    /// - Parameter userId: User ID (default: defaultUserId)
    /// - Returns: GetUserRequest instance
    public static func getUser(userId: String = defaultUserId) -> GetUserRequest {
        GetUserRequest(userId: userId)
    }

    /// Creates a GET user request with path parameters.
    ///
    /// - Parameter userId: User ID (default: defaultUserId)
    /// - Returns: GetUserWithPathParamsRequest instance
    public static func getUserWithPathParams(
        userId: String = defaultUserId
    ) -> GetUserWithPathParamsRequest {
        GetUserWithPathParamsRequest(userId: userId)
    }

    /// Creates a GET user request with path prefix.
    ///
    /// - Parameter userId: User ID (default: defaultUserId)
    /// - Returns: GetUserWithPrefixRequest instance
    public static func getUserWithPrefix(
        userId: String = defaultUserId
    ) -> GetUserWithPrefixRequest {
        GetUserWithPrefixRequest(userId: userId)
    }

    /// Creates a search request with query parameters.
    ///
    /// - Parameters:
    ///   - query: Search query (default: "test")
    ///   - limit: Result limit (default: 10)
    /// - Returns: SearchRequest instance
    public static func search(query: String = "test", limit: Int = 10) -> SearchRequest {
        SearchRequest(query: query, limit: limit)
    }

    /// Creates an authenticated request.
    ///
    /// - Parameter token: Bearer token (default: defaultToken)
    /// - Returns: AuthenticatedRequest instance
    public static func authenticated(token: String = defaultToken) -> AuthenticatedRequest {
        AuthenticatedRequest(token: token)
    }

    /// Creates a slow request with custom timeout.
    ///
    /// - Returns: SlowRequest instance
    public static func slow() -> SlowRequest {
        SlowRequest()
    }

    // MARK: - POST Requests

    /// Creates a POST request to create a post.
    ///
    /// - Parameters:
    ///   - title: Post title (default: defaultPostTitle)
    ///   - content: Post content (default: defaultPostContent)
    ///   - authorId: Author ID (default: defaultUserId)
    /// - Returns: CreatePostRequest instance
    public static func createPost(
        title: String = defaultPostTitle,
        content: String = defaultPostContent,
        authorId: String = defaultUserId
    ) -> CreatePostRequest {
        CreatePostRequest(title: title, content: content, authorId: authorId)
    }

    // MARK: - PUT Requests

    /// Creates a PUT request to update a user.
    ///
    /// - Parameters:
    ///   - userId: User ID (default: defaultUserId)
    ///   - name: User name (default: defaultUserName)
    ///   - email: User email (default: defaultEmail)
    /// - Returns: UpdateUserRequest instance
    public static func updateUser(
        userId: String = defaultUserId,
        name: String = defaultUserName,
        email: String = defaultEmail
    ) -> UpdateUserRequest {
        UpdateUserRequest(userId: userId, name: name, email: email)
    }

    // MARK: - DELETE Requests

    /// Creates a DELETE request to delete a user.
    ///
    /// - Parameter userId: User ID (default: defaultUserId)
    /// - Returns: DeleteUserRequest instance
    public static func deleteUser(userId: String = defaultUserId) -> DeleteUserRequest {
        DeleteUserRequest(userId: userId)
    }

    // MARK: - Upload Requests

    /// Creates a file upload request.
    ///
    /// - Parameters:
    ///   - userId: User ID (default: defaultUserId)
    ///   - fileData: File data (default: defaultFileData)
    /// - Returns: UploadFileRequest instance
    public static func uploadFile(
        userId: String = defaultUserId,
        fileData: Data = defaultFileData
    ) -> UploadFileRequest {
        UploadFileRequest(userId: userId, fileData: fileData)
    }
}
