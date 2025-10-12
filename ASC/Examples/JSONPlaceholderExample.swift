// JSONPlaceholderExample.swift
// ASC Usage Example
//
// This example demonstrates how to use the ASC library with the JSONPlaceholder API
// (https://jsonplaceholder.typicode.com) - a free fake REST API for testing.

import ASC
import Foundation

// MARK: - Models

/// Represents a blog post from JSONPlaceholder API
struct Post: Codable, Sendable {
    let id: Int?
    let userId: Int
    let title: String
    let body: String
}

/// Represents a user from JSONPlaceholder API
struct User: Codable, Sendable {
    let id: Int
    let name: String
    let username: String
    let email: String
}

/// Represents a comment from JSONPlaceholder API
struct Comment: Codable, Sendable {
    let id: Int
    let postId: Int
    let name: String
    let email: String
    let body: String
}

// MARK: - Network Requests

/// Fetch all posts
struct GetPostsRequest: NetworkRequest {
    typealias Response = [Post]

    var path: String { "/posts" }
    var method: HTTPMethod { .get }
}

/// Fetch a single post by ID
struct GetPostRequest: NetworkRequest {
    typealias Response = Post

    let postId: Int

    var path: String { "/posts/{id}" }
    var method: HTTPMethod { .get }
    var pathParameters: [String: String]? {
        ["id": String(postId)]
    }
}

/// Create a new post
struct CreatePostRequest: NetworkRequest {
    typealias Response = Post

    let userId: Int
    let title: String
    let body: String

    var path: String { "/posts" }
    var method: HTTPMethod { .post }
    var parameters: Parameters? {
        [
            "userId": userId,
            "title": title,
            "body": body
        ]
    }
}

/// Update an existing post
struct UpdatePostRequest: NetworkRequest {
    typealias Response = Post

    let postId: Int
    let userId: Int
    let title: String
    let body: String

    var path: String { "/posts/{id}" }
    var method: HTTPMethod { .put }
    var pathParameters: [String: String]? {
        ["id": String(postId)]
    }
    var parameters: Parameters? {
        [
            "userId": userId,
            "title": title,
            "body": body
        ]
    }
}

/// Delete a post
struct DeletePostRequest: NetworkRequest {
    typealias Response = ASCEmptyResponse

    let postId: Int

    var path: String { "/posts/{id}" }
    var method: HTTPMethod { .delete }
    var pathParameters: [String: String]? {
        ["id": String(postId)]
    }
}

/// Fetch posts for a specific user
struct GetUserPostsRequest: NetworkRequest {
    typealias Response = [Post]

    let userId: Int

    var path: String { "/posts" }
    var method: HTTPMethod { .get }
    var parameters: Parameters? {
        ["userId": userId]
    }
    var parameterEncoding: any ParameterEncoding {
        URLEncoding.default
    }
}

/// Fetch comments for a specific post
struct GetPostCommentsRequest: NetworkRequest {
    typealias Response = [Comment]

    let postId: Int

    var path: String { "/posts/{id}/comments" }
    var method: HTTPMethod { .get }
    var pathParameters: [String: String]? {
        ["id": String(postId)]
    }
}

/// Fetch a user by ID
struct GetUserRequest: NetworkRequest {
    typealias Response = User

    let userId: Int

    var path: String { "/users/{id}" }
    var method: HTTPMethod { .get }
    var pathParameters: [String: String]? {
        ["id": String(userId)]
    }
}

// MARK: - Example Usage

@MainActor
class JSONPlaceholderService {
    private let client: NetworkClient

    init() {
        // Initialize the client with JSONPlaceholder base URL
        self.client = NetworkClient(baseURL: "https://jsonplaceholder.typicode.com")
    }

    // MARK: - Example Methods

    /// Example 1: Fetch all posts
    func fetchAllPosts() async throws -> [Post] {
        debugPrint("📖 Fetching all posts...")

        let posts = try await client.execute(GetPostsRequest())

        debugPrint("✅ Fetched \(posts.count) posts")
        return posts
    }

    /// Example 2: Fetch a single post by ID
    func fetchPost(id: Int) async throws -> Post {
        debugPrint("📄 Fetching post #\(id)...")

        let post = try await client.execute(GetPostRequest(postId: id))

        debugPrint("✅ Fetched post: \"\(post.title)\"")
        return post
    }

