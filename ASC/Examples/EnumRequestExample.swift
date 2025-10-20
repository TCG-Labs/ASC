// EnumRequestExample.swift
// ASC - Request Organization Patterns

import ASC
import Foundation

// MARK: - Models

struct User: Codable, Sendable {
    let id: String
    let name: String
    let email: String
}

struct Post: Codable, Sendable {
    let id: String
    let title: String
    let body: String
}

// MARK: - Pattern 1: Namespace Enum (Recommended)

enum UserAPI {
    struct Get: NetworkRequest {
        typealias Response = User
        let userId: String

        var path: String { "/users/{id}" }
        var method: HTTPMethod { .get }
        var pathParameters: [String: String]? { ["id": userId] }
    }

    struct List: NetworkRequest {
        typealias Response = [User]
        let page: Int

        var path: String { "/users" }
        var method: HTTPMethod { .get }
        var parameters: Parameters? { ["page": page] }
        var parameterEncoding: any ParameterEncoding { URLEncoding.default }
    }

    struct Delete: NetworkRequest {
        typealias Response = ASCEmptyResponse
        let userId: String

        var path: String { "/users/{id}" }
        var method: HTTPMethod { .delete }
        var pathParameters: [String: String]? { ["id": userId] }
    }
}

// MARK: - Pattern 2: Simple Enum

enum PostRequest: NetworkRequest {
    typealias Response = Post

    case get(id: String)
    case list(page: Int)
    case create(title: String, body: String)

    var path: String {
        switch self {
        case .get: return "/posts/{id}"
        case .list, .create: return "/posts"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .get, .list: return .get
        case .create: return .post
        }
    }

    var pathParameters: [String: String]? {
        switch self {
        case .get(let id): return ["id": id]
        default: return nil
        }
    }

    var parameters: Parameters? {
        switch self {
        case .list(let page): return ["page": page]
        case .create(let title, let body): return ["title": title, "body": body]
        default: return nil
        }
    }
}

// MARK: - Usage

@MainActor
func demonstratePatterns() async throws {
    let client = NetworkClient(baseURL: "https://api.example.com")

    debugPrint("=== Namespace Enum Pattern ===")
    let user = try await client.execute(UserAPI.Get(userId: "123"))
    debugPrint("User: \(user.name)")

    let users = try await client.execute(UserAPI.List(page: 1))
    debugPrint("Users: \(users.count)")

    try await client.execute(UserAPI.Delete(userId: "123"))
    debugPrint("Deleted\n")

    debugPrint("=== Simple Enum Pattern ===")
    let post = try await client.execute(PostRequest.get(id: "456"))
    debugPrint("Post: \(post.title)")

    let posts = try await client.execute(PostRequest.list(page: 1))
    debugPrint("Posts: \(posts.count)")
}
