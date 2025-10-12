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
- 🧪 **Well Tested** - 65+ tests with 100% coverage of public API

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

## 📚 Architecture

ASC uses a clean, layered architecture:

```
┌─────────────────────────────────────┐
│      NetworkRequest Protocol        │  ← Type-safe request definition
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│         NetworkClient               │  ← Main client interface
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│      Alamofire Session              │  ← Alamofire integration
│  + Interceptors + Monitors          │
└─────────────────────────────────────┘
```

**Core Components:**

- **NetworkRequest** - Protocol defining request configuration
- **NetworkClient** - Main client executing requests
- **NetworkClientConfiguration** - Advanced configuration
- **ErrorMapper** - Transforms Alamofire errors to ASC errors
- **URLBuilder** - Builds URLs with path parameters
- **MultipartRequestBuilder** - Handles file uploads

**Re-exported Alamofire Types:**

ASC re-exports key Alamofire types for convenience:
- `HTTPHeaders`, `HTTPMethod`, `Parameters`
- `RequestInterceptor`, `EventMonitor`
- `ServerTrustManager`, `RedirectHandler`
- And more...

This allows full access to Alamofire's power while maintaining a simpler API.

## 🧪 Testing

ASC includes comprehensive test coverage with 65+ tests:

```bash
# Run all tests
swift test

# Run specific test
swift test --filter ASCTests.testNetworkClientExecutesGET

# Run with coverage
swift test --enable-code-coverage
```

**Test Helpers:**

ASC provides mock utilities for testing your network layer:

```swift
import ASCTests

// Mock URL responses
MockURLProtocol.requestHandler = { request in
    let response = MockResponse.success(user).build(url: request.url!)
    return response
}

// Use with URLSession
let config = URLSessionConfiguration.ephemeral
config.protocolClasses = [MockURLProtocol.self]
```

## 🎨 Code Quality

ASC maintains high code quality standards:

- ✅ **SwiftLint** - Strict linting rules enforced
- ✅ **Zero Warnings** - Clean codebase
- ✅ **Documentation** - 100% coverage of public API
- ✅ **Tests** - 65+ tests, 100% pass rate
- ✅ **Swift 6** - Full Sendable conformance

```bash
# Run linter
swiftlint

# Auto-fix issues
swiftlint --fix
```

## 📖 Documentation

Full documentation is available in the code via DocC:

- All public types are documented
- Usage examples in doc comments
- See `CLAUDE.md` for architecture details

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes with tests
4. Ensure SwiftLint passes
5. Submit a pull request

## 📄 License

ASC is available under the MIT license. See LICENSE file for details.
