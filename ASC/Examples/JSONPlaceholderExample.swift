// JSONPlaceholderExample.swift
// ASC - Basic CRUD Operations

import ASC
import Foundation

// MARK: - Models

struct Post: Codable, Sendable {
    let id: Int?
    let userId: Int
    let title: String
    let body: String
}

struct Comment: Codable, Sendable {
    let id: Int
    let postId: Int
    let name: String
    let email: String
    let body: String
}

// MARK: - API Requests

enum PostAPI {
    struct Get: NetworkRequest {
        typealias Response = Post
        let postId: Int

        var path: String { "/posts/{id}" }
        var method: HTTPMethod { .get }
        var pathParameters: [String: String]? { ["id": String(postId)] }
    }

    struct Create: NetworkRequest {
        typealias Response = Post
        let userId: Int
        let title: String
        let body: String

        var path: String { "/posts" }
        var method: HTTPMethod { .post }
        var parameters: Parameters? {
            ["userId": userId, "title": title, "body": body]
        }
    }

    struct Update: NetworkRequest {
        typealias Response = Post
        let postId: Int
        let userId: Int
        let title: String
        let body: String

        var path: String { "/posts/{id}" }
        var method: HTTPMethod { .put }
        var pathParameters: [String: String]? { ["id": String(postId)] }
        var parameters: Parameters? {
            ["userId": userId, "title": title, "body": body]
        }
    }

    struct Delete: NetworkRequest {
        typealias Response = ASCEmptyResponse
        let postId: Int

        var path: String { "/posts/{id}" }
        var method: HTTPMethod { .delete }
        var pathParameters: [String: String]? { ["id": String(postId)] }
    }

    struct GetComments: NetworkRequest {
        typealias Response = [Comment]
        let postId: Int

        var path: String { "/posts/{id}/comments" }
        var method: HTTPMethod { .get }
        var pathParameters: [String: String]? { ["id": String(postId)] }
    }
}

// MARK: - Examples

@MainActor
func runBasicExamples() async throws {
    let client = NetworkClient(baseURL: "https://jsonplaceholder.typicode.com")

    debugPrint("=== ASC Basic Examples ===\n")

    let post = try await client.execute(PostAPI.Get(postId: 1))
    debugPrint("1. GET: \(post.title)")

    let newPost = try await client.execute(
        PostAPI.Create(userId: 1, title: "New Post", body: "Content")
    )
    debugPrint("2. POST: Created #\(newPost.id ?? 0)")

    let updated = try await client.execute(
        PostAPI.Update(postId: 1, userId: 1, title: "Updated", body: "New content")
    )
    debugPrint("3. PUT: \(updated.title)")

    try await client.execute(PostAPI.Delete(postId: 1))
    debugPrint("4. DELETE: Success")

    let comments = try await client.execute(PostAPI.GetComments(postId: 1))
    debugPrint("5. Nested path: \(comments.count) comments")

    debugPrint("\n=== Error Handling ===\n")
    do {
        _ = try await client.execute(PostAPI.Get(postId: 99999))
    } catch let error as ResponseError {
        switch error {
        case let .clientError(code, message):
            debugPrint("Client error \(code): \(message ?? "N/A")")
        default:
            debugPrint("Other error: \(error)")
        }
    }
}
