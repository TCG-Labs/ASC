// QuickStart.swift
// ASC - Quick Start Example
//
// A minimal example to get started with ASC in 5 minutes.

import ASC
import Foundation

// MARK: - 1. Define Your Model

struct Post: Codable, Sendable {
    let id: Int
    let title: String
    let body: String
}

// MARK: - 2. Create Network Requests

/// Organize requests using Namespace Enum pattern
enum PostAPI {
    /// Fetch all posts
    struct GetAll: NetworkRequest {
        typealias Response = [Post]
        var path: String { "/posts" }
        var method: HTTPMethod { .get }
    }

    /// Create a new post
    struct Create: NetworkRequest {
        typealias Response = Post

        let title: String
        let body: String
        let userId: Int

        var path: String { "/posts" }
        var method: HTTPMethod { .post }
        var parameters: Parameters? {
            [
                "title": title,
                "body": body,
                "userId": userId
            ]
        }
    }
}

// MARK: - 3. Use the Client

@MainActor
func quickStartExample() async throws {
    // Create a network client
    let client = NetworkClient(baseURL: "https://jsonplaceholder.typicode.com")

    // GET request - Fetch posts
    debugPrint("Fetching posts...")
    let posts = try await client.execute(PostAPI.GetAll())
    debugPrint("✅ Fetched \(posts.count) posts")

    // POST request - Create a post
    debugPrint("\nCreating a new post...")
    let newPost = try await client.execute(
        PostAPI.Create(
            title: "Hello from ASC!",
            body: "This is my first request using ASC library",
            userId: 1
        )
    )
    debugPrint("✅ Created post with ID: \(newPost.id)")

    // Display the created post
    debugPrint("\nNew Post:")
    debugPrint("  Title: \(newPost.title)")
    debugPrint("  Body: \(newPost.body)")
}

// MARK: - Run It

/*
 To run this example:

 ```swift
 Task {
     do {
         try await quickStartExample()
     } catch {
         debugPrint("Error: \(error)")
     }
 }
 ```

 That's it! You're now using ASC for networking. 🎉

 Next steps:
 - Check out JSONPlaceholderExample.swift for advanced features
 - Read the documentation in CLAUDE.md
 - Explore error handling, file uploads, and interceptors
 */