    /// Example 3: Create a new post
    func createPost(userId: Int, title: String, body: String) async throws -> Post {
        debugPrint("✍️  Creating new post...")

        let post = try await client.execute(
            CreatePostRequest(userId: userId, title: title, body: body)
        )

        debugPrint("✅ Created post with ID: \(post.id ?? 0)")
        return post
    }

    /// Example 4: Update an existing post
    func updatePost(id: Int, userId: Int, title: String, body: String) async throws -> Post {
        debugPrint("📝 Updating post #\(id)...")

        let post = try await client.execute(
            UpdatePostRequest(postId: id, userId: userId, title: title, body: body)
        )

        debugPrint("✅ Updated post: \"\(post.title)\"")
        return post
    }

    /// Example 5: Delete a post
    func deletePost(id: Int) async throws {
        debugPrint("🗑️  Deleting post #\(id)...")

        try await client.execute(DeletePostRequest(postId: id))

        debugPrint("✅ Post deleted successfully")
    }

    /// Example 6: Fetch posts by user ID (URL parameters)
    func fetchUserPosts(userId: Int) async throws -> [Post] {
        debugPrint("👤 Fetching posts for user #\(userId)...")

        let posts = try await client.execute(GetUserPostsRequest(userId: userId))

        debugPrint("✅ Found \(posts.count) posts for user")
        return posts
    }

    /// Example 7: Fetch comments for a post
    func fetchPostComments(postId: Int) async throws -> [Comment] {
        debugPrint("💬 Fetching comments for post #\(postId)...")

        let comments = try await client.execute(GetPostCommentsRequest(postId: postId))

        debugPrint("✅ Found \(comments.count) comments")
        return comments
    }

    /// Example 8: Fetch user information
    func fetchUser(id: Int) async throws -> User {
        debugPrint("👤 Fetching user #\(id)...")

        let user = try await client.execute(GetUserRequest(userId: id))

        debugPrint("✅ Fetched user: \(user.name) (@\(user.username))")
        return user
    }

    /// Example 9: Complex workflow - Create post and fetch comments
    func createPostAndFetchComments() async throws {
        debugPrint("\n🔄 Starting complex workflow...\n")

        // Step 1: Create a new post
        let newPost = try await createPost(
            userId: 1,
            title: "Testing ASC Library",
            body: "This post was created using the ASC networking library!"
        )

        // Step 2: Fetch comments for the post (simulated)
        if let postId = newPost.id {
            let comments = try await fetchPostComments(postId: 1) // Using post 1 as example
            debugPrint("📊 Post has \(comments.count) comments")
        }

        debugPrint("\n✅ Complex workflow completed!\n")
    }

    /// Example 10: Concurrent requests
    func fetchMultiplePostsConcurrently() async throws {
        debugPrint("\n⚡ Fetching multiple posts concurrently...\n")

        let postIds = [1, 2, 3, 4, 5]

        let posts = try await withThrowingTaskGroup(of: Post.self) { group in
            for postId in postIds {
                group.addTask {
                    try await self.client.execute(GetPostRequest(postId: postId))
                }
            }

            var results: [Post] = []
            for try await post in group {
                results.append(post)
                debugPrint("  ✓ Fetched: \"\(post.title)\"")
            }
            return results
        }

        debugPrint("\n✅ Fetched \(posts.count) posts concurrently!\n")
    }

    /// Example 11: Error handling
    func demonstrateErrorHandling() async {
        debugPrint("\n⚠️  Demonstrating error handling...\n")

        do {
            // Try to fetch a non-existent post
            _ = try await client.execute(GetPostRequest(postId: 99999))
        } catch let error as ResponseError {
            switch error {
            case .clientError(let statusCode, let message):
                debugPrint("❌ Client Error (\(statusCode)): \(message ?? "Unknown")")
            case .serverError(let statusCode, let message):
                debugPrint("❌ Server Error (\(statusCode)): \(message)")
            case .decodingFailed(let decodingError, _):
                debugPrint("❌ Decoding Error: \(decodingError.localizedDescription)")
            case .missingData:
                debugPrint("❌ Missing response data")
            case .invalidStatusCode(let code, _):
                debugPrint("❌ Invalid status code: \(code)")
            case .invalidFormat(let description):
                debugPrint("❌ Invalid format: \(description)")
            case .validationFailed(let description):
                debugPrint("❌ Validation failed: \(description)")
            }
        } catch let error as NetworkError {
            switch error {
            case .noConnection:
                debugPrint("❌ No internet connection")
            case .timeout(let duration):
                debugPrint("❌ Request timed out after \(duration) seconds")
            case .hostUnreachable(let host):
                debugPrint("❌ Cannot reach host: \(host)")
            case .certificateValidationFailed(let reason):
                debugPrint("❌ Certificate validation failed: \(reason)")
            case .cancelled:
                debugPrint("❌ Request was cancelled")
            case .networkFailure(let underlyingError):
                debugPrint("❌ Network failure: \(underlyingError.localizedDescription)")
            }
        } catch {
            debugPrint("❌ Unexpected error: \(error.localizedDescription)")
        }

        debugPrint("\n✅ Error handling demonstration completed!\n")
    }
}

