// EnumRequestExample.swift
// ASC - Enum-based NetworkRequest Example
//
// Demonstrates different approaches to using enums for NetworkRequest
// to group related API calls together.

import ASC
import Foundation

// MARK: - Approach 1: Simple Enum (Single Response Type)

/// Best for: CRUD operations on a single resource type
/// Limitation: All cases must return the same Response type
enum UserRequest: NetworkRequest {
    typealias Response = User

    case get(userId: String)
    case list(page: Int, limit: Int)
    case create(name: String, email: String)
    case update(userId: String, name: String, email: String)
    case delete(userId: String)

    var path: String {
        switch self {
        case .get, .update, .delete:
            return "/users/{id}"
        case .list, .create:
            return "/users"
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
        case .delete:
            return .delete
        }
    }

    var pathParameters: [String: String]? {
        switch self {
        case .get(let userId), .update(let userId, _, _), .delete(let userId):
            return ["id": userId]
        default:
            return nil
        }
    }

    var parameters: Parameters? {
        switch self {
        case .list(let page, let limit):
            return ["page": page, "limit": limit]
        case .create(let name, let email):
            return ["name": name, "email": email]
        case .update(_, let name, let email):
            return ["name": name, "email": email]
        default:
            return nil
        }
    }

    var parameterEncoding: any ParameterEncoding {
        switch self {
        case .get, .list:
            return URLEncoding.default  // Query parameters
        case .create, .update:
            return JSONEncoding.default  // JSON body
        case .delete:
            return URLEncoding.default
        }
    }
}

// MARK: - Approach 2: Enum for Empty Response Operations

/// Best for: Operations that return 204 No Content
/// All cases perform actions without returning data
enum UserActionRequest: NetworkRequest {
    typealias Response = ASCEmptyResponse

    case delete(userId: String)
    case activate(userId: String)
    case deactivate(userId: String)
    case resetPassword(userId: String)

    var path: String {
        switch self {
        case .delete:
            return "/users/{id}"
        case .activate:
            return "/users/{id}/activate"
        case .deactivate:
            return "/users/{id}/deactivate"
        case .resetPassword:
            return "/users/{id}/reset-password"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .delete:
            return .delete
        case .activate, .deactivate, .resetPassword:
            return .post
        }
    }

    var pathParameters: [String: String]? {
        let userId: String
        switch self {
        case .delete(let id), .activate(let id), .deactivate(let id), .resetPassword(let id):
            userId = id
        }
        return ["id": userId]
    }
}

// MARK: - Approach 3: Namespace Enum + Nested Structs (Most Flexible)

/// Best for: Complex APIs with different response types
/// Provides grouping without enum constraints
enum PostAPI {
    // GET /posts/:id -> Post
    struct Get: NetworkRequest {
        typealias Response = Post
        let postId: String

        var path: String { "/posts/{id}" }
        var method: HTTPMethod { .get }
        var pathParameters: [String: String]? { ["id": postId] }
    }

    // GET /posts -> [Post]
    struct List: NetworkRequest {
        typealias Response = [Post]
        let page: Int
        let limit: Int

        var path: String { "/posts" }
        var method: HTTPMethod { .get }
        var parameters: Parameters? { ["page": page, "limit": limit] }
        var parameterEncoding: any ParameterEncoding { URLEncoding.default }
    }

    // POST /posts -> Post
    struct Create: NetworkRequest {
        typealias Response = Post
        let title: String
        let body: String
        let authorId: String

        var path: String { "/posts" }
        var method: HTTPMethod { .post }
        var parameters: Parameters? {
            ["title": title, "body": body, "authorId": authorId]
        }
    }

    // GET /posts/:id/comments -> [Comment]
    struct GetComments: NetworkRequest {
        typealias Response = [Comment]
        let postId: String

        var path: String { "/posts/{id}/comments" }
        var method: HTTPMethod { .get }
        var pathParameters: [String: String]? { ["id": postId] }
    }
}

// MARK: - Approach 4: Protocol + Enum (Advanced)

/// Protocol for common request properties
protocol UserAPIRequest: NetworkRequest where Response == User {
    var userId: String? { get }
}

extension UserAPIRequest {
    var pathPrefix: String? { "/api/v1" }

    var headers: HTTPHeaders? {
        HTTPHeaders([.accept("application/json")])
    }
}

/// Enum implementing the protocol
enum UserAPIEnum: UserAPIRequest {
    typealias Response = User

    case get(userId: String)
    case update(userId: String, name: String)

    var userId: String? {
        switch self {
        case .get(let id), .update(let id, _):
            return id
        }
    }

    var path: String {
        "/users/{id}"
    }

    var method: HTTPMethod {
        switch self {
        case .get:
            return .get
        case .update:
            return .put
        }
    }

    var pathParameters: [String: String]? {
        guard let userId = userId else { return nil }
        return ["id": userId]
    }

    var parameters: Parameters? {
        switch self {
        case .update(_, let name):
            return ["name": name]
        default:
            return nil
        }
    }
}

// MARK: - Supporting Models

struct User: Codable, Sendable {
    let id: String
    let name: String
    let email: String?
}

struct Post: Codable, Sendable {
    let id: String
    let title: String
    let body: String
    let authorId: String
}

struct Comment: Codable, Sendable {
    let id: String
    let postId: String
    let author: String
    let text: String
}

// MARK: - Usage Examples

