// EnumRequestExample.swift
// ASC - Request Organization Patterns
//
// Demonstrates two main approaches to organizing NetworkRequest:
// 1. Namespace Enum (Recommended)
// 2. Simple Enum (For single response type)

import ASC
import Foundation

// MARK: - Approach 1: Namespace Enum (Recommended) ⭐️

/// Best for: Complex APIs with different response types
/// Provides grouping without enum constraints

enum UserAPI {
    /// Get single user by ID
    struct Get: NetworkRequest {
        typealias Response = User
        let userId: String

        var path: String { "/users/{id}" }
        var method: HTTPMethod { .get }
        var pathParameters: [String: String]? { ["id": userId] }
    }

    /// List users with pagination
    struct List: NetworkRequest {
        typealias Response = [User]
        let page: Int
        let limit: Int

        var path: String { "/users" }
        var method: HTTPMethod { .get }
        var parameters: Parameters? { ["page": page, "limit": limit] }
        var parameterEncoding: any ParameterEncoding { URLEncoding.default }
    }

    /// Create new user
    struct Create: NetworkRequest {
        typealias Response = User
        let name: String
        let email: String

        var path: String { "/users" }
        var method: HTTPMethod { .post }
        var parameters: Parameters? { ["name": name, "email": email] }
    }

    /// Update existing user
    struct Update: NetworkRequest {
        typealias Response = User
        let userId: String
        let name: String
        let email: String

        var path: String { "/users/{id}" }
        var method: HTTPMethod { .put }
        var pathParameters: [String: String]? { ["id": userId] }
        var parameters: Parameters? { ["name": name, "email": email] }
    }

    /// Delete user
    struct Delete: NetworkRequest {
        typealias Response = ASCEmptyResponse
        let userId: String

        var path: String { "/users/{id}" }
        var method: HTTPMethod { .delete }
        var pathParameters: [String: String]? { ["id": userId] }
    }
}

// MARK: - Approach 2: Simple Enum

/// Best for: CRUD operations on single resource type
/// Limitation: All cases must return the same Response type

enum PostRequest: NetworkRequest {
    typealias Response = Post

    case get(id: String)
    case list(page: Int)
    case create(title: String, body: String)
    case update(id: String, title: String, body: String)

    var path: String {
        switch self {
        case .get, .update:
            return "/posts/{id}"
        case .list, .create:
            return "/posts"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .get, .list:
            return .get
        case .create:
            return .post
        case .update:
            return .put
        }
    }

    var pathParameters: [String: String]? {
        switch self {
        case .get(let id), .update(let id, _, _):
            return ["id": id]
        default:
            return nil
        }
    }

    var parameters: Parameters? {
        switch self {
        case .list(let page):
            return ["page": page]
        case .create(let title, let body):
            return ["title": title, "body": body]
        case .update(_, let title, let body):
            return ["title": title, "body": body]
        default:
            return nil
        }
    }
}

// MARK: - Supporting Models

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

// MARK: - Usage Examples

@MainActor
func demonstrateRequestOrganization() async throws {
    let client = NetworkClient(baseURL: "https://api.example.com")

    // ✅ Namespace Enum - Different response types
    debugPrint("=== Namespace Enum Pattern ===")

    let user = try await client.execute(UserAPI.Get(userId: "123"))
    debugPrint("✅ Got user: \(user.name)")

    let users = try await client.execute(UserAPI.List(page: 1, limit: 10))
    debugPrint("✅ Got \(users.count) users")

    let newUser = try await client.execute(
        UserAPI.Create(name: "John", email: "john@example.com")
    )
    debugPrint("✅ Created user: \(newUser.id)")

    try await client.execute(UserAPI.Delete(userId: "123"))
    debugPrint("✅ Deleted user")

    // ✅ Simple Enum - Same response type
    debugPrint("\n=== Simple Enum Pattern ===")

    let post = try await client.execute(PostRequest.get(id: "456"))
    debugPrint("✅ Got post: \(post.title)")

    let posts = try await client.execute(PostRequest.list(page: 1))
    debugPrint("✅ Got \(posts.count) posts")

    let updatedPost = try await client.execute(
        PostRequest.update(id: "456", title: "New Title", body: "New Body")
    )
    debugPrint("✅ Updated post: \(updatedPost.title)")
}

// MARK: - Comparison & Recommendations

/*
 ## 🎯 When to Use Each Pattern

 ### Namespace Enum ⭐️ (Recommended)

 **Use when:**
 - Different response types (User, [User], EmptyResponse)
 - Complex parameters or configurations
 - Multiple related resources (UserAPI, PostAPI, CommentAPI)

 **Advantages:**
 - ✅ Flexible - each request can have different Response type
 - ✅ Clean organization
 - ✅ Easy to extend
 - ✅ Type-safe
 - ✅ Works well with large APIs

 **Example structure:**
 ```swift
 enum UserAPI {
     struct Get: NetworkRequest { ... }      // -> User
     struct List: NetworkRequest { ... }     // -> [User]
     struct Delete: NetworkRequest { ... }   // -> EmptyResponse
 }
 ```

 ### Simple Enum

 **Use when:**
 - All operations return same type
 - Simple CRUD operations
 - Small APIs with few endpoints

 **Advantages:**
 - ✅ Concise syntax
 - ✅ Good for simple cases
 - ⚠️ All cases must return same Response type

 **Example:**
 ```swift
 enum PostRequest: NetworkRequest {
     case get(id: String)
     case list(page: Int)
 }
 ```

 ## 💡 Recommended Project Structure

 ```
 API/
 ├── UserAPI.swift
 │   └── enum UserAPI {
 │       struct Get: NetworkRequest { ... }
 │       struct List: NetworkRequest { ... }
 │       struct Create: NetworkRequest { ... }
 │   }
 ├── PostAPI.swift
 │   └── enum PostAPI { ... }
 └── CommentAPI.swift
     └── enum CommentAPI { ... }
 ```

 ## ✅ Best Practices

 1. **One file per resource** - UserAPI.swift, PostAPI.swift
 2. **Use clear names** - Get, List, Create, Update, Delete
 3. **Group by domain** - Auth, User, Post, etc.
 4. **Consistent patterns** - Use same approach across project
 5. **Path parameters** - Use templates: "/users/{id}"
 6. **Path prefixes** - Use for API versioning: "/api/v1"
 */
