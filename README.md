# ASC - Alamofire Swift Client

A modern, type-safe, protocol-oriented networking library built on top of Alamofire. ASC provides a clean, declarative API for network requests with full access to Alamofire's advanced features.

[![Swift](https://img.shields.io/badge/Swift-6.2-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-iOS%2018%2B%20%7C%20macOS%2015%2B-lightgrey.svg)](https://developer.apple.com)
[![SPM](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](https://swift.org/package-manager)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

## Features

- **Type-Safe Requests** — Protocol-oriented API with compile-time type checking
- **Modern Swift** — Full async/await support with Swift 6 Sendable conformance
- **Smart Retry** — Configurable retry policies with exponential backoff
- **File Uploads** — Multipart form-data support for file uploads
- **Interceptors** — Request/response interception for auth, logging, and more
- **Event Monitoring** — Track request lifecycle for analytics and debugging
- **SSL Pinning** — Certificate pinning support via `ServerTrustManager`
- **Well Tested** — 150+ tests covering networking, auth, error handling, and uploads

## Requirements

- iOS 18.0+ / macOS 15.0+
- Swift 6.2+
- Xcode 16.0+

## Installation

### Swift Package Manager

Add ASC to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/YOUR_ORG/ASC.git", from: "1.0.0")
]
```

Or add it via Xcode: **File → Add Package Dependencies...**

## Quick Start

### Basic Usage

```swift
import ASC

// 1. Create a client
let client = NetworkClient(baseURL: "https://api.example.com")

// 2. Define your request
struct GetUserRequest: Endpoint {
    typealias Request = Empty
    typealias Response = User

    let userId: String

    var path: String { "/users/\(userId)" }
    var method: HTTPMethod { .get }
}

// 3. Execute
let user = try await client.execute(GetUserRequest(userId: "123"))
```

### POST Request with JSON Body

```swift
struct CreatePostRequest: Endpoint {
    typealias Response = Post

    struct Body: Encodable, Sendable {
        let title: String
        let content: String
    }
    typealias Request = Body

    let title: String
    let content: String

    var path: String { "/posts" }
    var method: HTTPMethod { .post }
    var parameters: Body? {
        Body(title: title, content: content)
    }
}

let post = try await client.execute(
    CreatePostRequest(title: "Hello", content: "World!")
)
```

### GET with Query Parameters

```swift
struct SearchRequest: Endpoint {
    typealias Response = [SearchResult]

    struct Query: Encodable, Sendable {
        let q: String
        let limit: Int
    }
    typealias Request = Query

    let query: String
    let limit: Int

    var path: String { "/search" }
    var method: HTTPMethod { .get }
    var parameters: Query? {
        Query(q: query, limit: limit)
    }
}

let results = try await client.execute(
    SearchRequest(query: "swift", limit: 10)
)
```

GET/HEAD/DELETE parameters are URL-encoded automatically. POST/PUT/PATCH are JSON-encoded in the body.

## Logging

ASC includes built-in logging using Apple's unified logging system (`os.log`).

Configure logging when creating a client:

```swift
let config = NetworkClientConfiguration(
    baseURL: "https://api.example.com",
    logLevel: .verbose
)
let client = NetworkClient(configuration: config)
```

**Available levels:**

| Level | Output |
|-------|--------|
| `.none` | No logging (default) |
| `.error` | Errors only |
| `.info` | Request URLs and status codes |
| `.debug` | Info + HTTP headers |
| `.verbose` | Debug + request/response bodies (pretty-printed JSON) |

**Features:**
- Emoji indicators for methods, status codes, and timing
- Automatic redaction of sensitive headers (Authorization, API keys, cookies)
- Request duration with performance emojis
- Pretty-printed JSON for easy reading

Filter logs in Console.app or Xcode by subsystem: `com.asc.networking`

## Advanced Features

### File Upload

ASC supports three upload modes via the `uploadData` property on `Endpoint`:

#### 1. Upload Data (`.data`)

For small data already in memory:

```swift
struct UploadAvatarRequest: Endpoint {
    typealias Response = User
    typealias Request = Empty

    let userId: String
    let imageData: Data

    var path: String { "/users/\(userId)/avatar" }
    var method: HTTPMethod { .post }
    var uploadData: UploadData? {
        .data(imageData)
    }
}

let user = try await client.execute(
    UploadAvatarRequest(userId: "123", imageData: imageData)
)
```

#### 2. Upload File (`.file`)

For large files from the file system (memory-efficient):

```swift
struct UploadVideoRequest: Endpoint {
    typealias Response = Video
    typealias Request = Empty

    let videoURL: URL

    var path: String { "/videos" }
    var method: HTTPMethod { .post }
    var uploadData: UploadData? {
        .file(videoURL)
    }
}
```

#### 3. Multipart Form Data (`.multipart`)

For multiple files and/or parameters in a single request:

```swift
struct UploadDocumentsRequest: Endpoint {
    typealias Response = UploadResponse
    typealias Request = Empty

    let imageData: Data
    let documentURL: URL
    let description: String

    var path: String { "/documents" }
    var method: HTTPMethod { .post }
    var uploadData: UploadData? {
        .multipart([
            .data(fieldName: "image", data: imageData, fileName: "image.jpg", mimeType: "image/jpeg"),
            .file(fieldName: "document", fileURL: documentURL, fileName: "doc.pdf", mimeType: "application/pdf"),
            .parameter("description", value: description),
        ])
    }
}
```

**Choosing the right mode:**
- `.data` — files < 10MB already loaded into memory
- `.file` — large files (> 10MB) to avoid memory pressure
- `.multipart` — multiple files, or files combined with text parameters

### Authentication

ASC provides two authentication mechanisms: simple token injection via `AuthInterceptor`, and automatic pre-emptive token refresh via `OAuthAuthenticator`.

#### Bearer / Basic / Custom Token

Implement `TokenStorage` to provide tokens, then pass an `AuthInterceptor` via `authInterceptor:`:

```swift
final class BearerTokenStorage: TokenStorage {
    private var token: String?

    var authToken: AuthToken? {
        guard let token else { return nil }
        return .bearer(token: token)
    }

    func updateToken(_ newToken: String) {
        token = newToken
    }

    func flush() {
        token = nil
    }
}

let storage = BearerTokenStorage(token: "your-api-key")

let config = NetworkClientConfiguration(
    baseURL: "https://api.example.com",
    authInterceptor: AuthInterceptor(storage: storage)
)
let client = NetworkClient(configuration: config)
```

Mark individual requests that need authentication:

```swift
struct GetProfileRequest: Endpoint {
    typealias Response = UserProfile
    typealias Request = Empty

    var path: String { "/me" }
    var method: HTTPMethod { .get }
    var enableAuthorization: Bool { true }  // injects Authorization header
}

let profile = try await client.execute(GetProfileRequest())
// → Authorization: Bearer your-api-key
```

`AuthToken` supports three schemes:
- `.bearer(token:)` — `Authorization: Bearer {token}`
- `.basic(username:password:)` — `Authorization: Basic {base64}`
- `.custom(token:)` — `Authorization: {token}`

#### OAuth with Pre-emptive Token Refresh

For OAuth 2.0 with automatic token refresh, implement `OAuthTokenStorage` and use `OAuthAuthenticator`:

```swift
final class MyOAuthStorage: OAuthTokenStorage {
    private var accessToken: String?
    private var refreshToken: String?

    var authToken: AuthToken? {
        guard let token = accessToken else { return nil }
        return .bearer(token: token)
    }

    func update(accessToken: String, refreshToken: String) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }

    func executeRefreshToken() async throws {
        guard let refresh = refreshToken else {
            throw ASCError.invalidToken
        }
        // Call your refresh endpoint and update tokens
        let response = try await refreshClient.execute(
            RefreshTokenRequest(refreshToken: refresh)
        )
        update(accessToken: response.accessToken, refreshToken: response.refreshToken)
    }

    func flush() {
        accessToken = nil
        refreshToken = nil
    }
}
```

Configure the client with `OAuthAuthenticator`:

```swift
let storage = MyOAuthStorage()
let credential = OAuthCredential(authToken: .bearer(token: initialToken))
let authenticator = OAuthAuthenticator(storage: storage)
let interceptor = AuthenticationInterceptor(
    authenticator: authenticator,
    credential: credential
)

let config = NetworkClientConfiguration(
    baseURL: "https://api.example.com",
    interceptors: [interceptor]
)
let client = NetworkClient(configuration: config)
```

**How it works:**
- `OAuthCredential.requiresRefresh` returns `true` when the JWT is within 14 minutes of expiry
- Alamofire calls `OAuthAuthenticator.refresh()` proactively before sending the request
- `refresh()` delegates to `OAuthTokenStorage.executeRefreshToken()`
- The original request proceeds with the new token, no retry needed

### Event Monitoring

Pass custom `EventMonitor` implementations to track the request lifecycle:

```swift
final class AnalyticsMonitor: EventMonitor {
    func requestDidResume(_ request: Request) {
        Analytics.track("network_request_started", path: request.request?.url?.path ?? "")
    }

    func request<Value>(
        _ request: DataRequest,
        didParseResponse response: DataResponse<Value, AFError>
    ) {
        Analytics.track("network_request_completed", statusCode: response.response?.statusCode ?? 0)
    }
}

let config = NetworkClientConfiguration(
    baseURL: "https://api.example.com",
    eventMonitors: [AnalyticsMonitor()]
)
```

### Configuration Presets

```swift
// Development — verbose logging, 120s timeout, no retries
let devConfig = NetworkClientConfiguration.development(baseURL: "https://api.example.com")

// Production — error logging, 30s timeout, conservative retries
let prodConfig = NetworkClientConfiguration.production(baseURL: "https://api.example.com")

// Testing — no logging, 10s timeout, connectivity check disabled
let testConfig = NetworkClientConfiguration.testing(baseURL: "https://test.example.com")
```

### Advanced Configuration

```swift
let config = NetworkClientConfiguration(
    baseURL: "https://api.example.com",

    // Default headers for all requests
    defaultHeaders: HTTPHeaders([
        HTTPHeader(name: "X-App-Version", value: "1.0.0"),
        HTTPHeader(name: "Accept-Language", value: "en-US"),
    ]),

    // Dedicated auth interceptor (applied only to enableAuthorization: true requests)
    authInterceptor: AuthInterceptor(storage: tokenStorage),

    // Additional interceptors
    interceptors: [SigningInterceptor()],

    // Event monitors
    eventMonitors: [AnalyticsMonitor()],

    // SSL certificate pinning
    serverTrustManager: ServerTrustManager(
        evaluators: ["api.example.com": PinnedCertificatesTrustEvaluator()]
    ),

    // Timeouts and policy
    defaultTimeout: 30.0,
    defaultCachePolicy: .reloadIgnoringLocalCacheData,

    // Retry policy for all requests (can be overridden per-request)
    defaultRetryPolicy: .conservative,

    // Log level
    logLevel: .error
)
let client = NetworkClient(configuration: config)
```

### Retry Policies

Use the built-in presets or supply any `Alamofire.RetryPolicy`:

```swift
struct PaymentRequest: Endpoint {
    // ...
    var retryPolicy: Alamofire.RetryPolicy? { .aggressive }   // 5 retries
}

struct GetFeedRequest: Endpoint {
    // ...
    var retryPolicy: Alamofire.RetryPolicy? { .default }      // 3 retries
}

struct LogAnalyticsRequest: Endpoint {
    // ...
    var retryPolicy: Alamofire.RetryPolicy? { .conservative } // 2 retries
}

// No retries — omit retryPolicy (default is nil) or return nil explicitly
struct SearchRequest: Endpoint {
    // ...
    // retryPolicy defaults to nil — no retries
}
```

Available presets: `.aggressive` (5 retries), `.default` (3 retries), `.conservative` (2 retries).

### Downloads

Download a file from a URL directly:

```swift
let url = URL(string: "https://example.com/file.pdf")!
let fileURL = try await client.download(
    from: url,
    to: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0],
    options: [.createIntermediateDirectories, .removePreviousFile]
)
```

Download via an `Endpoint`:

```swift
struct DownloadReportRequest: Endpoint {
    typealias Request = Empty
    typealias Response = Empty

    var path: String { "/reports/latest.pdf" }
    var method: HTTPMethod { .get }
}

let fileURL = try await client.download(
    DownloadReportRequest(),
    to: destinationFolder
)
```

### Empty Response (204 No Content)

```swift
struct DeleteUserRequest: Endpoint {
    typealias Response = Empty
    typealias Request = Empty

    let userId: String

    var path: String { "/users/\(userId)" }
    var method: HTTPMethod { .delete }
}

try await client.execute(DeleteUserRequest(userId: "123"))
```

### Custom Response Validation

Add business-logic validation after decoding:

```swift
struct GetUserRequest: Endpoint {
    typealias Response = UserResponse
    typealias Request = Empty

    var path: String { "/me" }
    var method: HTTPMethod { .get }

    func validate(response: UserResponse) throws {
        guard response.isActive else {
            throw ASCError.unauthorized("User account is inactive")
        }
    }
}
```

## Error Handling

All errors are unified under `ASCError`:

```swift
do {
    let user = try await client.execute(GetUserRequest(userId: "123"))
} catch let error as ASCError {
    switch error {
    // Network errors
    case .noConnection:
        showOfflineBanner()
    case .timeout:
        showRetryPrompt()
    case .cancelled:
        break

    // Response errors
    case .serverError(let code, let message):
        log.error("Server \(code): \(message)")
    case .clientError(let code, let message):
        showErrorAlert(message ?? "Request failed (\(code))")
    case .decodingFailed(let underlying, _):
        log.error("Decode failed: \(underlying)")

    // Auth errors
    case .notAuthenticated, .tokenExpired:
        navigateToLogin()
    case .unauthorized(let resource):
        showPermissionDenied(resource)
    case .forbidden:
        showForbiddenAlert()

    default:
        showGenericError(error.localizedDescription)
    }
}
```

**Error categories:**

| Category | Cases |
|----------|-------|
| Network | `.noConnection`, `.timeout`, `.hostUnreachable`, `.certificateValidationFailed`, `.cancelled`, `.networkFailure` |
| Response | `.invalidStatusCode`, `.decodingFailed`, `.missingData`, `.invalidFormat`, `.serverError`, `.clientError`, `.validationFailed` |
| Auth | `.notAuthenticated`, `.tokenExpired`, `.invalidToken`, `.tokenRefreshFailed`, `.unauthorized`, `.forbidden`, `.invalidCredentials` |

Useful helpers on `ASCError`:
- `.statusCode: HTTPStatusCode?` — HTTP status from response/server/client errors
- `.responseData: Data?` — raw response body when available
- `.underlyingError: Error?` — wrapped original error

## Best Practices

### Organize requests with enums

```swift
enum UserAPI {
    struct GetUser: Endpoint {
        typealias Response = User
        typealias Request = Empty

        let id: String
        var path: String { "/users/\(id)" }
        var method: HTTPMethod { .get }
        var enableAuthorization: Bool { true }
    }

    struct UpdateUser: Endpoint {
        typealias Response = User

        struct Body: Encodable, Sendable {
            let name: String
            let email: String
        }
        typealias Request = Body

        let id: String
        let body: Body

        var path: String { "/users/\(id)" }
        var method: HTTPMethod { .put }
        var parameters: Body? { body }
        var enableAuthorization: Bool { true }
    }
}

let user = try await client.execute(UserAPI.GetUser(id: "123"))
```

### Reuse a single client instance

```swift
// ✅ Good — single session, shared connection pool
final class NetworkService {
    static let shared = NetworkService()
    private let client = NetworkClient(configuration: .production(baseURL: "https://api.example.com"))

    func getUser(id: String) async throws -> User {
        try await client.execute(UserAPI.GetUser(id: id))
    }
}

// ❌ Bad — creates a new Alamofire Session on every call
func fetchUser() async throws -> User {
    let client = NetworkClient(baseURL: "https://api.example.com") // don't do this
    return try await client.execute(UserAPI.GetUser(id: "123"))
}
```

### Parallel requests

```swift
func loadDashboard(userId: String) async throws -> (User, [Post], Stats) {
    async let user  = client.execute(UserAPI.GetUser(id: userId))
    async let posts = client.execute(PostAPI.GetPosts(userId: userId))
    async let stats = client.execute(StatsAPI.GetStats(userId: userId))
    return try await (user, posts, stats)
}
```

### Testing

Mock the network layer using `URLProtocol`:

```swift
import Testing
@testable import ASC

@Suite("UserRepository Tests", .serialized)
struct UserRepositoryTests {
    @Test("Returns user on success")
    func testGetUserSuccess() async throws {
        let mockUser = User(id: "123", name: "John")
        let response = try JSONEncoder().encode(mockUser)

        MockURLProtocol.setMockResponse(
            data: response,
            statusCode: 200,
            url: URL(string: "https://test.com/users/123")!
        )

        let sessionConfig = URLSessionConfiguration.ephemeral
        sessionConfig.protocolClasses = [MockURLProtocol.self]
        let config = NetworkClientConfiguration(
            baseURL: "https://test.com",
            sessionType: .custom(sessionConfig),
            connectivityCheckEnabled: false
        )
        let client = NetworkClient(configuration: config)
        let user = try await client.execute(UserAPI.GetUser(id: "123"))

        #expect(user.id == "123")
        #expect(user.name == "John")
    }
}
```

### Error handling in repositories

Transform network errors to domain errors at the repository boundary:

```swift
final class UserRepository {
    private let client: NetworkClient

    func getUser(id: String) async throws -> User {
        do {
            return try await client.execute(UserAPI.GetUser(id: id))
        } catch let error as ASCError {
            switch error {
            case .clientError(404, _):
                throw DomainError.userNotFound(id: id)
            case .noConnection, .timeout:
                throw DomainError.networkUnavailable
            case .notAuthenticated, .tokenExpired:
                throw DomainError.sessionExpired
            default:
                throw DomainError.unknown(error)
            }
        }
    }
}
```

## License

ASC is available under the MIT license. See [LICENSE](LICENSE) for details.
