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

## 🔍 Logging

ASC includes built-in logging using Apple's unified logging system (os.log).

### Log Levels

Configure logging when creating a NetworkClient:

```swift
let config = NetworkClientConfiguration(
    baseURL: "https://api.example.com",
    logLevel: .verbose  // Choose your log level
)
let client = NetworkClient(configuration: config)
```

**Available levels:**

- `.none` - No logging (default)
- `.error` - Errors only
- `.info` - Requests and responses (URLs, status codes, timing)
- `.debug` - Info + HTTP headers
- `.verbose` - Debug + request/response bodies (JSON pretty-printed)

### Example Output

With `.verbose` logging enabled, you'll see in Xcode Console:

```
→ 📤 POST https://api.example.com/v1/auth/login
  📋 Headers:
    Content-Type: application/json
  📦 Body (JSON):
{
  "email" : "user@example.com",
  "password" : "🔒 <redacted>"
}
← ✅ 200 https://api.example.com/v1/auth/login ⚡ 0.23s
  📄 Response (JSON):
{
  "accessToken" : "eyJhbG...",
  "refreshToken" : "eyJhbG..."
}
```

**Features:**
- 🎨 Emoji indicators for methods, status codes, and timing
- 🔒 Automatic redaction of sensitive headers (Authorization, API keys, cookies)
- 📊 Request duration with performance emojis (⚡ fast, 🐢 slow)
- 🎯 Pretty-printed JSON for easy reading

### Viewing Logs in Xcode

- Logs appear in real-time with emoji prefixes
- Filter by subsystem: `com.asc.networking`

## 📚 Examples

All runnable examples are located in the [`Examples/`](ASC/Examples/) directory.

### [QuickStart.swift](ASC/Examples/QuickStart.swift) - 51 lines
Minimal example to get started in 5 minutes.

**What you'll learn:**
- Define models and requests
- Execute GET and POST requests
- Use Namespace Enum pattern

**Run:**
```swift
Task { try await quickStart() }
```

---

### [JSONPlaceholderExample.swift](ASC/Examples/JSONPlaceholderExample.swift) - 121 lines
Complete CRUD operations with real API (JSONPlaceholder).

**What you'll learn:**
- GET requests
- POST with body parameters
- PUT to update resources
- DELETE with empty response
- Nested paths (`/posts/{id}/comments`)
- Error handling

**Run:**
```swift
Task { try await runBasicExamples() }
```

---

### [AdvancedExample.swift](ASC/Examples/AdvancedExample.swift) - 153 lines
Production-ready patterns for authentication and monitoring.

**What you'll learn:**
- Custom `RequestInterceptor` for authentication
- Automatic token refresh on 401
- Custom `EventMonitor` for performance tracking
- Advanced configuration with interceptors and monitors
- Retry policies per request
- Custom timeouts

**Run:**
```swift
Task { try await runAdvancedExamples() }
```

---

### [FileUploadExample.swift](ASC/Examples/FileUploadExample.swift) - 126 lines
All three methods of uploading files.

**What you'll learn:**
- Simple uploads with `files`
- Custom MIME types with `fileUploads`
- Memory-efficient uploads with `largeFileUploads` (for files > 10MB)
- Upload with metadata
- Real uploads to httpbin.org

**Run:**
```swift
Task { try await runFileUploadExamples() }
```

---

### [EnumRequestExample.swift](ASC/Examples/EnumRequestExample.swift) - 114 lines
Two ways to organize your API requests.

**What you'll learn:**
- **Namespace Enum** (recommended) - For different response types
- **Simple Enum** - For same response type
- When to use each pattern
- URL encoding

**Run:**
```swift
Task { try await demonstratePatterns() }
```

## 🎯 Advanced Features

### File Upload (Multipart Form-Data)

```swift
struct UploadAvatarRequest: NetworkRequest {
    typealias Response = User

    let userId: String
    let imageData: Data

    var path: String { "/users/\(userId)/avatar" }
    var method: HTTPMethod { .post }
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

ASC provides built-in authentication support through two key components:

- **`TokenStorage`** - Protocol for storing and managing authentication tokens (bearer, basic, custom)
- **`AuthInterceptor`** - Request interceptor that automatically adds `Authorization` headers to requests

When a request is marked with `enableAuthorization = true`, the interceptor retrieves the token from storage and adds the appropriate authentication header before sending the request.

**Usage:**

1. Implement the `TokenStorage` protocol to define how tokens are stored
2. Create an `AuthInterceptor` instance with your token storage
3. Add the interceptor to `NetworkClientConfiguration`
4. Mark requests that need authentication with `enableAuthorization = true`

#### Bearer Token Authentication (API Keys, OAuth)

Most common for REST APIs and OAuth 2.0:

```swift
import ASC

// 1. Implement TokenStorage protocol
final class BearerTokenStorage: TokenStorage {
    private var token: String?
    
    var authToken: AuthToken? {
        guard let token = token else { return nil }
        return .bearer(token: token)
    }
    
    init(token: String) {
        self.token = token
    }
    
    func updateToken(_ newToken: String) {
        self.token = newToken
    }
    
    func flush() {
        token = nil
    }
}

// 2. Configure client with AuthInterceptor
let storage = BearerTokenStorage(token: "your-api-key")
let authInterceptor = AuthInterceptor(storage: storage)

let config = NetworkClientConfiguration(
    baseURL: "https://api.example.com",
    interceptors: [authInterceptor]
)
let client = NetworkClient(configuration: config)

// 3. Mark requests that need authentication
struct GetProfileRequest: NetworkRequest {
    typealias Response = UserProfile
    
    var path: String { "/me" }
    var method: HTTPMethod { .get }
    var enableAuthorization: Bool { true }  // Adds Authorization header
}

let profile = try await client.execute(GetProfileRequest())
// Request includes: Authorization: Bearer your-api-key
```

For advanced scenarios (custom retry logic, token refresh), implement Alamofire's `RequestInterceptor` directly:

```swift
import Alamofire

final class CustomAuthInterceptor: RequestInterceptor {
    private var token: String
    
    init(token: String) {
        self.token = token
    }
    
    func adapt(
        _ urlRequest: URLRequest,
        for session: Session,
        completion: @escaping (Result<URLRequest, Error>) -> Void
    ) {
        var urlRequest = urlRequest
        urlRequest.headers.add(.authorization(bearerToken: token))
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
            // Refresh token and retry
            Task {
                do {
                    self.token = try await refreshToken()
                    completion(.retry)
                } catch {
                    completion(.doNotRetry)
                }
            }
        } else {
            completion(.doNotRetry)
        }
    }
    
    private func refreshToken() async throws -> String {
        // Implement token refresh logic
        return "new-token"
    }
}
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
    var retryPolicy: Alamofire.RetryPolicy? { .aggressive }  // 5 retries with exponential backoff
}

// Or create custom policy using Alamofire's RetryPolicy
let customPolicy = Alamofire.RetryPolicy(
    retryLimit: 3,
    exponentialBackoffBase: 2,
    exponentialBackoffScale: 0.5
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
