# ASC - Alamofire Swift Client

[![CI](https://github.com/YOUR_USERNAME/ASC/actions/workflows/ci.yml/badge.svg)](https://github.com/YOUR_USERNAME/ASC/actions/workflows/ci.yml)
[![Release](https://github.com/YOUR_USERNAME/ASC/actions/workflows/release.yml/badge.svg)](https://github.com/YOUR_USERNAME/ASC/actions/workflows/release.yml)
[![Swift](https://img.shields.io/badge/Swift-6.2-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-iOS%2018%2B%20%7C%20macOS%2015%2B-lightgrey.svg)](https://developer.apple.com)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

A modern, type-safe Swift networking library built on top of Alamofire. ASC provides a clean, protocol-oriented API for making network requests with full access to Alamofire's advanced features.

## ✨ Features

- 🎯 **Type-Safe API** - Protocol-oriented design with generic responses
- 🚀 **Async/Await** - Native Swift concurrency support
- 📦 **Codable Integration** - Automatic JSON encoding/decoding
- 🔄 **Retry Policies** - Configurable retry logic with exponential backoff
- 📤 **File Uploads** - Multipart form data with progress tracking
- 🔐 **Request Interceptors** - Authentication, logging, and custom modifications
- 📊 **Event Monitors** - Request lifecycle tracking and analytics
- ⚡ **Concurrent Requests** - Efficient parallel request handling
- 🛡️ **Comprehensive Error Handling** - Structured error types with recovery suggestions
- 🎨 **Clean Architecture** - Minimal boilerplate, maximum clarity

## 📋 Requirements

- iOS 18.0+ / macOS 15.0+
- Swift 6.2+
- Xcode 16.0+

## 📦 Installation

### Swift Package Manager

Add ASC to your project using Xcode:

1. File → Add Package Dependencies
2. Enter the repository URL:
   ```
   https://github.com/YOUR_USERNAME/ASC.git
   ```
3. Select version and add to your target

Or add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/YOUR_USERNAME/ASC.git", from: "1.0.0")
]
```

## 🚀 Quick Start

### 1. Define Your Model

```swift
struct Post: Codable, Sendable {
    let id: Int
    let title: String
    let body: String
}
```

### 2. Create a Network Request

```swift
struct GetPostsRequest: NetworkRequest {
    typealias Response = [Post]

    var path: String { "/posts" }
    var method: HTTPMethod { .get }
}
```

### 3. Execute the Request

```swift
let client = NetworkClient(baseURL: "https://api.example.com")

// Fetch posts
let posts = try await client.execute(GetPostsRequest())

// That's it! 🎉
```

## 📚 Examples

Check out the [Examples](Examples/) directory for comprehensive usage examples:

- **[QuickStart.swift](Examples/QuickStart.swift)** - Get started in 5 minutes
- **[JSONPlaceholderExample.swift](Examples/JSONPlaceholderExample.swift)** - Complete API integration
- **[AdvancedExample.swift](Examples/AdvancedExample.swift)** - Production patterns (interceptors, monitors)
- **[FileUploadExample.swift](Examples/FileUploadExample.swift)** - File upload guide

## 💡 Common Use Cases

### GET Request

```swift
struct GetUserRequest: NetworkRequest {
    typealias Response = User
    let userId: String

    var path: String { "/users/{id}" }
    var method: HTTPMethod { .get }
    var pathParameters: [String: String]? {
        ["id": userId]
    }
}

let user = try await client.execute(GetUserRequest(userId: "123"))
```

### POST Request with JSON

```swift
struct CreatePostRequest: NetworkRequest {
    typealias Response = Post
    let title: String
    let body: String

    var path: String { "/posts" }
    var method: HTTPMethod { .post }
    var parameters: Parameters? {
        ["title": title, "body": body]
    }
}

let post = try await client.execute(
    CreatePostRequest(title: "Hello", body: "World")
)
```

### File Upload

```swift
struct UploadAvatarRequest: NetworkRequest {
    typealias Response = User
    let userId: String
    let imageData: Data

    var path: String { "/users/{id}/avatar" }
    var method: HTTPMethod { .post }
    var pathParameters: [String: String]? { ["id": userId] }
    var files: [String: Data]? { ["avatar": imageData] }
}

let user = try await client.execute(
    UploadAvatarRequest(userId: "123", imageData: imageData)
)
```

### Error Handling

```swift
do {
    let user = try await client.execute(GetUserRequest(userId: "123"))
} catch let error as ResponseError {
    switch error {
    case .clientError(let statusCode, let message):
        debugPrint("Client error (\(statusCode)): \(message ?? "")")
    case .serverError(let statusCode, _):
        debugPrint("Server error: \(statusCode)")
    case .decodingFailed(let error, _):
        debugPrint("Decoding failed: \(error)")
    default:
        debugPrint("Response error: \(error.errorDescription ?? "")")
    }
} catch let error as NetworkError {
    switch error {
    case .noConnection:
        debugPrint("No internet connection")
    case .timeout(let duration):
        debugPrint("Request timed out after \(duration)s")
    default:
        debugPrint("Network error: \(error.errorDescription ?? "")")
    }
}
```

## 🎨 Advanced Features

### Custom Configuration

```swift
let configuration = NetworkClientConfiguration(
    baseURL: "https://api.example.com",
    defaultTimeout: 60.0,
    defaultHeaders: HTTPHeaders([
        .authorization(bearerToken: "your-token"),
        .accept("application/json")
    ]),
    interceptors: [AuthInterceptor()],
    eventMonitors: [AnalyticsMonitor()]
)

let client = NetworkClient(configuration: configuration)
```

### Request Interceptors

```swift
final class AuthInterceptor: RequestInterceptor {
    func adapt(_ urlRequest: URLRequest,
               for session: Session,
               completion: @escaping (Result<URLRequest, Error>) -> Void) {
        var urlRequest = urlRequest
        urlRequest.headers.add(.authorization(bearerToken: getToken()))
        completion(.success(urlRequest))
    }
}
```

### Event Monitors

```swift
final class AnalyticsMonitor: EventMonitor {
    func requestDidResume(_ request: Request) {
        Analytics.track("api_request_started")
    }

    func request<Value>(_ request: DataRequest,
                       didParseResponse response: DataResponse<Value, AFError>) {
        Analytics.track("api_request_completed",
                       statusCode: response.response?.statusCode)
    }
}
```

### Retry Policies

```swift
struct GetUserRequest: NetworkRequest {
    // ... other properties ...

    var retryPolicy: RetryPolicy {
        RetryPolicy(
            maxRetries: 3,
            retryDelay: 1.0,
            exponentialBackoff: true,
            retryableStatusCodes: [408, 429, 500, 502, 503],
            retryOnNetworkError: true
        )
    }
}
```

### Concurrent Requests

```swift
let userIds = [1, 2, 3, 4, 5]

let users = try await withThrowingTaskGroup(of: User.self) { group in
    for userId in userIds {
        group.addTask {
            try await client.execute(GetUserRequest(userId: String(userId)))
        }
    }

    var results: [User] = []
    for try await user in group {
        results.append(user)
    }
    return results
}
```

## 🏗️ Architecture

ASC is built around several key components:

### Protocol-Oriented Design

- **NetworkRequest** - Defines all request parameters declaratively
- **NetworkClient** - Executes requests using Alamofire
- **Type-safe responses** - Generic associated types ensure compile-time safety

### Error Handling

- **NetworkError** - Connection issues (timeout, no internet, SSL)
- **ResponseError** - HTTP errors (4xx, 5xx, decoding failures)
- **AuthenticationError** - Auth-specific errors (token expired, unauthorized)

### Advanced Features

- **Request Interceptors** - Modify requests before sending
- **Event Monitors** - Track request lifecycle
- **Retry Policies** - Automatic retry with backoff
- **File Uploads** - Multipart form data support

See [CLAUDE.md](CLAUDE.md) for detailed architecture documentation.

## 📖 Documentation

- **[CLAUDE.md](CLAUDE.md)** - Complete architecture and development guide
- **[Examples/](Examples/)** - Practical usage examples
- **[API Documentation](https://YOUR_USERNAME.github.io/ASC/)** - Full API reference

## 🧪 Testing

ASC has comprehensive test coverage (99%+):

```bash
# Run tests
swift test

# Run tests with coverage
swift test --enable-code-coverage

# View coverage report
xcrun llvm-cov report \
    .build/x86_64-apple-macosx/debug/ASCPackageTests.xctest/Contents/MacOS/ASCPackageTests \
    -instr-profile=.build/x86_64-apple-macosx/debug/codecov/default.profdata \
    Sources/ASC/
```

## 🤝 Contributing

Contributions are welcome! Please read our [Contributing Guide](CONTRIBUTING.md) for details.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

ASC is available under the MIT license. See the [LICENSE](LICENSE) file for more info.

## 🙏 Acknowledgments

- Built on top of [Alamofire](https://github.com/Alamofire/Alamofire) - the elegant HTTP networking library
- Inspired by modern networking patterns and best practices
- Uses [SwiftLint](https://github.com/realm/SwiftLint) for code quality

## 🔗 Links

- **GitHub:** https://github.com/YOUR_USERNAME/ASC
- **Documentation:** https://YOUR_USERNAME.github.io/ASC/
- **Issues:** https://github.com/YOUR_USERNAME/ASC/issues
- **Discussions:** https://github.com/YOUR_USERNAME/ASC/discussions

## 💬 Support

- 📖 Read the [documentation](CLAUDE.md)
- 💡 Check [examples](Examples/)
- 🐛 Report bugs via [GitHub Issues](https://github.com/YOUR_USERNAME/ASC/issues)
- 💬 Ask questions in [Discussions](https://github.com/YOUR_USERNAME/ASC/discussions)

---

**Made with ❤️ by the ASC team**

*Replace `YOUR_USERNAME` with your actual GitHub username*
