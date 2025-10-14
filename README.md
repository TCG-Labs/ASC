# ASC - Alamofire Swift Client

A modern, type-safe, protocol-oriented networking library built on top of Alamofire. ASC provides a clean, declarative API for network requests with full access to Alamofire's advanced features.

[![Swift](https://img.shields.io/badge/Swift-6.2-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-iOS%2018%2B%20%7C%20macOS%2015%2B-lightgrey.svg)](https://developer.apple.com)
[![SPM](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](https://swift.org/package-manager)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

## ✨ Features

- 🎯 **Type-Safe Requests** - Protocol-oriented API with compile-time type checking
- ⚡️ **Modern Swift** - Full async/await support with Swift 6 Sendable conformance
- 🔄 **Smart Retry** - Configurable retry policies with exponential backoff
- 📤 **File Uploads** - Multipart form-data support for file uploads
- 🔌 **Interceptors** - Request/response interception for auth, logging, and more
- 📊 **Event Monitoring** - Track request lifecycle for analytics and debugging
- 🔒 **SSL Pinning** - Certificate pinning support via ServerTrustManager
- 🎨 **Clean Architecture** - Minimal wrapper, maximum Alamofire compatibility
- 🧪 **Well Tested** - 131 tests with 100% pass rate and comprehensive coverage

## 📋 Requirements

- iOS 18.0+ / macOS 15.0+
- Swift 6.2+
- Xcode 16.0+

## 📦 Installation

### Swift Package Manager

Add ASC to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/YOUR_ORG/ASC.git", from: "1.0.0")
]
```

Or add it via Xcode:
1. File → Add Package Dependencies...
2. Enter repository URL
3. Select version and add to target

## 🚀 Quick Start

### Basic Usage

```swift
import ASC

// 1. Create a client
let client = NetworkClient(baseURL: "https://api.example.com")

// 2. Define your request
struct GetUserRequest: NetworkRequest {
    typealias Response = User

    let userId: String

    var path: String { "/users/\(userId)" }
    var method: HTTPMethod { .get }
}

// 3. Execute
let user = try await client.execute(GetUserRequest(userId: "123"))
print(user.name)
```

### POST Request with JSON Body

```swift
struct CreatePostRequest: NetworkRequest {
    typealias Response = Post

    let title: String
    let content: String

    var path: String { "/posts" }
    var method: HTTPMethod { .post }
    var parameters: Parameters? {
        [
            "title": title,
            "content": content,
        ]
    }
}

let post = try await client.execute(
    CreatePostRequest(title: "Hello", content: "World!")
)
```

### URL Encoding (Query Parameters)

```swift
struct SearchRequest: NetworkRequest {
    typealias Response = [SearchResult]

    let query: String
    let limit: Int

    var path: String { "/search" }
    var method: HTTPMethod { .get }
    var parameters: Parameters? {
        ["q": query, "limit": limit]
    }
    var parameterEncoding: any ParameterEncoding {
        URLEncoding.default  // Encodes as query string
    }
}

let results = try await client.execute(
    SearchRequest(query: "swift", limit: 10)
)
```

## 🎯 Advanced Features

### Path Parameters

Use path templates with automatic substitution:

```swift
struct GetUserPostRequest: NetworkRequest {
    typealias Response = Post

    let userId: String
    let postId: String

    var path: String { "/users/{userId}/posts/{postId}" }
    var method: HTTPMethod { .get }
    var pathParameters: [String: String]? {
        ["userId": userId, "postId": postId]
    }
}

// Actual URL: https://api.example.com/users/123/posts/456
let post = try await client.execute(
    GetUserPostRequest(userId: "123", postId: "456")
)
```

### API Versioning with Path Prefix

```swift
struct GetUserRequestV1: NetworkRequest {
    typealias Response = User

    let userId: String

    var pathPrefix: String? { "/api/v1" }
    var path: String { "/users/{userId}" }
    var method: HTTPMethod { .get }
    var pathParameters: [String: String]? {
        ["userId": userId]
    }
}

// Actual URL: https://api.example.com/api/v1/users/123
let user = try await client.execute(GetUserRequestV1(userId: "123"))
```

### File Upload (Multipart Form-Data)

```swift
struct UploadAvatarRequest: NetworkRequest {
    typealias Response = User

    let userId: String
    let imageData: Data

    var path: String { "/users/{userId}/avatar" }
    var method: HTTPMethod { .post }
    var pathParameters: [String: String]? {
        ["userId": userId]
    }
    var files: [String: Data]? {
        ["avatar": imageData]
    }
}

let imageData = UIImage(named: "avatar")?.jpegData(compressionQuality: 0.8)
let user = try await client.execute(
    UploadAvatarRequest(userId: "123", imageData: imageData!)
)
```

### Request Interceptor (Authentication)

```swift
import Alamofire

final class AuthInterceptor: RequestInterceptor {
    func adapt(
        _ urlRequest: URLRequest,
        for session: Session,
        completion: @escaping (Result<URLRequest, Error>) -> Void
    ) {
        var urlRequest = urlRequest
        urlRequest.headers.add(.authorization(bearerToken: getToken()))
        completion(.success(urlRequest))
    }

    func retry(
        _ request: Request,
        for session: Session,
        dueTo error: Error,
        completion: @escaping (RetryResult) -> Void
    ) {
        if let response = request.task?.response as? HTTPURLResponse,
           response.statusCode == 401 {
            refreshToken { success in
                completion(success ? .retry : .doNotRetry)
            }
        } else {
            completion(.doNotRetry)
        }
    }
}

// Configure client with interceptor
let config = NetworkClientConfiguration(
    baseURL: "https://api.example.com",
    interceptors: [AuthInterceptor()]
)
let client = NetworkClient(configuration: config)
```

### Event Monitoring (Logging)

```swift
final class Logger: EventMonitor {
    func requestDidResume(_ request: Request) {
        print("🚀 Request started: \(request.description)")
    }

    func request<Value>(
        _ request: DataRequest,
        didParseResponse response: DataResponse<Value, AFError>
    ) {
        print("✅ Response: \(response.response?.statusCode ?? 0)")
    }
}

let config = NetworkClientConfiguration(
    baseURL: "https://api.example.com",
    eventMonitors: [Logger()]
)
let client = NetworkClient(configuration: config)
```

### Advanced Configuration

```swift
let config = NetworkClientConfiguration(
    baseURL: "https://api.example.com",

    // Default headers for all requests
    defaultHeaders: [
        "X-App-Version": "1.0.0",
        "Accept-Language": "en-US",
    ],

    // Request interceptors (auth, signing, etc.)
    interceptors: [AuthInterceptor()],

    // Event monitors (logging, analytics)
    eventMonitors: [Logger(), AnalyticsMonitor()],

    // SSL certificate pinning
    serverTrustManager: ServerTrustManager(
        evaluators: ["api.example.com": DefaultTrustEvaluator()]
    ),

    // Custom timeout
    defaultTimeout: 30.0,

    // Cache policy
    defaultCachePolicy: .reloadIgnoringLocalCacheData,

    // Custom dispatch queues
    rootQueue: DispatchQueue(label: "com.app.network.root"),
    requestQueue: DispatchQueue(label: "com.app.network.request"),
    serializationQueue: DispatchQueue(label: "com.app.network.serialization")
)

let client = NetworkClient(configuration: config)
```

### Retry Policy

```swift
// Use predefined policies
struct MyRequest: NetworkRequest {
    // ...
    var retryPolicy: RetryPolicy { .aggressive }  // 5 retries with 2s delay
}

// Or create custom policy
let customPolicy = RetryPolicy(
    maxRetries: 3,
    retryDelay: 1.0,
    exponentialBackoff: true,
    retryableStatusCodes: [408, 429, 500, 502, 503],
    retryOnNetworkError: true
)
```

### Empty Response (204 No Content)

```swift
struct DeleteUserRequest: NetworkRequest {
    typealias Response = ASCEmptyResponse  // or EmptyResponse

    let userId: String

    var path: String { "/users/\(userId)" }
    var method: HTTPMethod { .delete }
}

// No return value for empty responses
try await client.execute(DeleteUserRequest(userId: "123"))
```

## 🔧 Error Handling

ASC provides three types of structured errors:

### NetworkError

Connection and transport-level errors:

```swift
do {
    let user = try await client.execute(request)
} catch let error as NetworkError {
    switch error {
    case .noConnection:
        print("No internet connection")
    case .timeout(let duration):
        print("Request timed out after \(duration)s")
    case .hostUnreachable(let host):
        print("Cannot reach \(host)")
    case .certificateValidationFailed(let reason):
        print("SSL error: \(reason)")
    case .cancelled:
        print("Request was cancelled")
    case .networkFailure(let underlying):
        print("Network error: \(underlying)")
    }
}
```

### ResponseError

HTTP response and parsing errors:

```swift
do {
    let user = try await client.execute(request)
} catch let error as ResponseError {
    switch error {
    case .invalidStatusCode(let code, let data):
        print("Invalid status: \(code)")
    case .decodingFailed(let error, let data):
        print("Failed to parse: \(error)")
    case .missingData:
        print("No response data")
    case .serverError(let code, let message):
        print("Server error \(code): \(message)")
    case .clientError(let code, let message):
        print("Client error \(code): \(message ?? "")")
    default:
        print("Response error: \(error)")
    }
}
```

### AuthenticationError

Authentication and authorization errors:

```swift
do {
    let user = try await client.execute(request)
} catch let error as AuthenticationError {
    switch error {
    case .notAuthenticated:
        print("Please log in")
    case .tokenExpired:
        print("Session expired, please log in again")
    case .unauthorized(let resource):
        print("No access to \(resource ?? "resource")")
    case .forbidden(let reason):
        print("Forbidden: \(reason ?? "")")
    default:
        print("Auth error: \(error)")
    }
}
```

## 💡 Best Practices

### Request Organization

Use enums to organize related requests:

```swift
enum UserAPI {
    case getUser(id: String)
    case updateUser(id: String, name: String)
    case deleteUser(id: String)
}

extension UserAPI: NetworkRequest {
    typealias Response = User

    var path: String {
        switch self {
        case .getUser(let id):
            return "/users/\(id)"
        case .updateUser(let id, _):
            return "/users/\(id)"
        case .deleteUser(let id):
            return "/users/\(id)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .getUser:
            return .get
        case .updateUser:
            return .put
        case .deleteUser:
            return .delete
        }
    }

    var parameters: Parameters? {
        switch self {
        case .updateUser(_, let name):
            return ["name": name]
        default:
            return nil
        }
    }
}

// Usage
let user = try await client.execute(UserAPI.getUser(id: "123"))
```

### Client Configuration Management

Create a single configured client for your app:

```swift
// NetworkClientFactory.swift
final class NetworkClientFactory {
    static let shared = NetworkClientFactory()

    private(set) lazy var client: NetworkClient = {
        let config = NetworkClientConfiguration(
            baseURL: Configuration.apiBaseURL,
            defaultHeaders: [
                "X-App-Version": Bundle.main.appVersion,
                "Accept-Language": Locale.current.languageCode ?? "en"
            ],
            interceptors: [AuthInterceptor.shared],
            eventMonitors: [NetworkLogger.shared],
            defaultTimeout: 30.0
        )
        return NetworkClient(configuration: config)
    }()

    private init() {}
}

// Usage throughout app
let user = try await NetworkClientFactory.shared.client.execute(request)
```

### Error Handling Strategy

Handle errors at appropriate levels:

```swift
// Repository level - transform to domain errors
class UserRepository {
    func getUser(id: String) async throws -> User {
        do {
            return try await client.execute(UserAPI.getUser(id: id))
        } catch let error as NetworkError {
            throw DomainError.connectionFailed(reason: error.localizedDescription)
        } catch let error as ResponseError {
            switch error {
            case .invalidStatusCode(404, _):
                throw DomainError.userNotFound(id: id)
            case .serverError(let code, _):
                throw DomainError.serverUnavailable(code: code)
            default:
                throw DomainError.unknown(error)
            }
        }
    }
}

// ViewModel level - prepare user-facing messages
class UserViewModel {
    func loadUser(id: String) async {
        do {
            self.user = try await repository.getUser(id: id)
        } catch let error as DomainError {
            self.errorMessage = error.userFacingMessage
        }
    }
}
```

### File Upload Patterns

Choose the right upload method based on file size:

```swift
// Small files (< 10MB) - use FileUpload with MIME types
struct UploadPhotoRequest: NetworkRequest {
    typealias Response = Photo
    let imageData: Data

    var path: String { "/photos" }
    var method: HTTPMethod { .post }
    var fileUploads: [String: FileUpload]? {
        [
            "photo": .jpeg(data: imageData, fileName: "photo.jpg")
        ]
    }
}

// Large files (> 10MB) - use LargeFileUpload with file URLs
struct UploadVideoRequest: NetworkRequest {
    typealias Response = Video
    let videoURL: URL

    var path: String { "/videos" }
    var method: HTTPMethod { .post }
    var largeFileUploads: [LargeFileUpload]? {
        [
            LargeFileUpload(
                fileURL: videoURL,
                fieldName: "video",
                fileName: "video.mp4",
                mimeType: "video/mp4"
            )
        ]
    }
}

// Multiple files with metadata
struct UploadDocumentsRequest: NetworkRequest {
    typealias Response = UploadResult
    let files: [URL]
    let category: String

    var path: String { "/documents" }
    var method: HTTPMethod { .post }
    var largeFileUploads: [LargeFileUpload]? {
        files.map { url in
            LargeFileUpload(
                fileURL: url,
                fieldName: "documents[]",  // Note: array syntax
                fileName: url.lastPathComponent
            )
        }
    }
    var parameters: Parameters? {
        ["category": category, "count": files.count]
    }
}
```

### Retry Policy Selection

Choose retry policies based on request importance:

```swift
// Critical requests - aggressive retry
struct PaymentRequest: NetworkRequest {
    // ...
    var retryPolicy: Alamofire.RetryPolicy? { .aggressive }  // 5 retries
}

// Standard requests - default retry
struct GetFeedRequest: NetworkRequest {
    // ...
    var retryPolicy: Alamofire.RetryPolicy? { .default }  // 3 retries
}

// Non-critical requests - conservative retry
struct LogAnalyticsRequest: NetworkRequest {
    // ...
    var retryPolicy: Alamofire.RetryPolicy? { .conservative }  // 2 retries
}

// Real-time requests - no retry
struct SearchRequest: NetworkRequest {
    // ...
    var retryPolicy: Alamofire.RetryPolicy? { .none }  // No retries
}
```

### Security Considerations

Protect sensitive data in requests:

```swift
// 1. Don't log sensitive data
final class SecureLogger: EventMonitor {
    let sensitiveHeaders = ["Authorization", "X-API-Key", "Cookie"]

    func request<Value>(
        _ request: DataRequest,
        didParseResponse response: DataResponse<Value, AFError>
    ) {
        var headers = request.request?.allHTTPHeaderFields ?? [:]
        // Redact sensitive headers
        for header in sensitiveHeaders {
            if headers[header] != nil {
                headers[header] = "[REDACTED]"
            }
        }
        debugPrint("Response:", response.response?.statusCode ?? 0, "Headers:", headers)
    }
}

// 2. Use HTTPS only in production
let config = NetworkClientConfiguration(
    baseURL: Configuration.isProduction ? "https://api.example.com" : "http://localhost:3000"
)

// 3. Implement certificate pinning for production
let trustManager = ServerTrustManager(
    evaluators: ["api.example.com": PinnedCertificatesTrustEvaluator()]
)
```

### Testing Your Network Layer

Mock network calls in tests:

```swift
import Testing
@testable import YourApp
@testable import ASC

@Suite("User Repository Tests")
struct UserRepositoryTests {
    @Test("Repository returns user on success")
    func testGetUserSuccess() async throws {
        // Setup
        let mockUser = User(id: "123", name: "John")
        MockURLProtocol.requestHandler = MockResponseBuilder.success(mockUser).handler()

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let client = NetworkClient(
            configuration: NetworkClientConfiguration(
                baseURL: "https://test.com",
                session: Session(configuration: config)
            )
        )

        let repository = UserRepository(client: client)

        // Execute
        let user = try await repository.getUser(id: "123")

        // Verify
        #expect(user.id == "123")
        #expect(user.name == "John")
    }

    @Test("Repository throws domain error on 404")
    func testGetUserNotFound() async throws {
        // Setup
        MockURLProtocol.requestHandler = MockResponseBuilder.notFound().handler()

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let client = NetworkClient(
            configuration: NetworkClientConfiguration(
                baseURL: "https://test.com",
                session: Session(configuration: config)
            )
        )

        let repository = UserRepository(client: client)

        // Execute & Verify
        do {
            _ = try await repository.getUser(id: "999")
            Issue.record("Expected error to be thrown")
        } catch let error as DomainError {
            #expect(error == .userNotFound(id: "999"))
        }
    }
}
```

### Performance Optimization

Optimize based on usage patterns:

```swift
// 1. Reuse client instance (don't create new clients)
// ✅ Good
class APIService {
    private let client = NetworkClientFactory.shared.client
    func fetchData() async throws { /* ... */ }
}

// ❌ Bad - creates new session each time
class APIService {
    func fetchData() async throws {
        let client = NetworkClient(baseURL: "...")  // Don't do this
    }
}

// 2. Use appropriate cache policy
struct GetCachedDataRequest: NetworkRequest {
    // ...
    var cachePolicy: URLRequest.CachePolicy? {
        .returnCacheDataElseLoad  // Use cache when available
    }
}

// 3. Batch requests when possible
func loadUserDashboard(userId: String) async throws {
    async let user = client.execute(UserAPI.getUser(id: userId))
    async let posts = client.execute(PostAPI.getUserPosts(userId: userId))
    async let stats = client.execute(StatsAPI.getUserStats(userId: userId))

    // All requests execute in parallel
    let (userData, postsData, statsData) = try await (user, posts, stats)
}

// 4. Use streaming for large responses (if backend supports)
struct DownloadLargeFileRequest: NetworkRequest {
    typealias Response = Data
    // ...
    var timeout: TimeInterval? { 300 }  // 5 minutes for large downloads
}
```

## 📄 License

ASC is available under the MIT license. See LICENSE file for details.