@MainActor
func demonstrateEnumRequests() async throws {
    let client = NetworkClient(baseURL: "https://api.example.com")

    debugPrint("=== Approach 1: Simple Enum ===")

    // Very clean and concise usage
    let user = try await client.execute(UserRequest.get(userId: "123"))
    debugPrint("✅ Got user: \(user.name)")

    let users = try await client.execute(UserRequest.list(page: 1, limit: 10))
    debugPrint("✅ Got \(users.count) users")

    let newUser = try await client.execute(
        UserRequest.create(name: "John", email: "john@example.com")
    )
    debugPrint("✅ Created user: \(newUser.id)")

    try await client.execute(UserRequest.delete(userId: "123"))
    debugPrint("✅ Deleted user")

    debugPrint("\n=== Approach 2: Empty Response Enum ===")

    try await client.execute(UserActionRequest.activate(userId: "123"))
    debugPrint("✅ User activated")

    try await client.execute(UserActionRequest.resetPassword(userId: "123"))
    debugPrint("✅ Password reset")

    debugPrint("\n=== Approach 3: Namespace + Structs ===")

    let post = try await client.execute(PostAPI.Get(postId: "456"))
    debugPrint("✅ Got post: \(post.title)")

    let posts = try await client.execute(PostAPI.List(page: 1, limit: 5))
    debugPrint("✅ Got \(posts.count) posts")

    let comments = try await client.execute(PostAPI.GetComments(postId: "456"))
    debugPrint("✅ Got \(comments.count) comments")

    debugPrint("\n=== Approach 4: Protocol + Enum ===")

    let userWithProtocol = try await client.execute(UserAPIEnum.get(userId: "789"))
    debugPrint("✅ Got user via protocol enum: \(userWithProtocol.name)")
}

// MARK: - Comparison & Recommendations

/*
 # Enum vs Struct для NetworkRequest

 ## ✅ Когда использовать ENUM:

 1. **CRUD операции на одном ресурсе**
    - Все запросы возвращают один тип (User, Post, etc.)
    - Логически связанные операции
    - Пример: UserRequest.get, .create, .update, .delete

 2. **Операции без возвращаемых данных**
    - Все возвращают ASCEmptyResponse
    - Пример: UserActionRequest (activate, deactivate, delete)

 3. **Группировка по функциональности**
    - Authentication: .login, .logout, .refreshToken
    - Payment: .charge, .refund, .checkStatus

 ## ✅ Когда использовать STRUCT:

 1. **Разные типы ответов**
    - GET /user/:id -> User
    - GET /user/:id/posts -> [Post]
    - Нужны разные Response типы

 2. **Сложные параметры**
    - Много параметров с default значениями
    - Опциональные параметры
    - Конфигурация через инициализатор

 3. **Независимые запросы**
    - Не связаны логически
    - Разовые специфичные запросы

 ## 🎯 Рекомендуемый подход: NAMESPACE ENUM

 Лучшее из обоих миров:

 ```swift
 enum UserAPI {
     struct Get: NetworkRequest { ... }      // -> User
     struct List: NetworkRequest { ... }     // -> [User]
     struct Create: NetworkRequest { ... }   // -> User
     struct Delete: NetworkRequest { ... }   // -> EmptyResponse
 }

 // Использование:
 let user = try await client.execute(UserAPI.Get(userId: "123"))
 let users = try await client.execute(UserAPI.List(page: 1))
 ```

 **Преимущества:**
 - ✅ Группировка по модулям/ресурсам
 - ✅ Разные Response типы
 - ✅ Легко расширять
 - ✅ Чистый namespace
 - ✅ Нет ограничений enum

 ## 📊 Сравнение подходов

 | Критерий              | Простой Enum | Namespace Enum | Struct |
 |----------------------|--------------|----------------|--------|
 | Группировка          | ✅ Отлично   | ✅ Отлично     | ❌     |
 | Разные Response типы | ❌           | ✅ Да          | ✅ Да  |
 | Краткость кода       | ✅ Очень     | ✅ Хорошо      | ⚠️ Средне |
 | Гибкость             | ⚠️ Средняя   | ✅ Высокая     | ✅ Высокая |
 | Читаемость           | ✅ Хорошо    | ✅ Отлично     | ✅ Хорошо |
 | Простота             | ✅ Просто    | ✅ Просто      | ✅ Просто |

 ## 💡 Практические советы

 1. **Для простых API** - используйте простой enum:
    ```swift
    enum TodoRequest: NetworkRequest { ... }
    ```

 2. **Для сложных API** - используйте namespace enum:
    ```swift
    enum UserAPI {
        struct Get: NetworkRequest { ... }
        struct List: NetworkRequest { ... }
    }
    enum PostAPI { ... }
    enum CommentAPI { ... }
    ```

 3. **Комбинируйте подходы**:
    ```swift
    enum API {
        enum User: NetworkRequest { ... }  // Simple enum
        enum Post {                         // Namespace
            struct Get: NetworkRequest { ... }
            struct List: NetworkRequest { ... }
        }
    }
    ```

 4. **Используйте протоколы для общей логики**:
    ```swift
    protocol AuthenticatedRequest: NetworkRequest {
        var authToken: String { get }
    }

    extension AuthenticatedRequest {
        var headers: HTTPHeaders? {
            HTTPHeaders([.authorization(bearerToken: authToken)])
        }
    }
    ```

 ## 🎨 Рекомендуемая структура проекта

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
 ├── AuthAPI.swift
 │   └── enum AuthRequest: NetworkRequest {
 │       case login(email: String, password: String)
 │       case logout
 │       case refreshToken(token: String)
 │   }
 └── Protocols/
     ├── AuthenticatedRequest.swift
     └── PaginatedRequest.swift
 ```
 */