// MARK: - Main Example Runner

/// Run all examples
@MainActor
func runExamples() async {
    let service = JSONPlaceholderService()

    debugPrint("=" * 60)
    debugPrint("ASC Library - JSONPlaceholder API Examples")
    debugPrint("=" * 60)
    debugPrint()

    do {
        // Example 1: Fetch all posts (limited to first 5 for display)
        let posts = try await service.fetchAllPosts()
        debugPrint("First 5 posts:")
        posts.prefix(5).forEach { post in
            debugPrint("  • [\(post.id ?? 0)] \(post.title)")
        }
        debugPrint()

        // Example 2: Fetch single post
        let post = try await service.fetchPost(id: 1)
        debugPrint("Post details:")
        debugPrint("  Title: \(post.title)")
        debugPrint("  Body: \(post.body.prefix(50))...")
        debugPrint()

        // Example 3: Create post
        let newPost = try await service.createPost(
            userId: 1,
            title: "ASC Library is Awesome!",
            body: "This is a test post created with the ASC networking library."
        )
        debugPrint()

        // Example 4: Update post
        _ = try await service.updatePost(
            id: 1,
            userId: 1,
            title: "Updated Title",
            body: "Updated body content"
        )
        debugPrint()

        // Example 5: Delete post
        try await service.deletePost(id: 1)
        debugPrint()

        // Example 6: Fetch user posts
        let userPosts = try await service.fetchUserPosts(userId: 1)
        debugPrint("User's posts: \(userPosts.count) found")
        debugPrint()

        // Example 7: Fetch comments
        let comments = try await service.fetchPostComments(postId: 1)
        debugPrint("Post comments:")
        comments.prefix(3).forEach { comment in
            debugPrint("  • \(comment.name): \(comment.body.prefix(40))...")
        }
        debugPrint()

        // Example 8: Fetch user
        let user = try await service.fetchUser(id: 1)
        debugPrint("User: \(user.name) <\(user.email)>")
        debugPrint()

        // Example 9: Complex workflow
        try await service.createPostAndFetchComments()

        // Example 10: Concurrent requests
        try await service.fetchMultiplePostsConcurrently()

        // Example 11: Error handling
        await service.demonstrateErrorHandling()

        debugPrint("=" * 60)
        debugPrint("✅ All examples completed successfully!")
        debugPrint("=" * 60)

    } catch {
        debugPrint("\n❌ Example failed with error:")
        debugPrint(error)
    }
}

// Helper for string repetition
extension String {
    static func * (left: String, right: Int) -> String {
        String(repeating: left, count: right)
    }
}

// MARK: - Usage Instructions

/*
 To run these examples:

 1. Add ASC to your project:
    ```swift
    dependencies: [
        .package(url: "https://github.com/YOUR_USERNAME/ASC.git", from: "1.0.0")
    ]
    ```

 2. Create a new Swift file in your project and copy this code

 3. Call runExamples() from your app:
    ```swift
    Task {
        await runExamples()
    }
    ```

 4. Or run from a command-line tool:
    ```swift
    @main
    struct Main {
        static func main() async {
            await runExamples()
        }
    }
    ```

 API Documentation: https://jsonplaceholder.typicode.com

 Available Endpoints:
 - GET    /posts              - Get all posts
 - GET    /posts/1            - Get post by ID
 - POST   /posts              - Create new post
 - PUT    /posts/1            - Update post
 - DELETE /posts/1            - Delete post
 - GET    /posts?userId=1     - Get posts by user
 - GET    /posts/1/comments   - Get comments for post
 - GET    /users              - Get all users
 - GET    /users/1            - Get user by ID
 */
