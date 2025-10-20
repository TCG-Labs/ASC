// QuickStart.swift
// ASC - Quick Start Example

import ASC
import Foundation

// MARK: - Model

struct Post: Codable, Sendable {
    let id: Int
    let title: String
    let body: String
}

// MARK: - Requests

enum PostAPI {
    struct GetAll: NetworkRequest {
        typealias Response = [Post]
        var path: String { "/posts" }
        var method: HTTPMethod { .get }
    }

    struct Create: NetworkRequest {
        typealias Response = Post
        let title: String
        let body: String
        let userId: Int

        var path: String { "/posts" }
        var method: HTTPMethod { .post }
        var parameters: Parameters? {
            ["title": title, "body": body, "userId": userId]
        }
    }
}

// MARK: - Usage

@MainActor
func quickStart() async throws {
    let client = NetworkClient(baseURL: "https://jsonplaceholder.typicode.com")

    let posts = try await client.execute(PostAPI.GetAll())
    debugPrint("Fetched \(posts.count) posts")

    let newPost = try await client.execute(
        PostAPI.Create(title: "Hello ASC", body: "My first request", userId: 1)
    )
    debugPrint("Created post #\(newPost.id): \(newPost.title)")
}
