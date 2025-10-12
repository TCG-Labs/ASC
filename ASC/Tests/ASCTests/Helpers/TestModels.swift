// TestModels.swift
// ASC Tests
//
// Test models and request types for testing.

import Foundation
@testable import ASC

// MARK: - Test Models

/// Test user model for testing.
public struct TestUser: Codable, Sendable, Equatable {
    public let id: String
    public let name: String
    public let email: String?

    public init(id: String, name: String, email: String? = nil) {
        self.id = id
        self.name = name
        self.email = email
    }
}

/// Test post model for testing.
public struct TestPost: Codable, Sendable, Equatable {
    public let id: String
    public let title: String
    public let content: String
    public let authorId: String

    public init(id: String, title: String, content: String, authorId: String) {
        self.id = id
        self.title = title
        self.content = content
        self.authorId = authorId
    }
}

/// Test error response model.
public struct TestErrorResponse: Codable, Sendable {
    public let error: String
    public let message: String
    public let code: Int
}

// MARK: - Test Requests

/// Simple GET request for testing.
public struct GetUserRequest: NetworkRequest {
    public typealias Response = TestUser

    public let userId: String

    public var path: String { "/users/\(userId)" }
    public var method: HTTPMethod { .get }

    public init(userId: String) {
        self.userId = userId
    }
}

/// GET request with path parameters.
public struct GetUserWithPathParamsRequest: NetworkRequest {
    public typealias Response = TestUser

    public let userId: String

    public var path: String { "/users/{userId}" }
    public var method: HTTPMethod { .get }
    public var pathParameters: [String: String]? { ["userId": userId] }

    public init(userId: String) {
        self.userId = userId
    }
}

/// GET request with path prefix.
public struct GetUserWithPrefixRequest: NetworkRequest {
    public typealias Response = TestUser

    public let userId: String

    public var pathPrefix: String? { "/api/v1" }
    public var path: String { "/users/{userId}" }
    public var method: HTTPMethod { .get }
    public var pathParameters: [String: String]? { ["userId": userId] }

    public init(userId: String) {
        self.userId = userId
    }
}

/// POST request with JSON body.
public struct CreatePostRequest: NetworkRequest {
    public typealias Response = TestPost

    public let title: String
    public let content: String
    public let authorId: String

    public var path: String { "/posts" }
    public var method: HTTPMethod { .post }
    public var parameters: Parameters? {
        [
            "title": title,
            "content": content,
            "authorId": authorId,
        ]
    }

    public init(title: String, content: String, authorId: String) {
        self.title = title
        self.content = content
        self.authorId = authorId
    }
}

/// PUT request for updating.
public struct UpdateUserRequest: NetworkRequest {
    public typealias Response = TestUser

    public let userId: String
    public let name: String
    public let email: String

    public var path: String { "/users/\(userId)" }
    public var method: HTTPMethod { .put }
    public var parameters: Parameters? {
        ["name": name, "email": email]
    }

    public init(userId: String, name: String, email: String) {
        self.userId = userId
        self.name = name
        self.email = email
    }
}

/// DELETE request with empty response.
public struct DeleteUserRequest: NetworkRequest {
    public typealias Response = ASCEmptyResponse

    public let userId: String

    public var path: String { "/users/\(userId)" }
    public var method: HTTPMethod { .delete }

    public init(userId: String) {
        self.userId = userId
    }
}

/// Request with URL encoding for query parameters.
public struct SearchRequest: NetworkRequest {
    public typealias Response = [TestUser]

    public let query: String
    public let limit: Int

    public var path: String { "/search" }
    public var method: HTTPMethod { .get }
    public var parameters: Parameters? {
        ["q": query, "limit": limit]
    }
    public var parameterEncoding: any ParameterEncoding {
        URLEncoding.default
    }

    public init(query: String, limit: Int = 10) {
        self.query = query
        self.limit = limit
    }
}

/// Request with custom headers.
public struct AuthenticatedRequest: NetworkRequest {
    public typealias Response = TestUser

    public let token: String

    public var path: String { "/me" }
    public var method: HTTPMethod { .get }
    public var headers: HTTPHeaders? {
        HTTPHeaders([.authorization(bearerToken: token)])
    }

    public init(token: String) {
        self.token = token
    }
}

/// Request with custom timeout.
public struct SlowRequest: NetworkRequest {
    public typealias Response = TestUser

    public var path: String { "/slow" }
    public var method: HTTPMethod { .get }
    public var timeout: TimeInterval? { 5.0 }
}

/// Request with file upload.
public struct UploadFileRequest: NetworkRequest {
    public typealias Response = TestUser

    public let userId: String
    public let fileData: Data

    public var path: String { "/users/{userId}/avatar" }
    public var method: HTTPMethod { .post }
    public var pathParameters: [String: String]? { ["userId": userId] }
    public var files: [String: Data]? { ["avatar": fileData] }

    public init(userId: String, fileData: Data) {
        self.userId = userId
        self.fileData = fileData
    }
}
