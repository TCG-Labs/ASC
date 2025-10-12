# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ASC (Alamofire Swift Client) is a Swift Package Manager library built on top of Alamofire. The project targets iOS 18+ and macOS 15+ and uses Swift 6.2.

### Purpose
Provides a convenient wrapper over Alamofire for:
- **Simplified network requests** - More declarative and type-safe API
- **Convenient response handling** - Automatic parsing and error handling
- **Modern Swift patterns** - Protocol-oriented, async/await, Codable support

## Development Commands

### Building
```bash
swift build
```

### Testing
```bash
# Run all tests
swift test

# Run all tests with coverage
swift test --enable-code-coverage

# Run a specific test
swift test --filter ASCTests.example

# View coverage report
xcrun llvm-cov report \
    .build/x86_64-apple-macosx/debug/ASCPackageTests.xctest/Contents/MacOS/ASCPackageTests \
    -instr-profile=.build/x86_64-apple-macosx/debug/codecov/default.profdata \
    Sources/ASC/
```

### Linting
The project uses SwiftLint with a strict configuration. Linting runs automatically during build via the SwiftLintBuildToolPlugin.

```bash
# Manually run SwiftLint (if installed)
swiftlint

# Auto-fix issues
swiftlint --fix
```

## Architecture

### Package Structure
- **ASC/Sources/ASC/**: Main library source code
  - **Client/**: NetworkClient and supporting components (5 files)
    - `NetworkClient.swift` - Main client for executing requests (276 lines)
    - `NetworkClientConfiguration.swift` - Configuration struct (112 lines)
    - `URLBuilder.swift` - URL construction with path parameters (81 lines)
    - `MultipartRequestBuilder.swift` - Multipart upload builder (67 lines)
    - `ErrorMapper.swift` - Error mapping from Alamofire (113 lines)
  - **Core/**: Protocol definitions and core types
  - **Errors/**: Error types (NetworkError, ResponseError, AuthenticationError)
  - **Request/**: NetworkRequest protocol and extensions
- **ASC/Tests/ASCTests/**: Comprehensive test suite (65 tests, 100% pass rate)
  - **Helpers/**: Test utilities and infrastructure
    - `TestRequestFactory.swift` - Factory for creating test requests (149 lines)
    - `MockResponseBuilder.swift` - DSL for mock responses (248 lines)
    - `TestHelpers.swift` - Common test utilities (62 lines)
    - `TestModels.swift` - Test data models (217 lines)
  - **Mocks/**: Mock implementations for testing
  - Test files organized by feature area
- **ASC/Package.swift**: SPM configuration with Alamofire dependency

### Dependencies
- **Alamofire** (5.10.2+): Core networking library this package wraps
- **SwiftLint** (0.61.0+): Build-time linting via plugin

### Testing Framework
Uses Swift Testing framework (not XCTest). Tests use the `@Test` attribute and `#expect` for assertions.

**Test Coverage:**
- 65 comprehensive tests across all features
- 100% pass rate
- Organized test suites: NetworkClientTests, ErrorHandlingTests, InterceptorAndMonitorTests, AdvancedNetworkTests
- Serialized execution to prevent state interference
- MockURLProtocol for network request interception
- Test factory pattern for easy request creation
- DSL for mock response building

## Library Architecture & Features

### Core Design: Protocol-Based Architecture

The library uses protocol-oriented design for maximum flexibility and testability:

#### NetworkRequest Protocol
Defines all network request parameters in a declarative way:
- Base URL, path, HTTP method
- Headers, query parameters, body
- Response type (Codable)
- Retry policy, timeout configuration
- **Path parameters** for template substitution (`{userId}` → `123`)
- **Path prefix** for API versioning (`/api/v1`)
- **File uploads** via multipart/form-data

#### NetworkClient
Main client that executes requests using Alamofire:
- Async/await API
- Generic response handling
- Interceptor chain execution
- Error transformation

**Component-Based Architecture:**
NetworkClient follows Single Responsibility Principle with dedicated components:

1. **URLBuilder** - URL Construction
   - Combines base URL with path
   - Applies path prefix for API versioning
   - Substitutes path parameters (`{userId}` → `123`)
   - Validates and builds final URLs

2. **MultipartRequestBuilder** - File Uploads
   - Constructs multipart/form-data requests
   - Handles file data with custom MIME types
   - Combines files with regular parameters
   - Returns configured Alamofire UploadRequest

3. **ErrorMapper** - Error Translation
   - Maps Alamofire errors to ASC error types
   - Handles URLError → NetworkError mapping
   - Handles validation errors → ResponseError
   - Handles serialization errors with context

4. **NetworkClientConfiguration** - Configuration
   - Centralizes all client settings
   - Manages interceptors and monitors
   - Controls dispatch queues and trust managers
   - Provides default configuration factory

### Response Handling System

**Automatic JSON Parsing**
- Direct Codable model mapping
- Type-safe response handling
- Support for various content types

**HTTP Status Code Handling**
- 2xx: Success with parsed models
- 4xx: Client errors with detailed info
- 5xx: Server errors with retry suggestions

**Retry Mechanism**
- Configurable retry policies
- Exponential backoff
- Conditional retry based on error type

**Caching Layer**
- URLCache integration
- Custom cache policies
- Memory and disk caching

### Core Features

**1. Request/Response Interceptors**
- Chain of responsibility pattern
- Pre-request modification (add headers, sign requests)
- Post-response processing (logging, metrics)
- Error interception and transformation

**2. Authentication System**
- Token-based authentication
- Automatic token refresh on 401
- Secure token storage integration
- Multiple authentication schemes support

**3. Logging System**
- Unified Logger (OSLog) integration
- Request/response logging
- Configurable log levels
- Privacy-aware (redact sensitive data)

**4. Mock System for Testing**
- Protocol-based mocking
- Predefined response fixtures
- Network condition simulation
- Easy test setup

**Test Infrastructure:**
Comprehensive testing utilities for writing clean, maintainable tests:

1. **TestRequestFactory** - Request Creation Factory
   - Pre-configured test requests with sensible defaults
   - Methods for all request types (GET, POST, PUT, DELETE, upload)
   - Eliminates repetitive request setup code
   - Example: `TestRequestFactory.getUser(userId: "123")`

2. **MockResponseBuilder** - Response DSL
   - Fluent API for building mock HTTP responses
   - Success/error response builders
   - Convenience methods: `.success(user)`, `.notFound()`, `.serverError()`
   - Type-safe with `.handler()` method for MockURLProtocol
   - Example: `MockResponseBuilder.user().handler()`

3. **MockURLProtocol** - Network Interception
   - Intercepts URLSession requests for testing
   - Configurable request handlers
   - Request history tracking
   - Response delay simulation

4. **Test Helpers**
   - `setupTest()` - Reset mock state before each test
   - `createMockClient()` - Factory for test clients
   - `TestConstants` - Centralized test constants
   - Serialized test execution to prevent state interference

**5. Upload/Download with Progress**
- Async sequences for progress tracking
- Background upload/download support
- Multipart form data
- Resume capability for downloads

### Error Handling

Structured error types:
- `NetworkError`: Connection, timeout, no internet
- `ResponseError`: Invalid status, parsing failed
- `AuthenticationError`: Token expired, unauthorized
- Custom error mapping from backend

## Architecture Decision: Type Re-exports

### 🎯 Optimization Strategy

Instead of duplicating Alamofire types, ASC **re-exports them directly**. This approach:

- ✅ **Reduces codebase** from ~1,841 to 1,015 lines (-45% code)
- ✅ **Eliminates maintenance** of ~826 lines of duplicate code
- ✅ **Uses battle-tested implementations** from Alamofire
- ✅ **Maintains API consistency** with Alamofire ecosystem
- ✅ **Automatic updates** when Alamofire improves
- ✅ **Zero conversion overhead** between types

### 📦 Re-exported Types

All re-exports are in `Core/AlamofireReExports.swift` (95 lines):

**HTTP Types:**
- `HTTPHeaders` - Order-preserving, case-insensitive headers
- `HTTPHeader` - Single header field
- `HTTPMethod` - HTTP method with custom support

**Parameter Encoding:**
- `Parameters` - Parameter dictionary typealias
- `ParameterEncoding` - Encoding protocol
- `JSONEncoding` - JSON parameter encoding
- `URLEncoding` - URL-encoded parameter encoding

**URL Conversion:**
- `URLConvertible` - Type-safe URL conversion
- `URLRequestConvertible` - Type-safe URLRequest conversion

**Advanced (Future Use):**
- `RequestAdapter` - Adapt requests before sending
- `RequestRetrier` - Retry failed requests
- `RequestInterceptor` - Combined adapter + retrier
- `EventMonitor` - Observe request lifecycle
- `CachedResponseHandler` - Handle cached responses
- `RedirectHandler` - Handle HTTP redirects

### 🔧 ASC-Specific Code

We focus on our unique value:
- `NetworkRequest` protocol - Type-safe request definition
- `NetworkClient` - Convenient async/await client
- Error types - Structured error handling
- `RetryPolicy` - Retry configuration

## Current Implementation Status

### ✅ Completed Core Features

**1. Type Re-exports from Alamofire**
- `HTTPHeaders`, `HTTPHeader`, `HTTPMethod`
- `Parameters`, `ParameterEncoding`, `JSONEncoding`, `URLEncoding`
- `URLConvertible`, `URLRequestConvertible`
- All features from Alamofire available directly
- See Alamofire documentation for full capabilities

**2. NetworkClient with Advanced Configuration**
- **NetworkClientConfiguration** struct for fine-grained control
- **RequestInterceptor support**: Adapt and retry requests
  - Multiple interceptors can be chained
  - Session-level interceptors apply to all requests
  - Perfect for authentication, logging, signing
- **EventMonitor support**: Observe request lifecycle
  - Multiple monitors can be registered
  - Track request start, completion, errors
  - Integrate with logging systems (OSLog, etc.)
- **ServerTrustManager**: SSL/TLS validation
  - Certificate pinning support
  - Custom trust evaluation per host
  - Development vs production configurations
- **RedirectHandler**: Custom redirect logic
  - Control redirect behavior per request
  - Modify redirect requests
- **CachedResponseHandler**: Smart caching
  - Custom cache policies
  - Memory and disk cache control
- **Custom Dispatch Queues**: Performance optimization
  - Separate queues for root, request, serialization
  - Configurable QoS levels
- **EmptyResponse**: Support for 204 No Content
- Default headers with smart override system
- Full Sendable conformance for Swift 6
- Async/await API with comprehensive error mapping

**3. NetworkRequest Protocol**
- Main abstraction layer - our unique value proposition
- Uses `parameters: Parameters?` for flexible data passing
- Uses `parameterEncoding` for encoding strategy selection
- Default encoding is JSONEncoding.default from Alamofire
- **Path parameters**: Template substitution in URLs (`/users/{userId}`)
- **Path prefix**: Common path prefix for API versioning (`/api/v1`)
- **File uploads**: Multipart/form-data support via `files` property
- Per-request headers, timeout, and cache policy override
- Fully type-safe with associatedtype Response: Decodable & Sendable
- Protocol extensions provide sensible defaults

**4. Error Handling System**
- `ASCError` base protocol with LocalizedError conformance
- `NetworkError`: Connection issues, timeouts, SSL problems
- `ResponseError`: HTTP status codes, parsing failures
- `AuthenticationError`: Token and permission issues
- All errors provide errorDescription, recoverySuggestion, underlyingError

**5. RetryPolicy Configuration**
- Configurable retry behavior for failed requests
- Exponential backoff support
- Retryable status codes customization
- Network error retry options
- Predefined policies: .default, .none, .aggressive

### 🎯 Usage Examples

#### Basic Usage

```swift
// Simple client creation
let client = NetworkClient(baseURL: "https://api.example.com")

// Define a request
struct GetUserRequest: NetworkRequest {
    typealias Response = User
    let userId: String
    var path: String { "/users/\(userId)" }
    var method: HTTPMethod { .get }
}

// Execute
let user = try await client.execute(GetUserRequest(userId: "123"))
```

#### Advanced Configuration with Interceptors and Monitors

```swift
// Create custom interceptor for authentication
final class AuthInterceptor: RequestInterceptor {
    func adapt(
        _ urlRequest: URLRequest,
        for session: Session,
        completion: @escaping (Result<URLRequest, any Error>) -> Void
    ) {
        var urlRequest = urlRequest
        urlRequest.headers.add(.authorization(bearerToken: getToken()))
        completion(.success(urlRequest))
    }

    func retry(
        _ request: Request,
        for session: Session,
        dueTo error: any Error,
        completion: @escaping (RetryResult) -> Void
    ) {
        if let response = request.task?.response as? HTTPURLResponse,
           response.statusCode == 401 {
            // Refresh token and retry
            refreshToken { success in
                completion(success ? .retry : .doNotRetry)
            }
        } else {
            completion(.doNotRetry)
        }
    }
}

// Create logging monitor
final class Logger: EventMonitor {
    func requestDidResume(_ request: Request) {
        print("🚀 Request started: \(request.description)")
    }

    func request<Value>(_ request: DataRequest, didParseResponse response: DataResponse<Value, AFError>) {
        print("✅ Response received: \(response.response?.statusCode ?? 0)")
    }
}

// Configure advanced client
let config = NetworkClientConfiguration(
    baseURL: "https://api.example.com",
    interceptors: [AuthInterceptor()],
    eventMonitors: [Logger()],
    serverTrustManager: ServerTrustManager(
        evaluators: ["api.example.com": DefaultTrustEvaluator()]
    )
)

let client = NetworkClient(configuration: config)
```

#### Empty Response (204 No Content)

```swift
struct DeleteUserRequest: NetworkRequest {
    typealias Response = EmptyResponse
    let userId: String
    var path: String { "/users/\(userId)" }
    var method: HTTPMethod { .delete }
}

// No return value for empty responses
try await client.execute(DeleteUserRequest(userId: "123"))
```

#### Parameter Encoding

```swift
// JSON encoding (default)
struct CreatePostRequest: NetworkRequest {
    typealias Response = Post
    let title: String
    let content: String

    var path: String { "/posts" }
    var method: HTTPMethod { .post }
    var parameters: Parameters? {
        ["title": title, "content": content]
    }
    // parameterEncoding defaults to JSONEncoding.default
}

// URL encoding for query parameters
struct SearchRequest: NetworkRequest {
    typealias Response = SearchResults
    let query: String
    let page: Int

    var path: String { "/search" }
    var method: HTTPMethod { .get }
    var parameters: Parameters? {
        ["q": query, "page": page]
    }
    var parameterEncoding: any ParameterEncoding {
        URLEncoding.default // Will encode in query string for GET
    }
}
```

#### Path Parameters (URL Template Substitution)

```swift
// Define request with path parameters
struct GetUserRequest: NetworkRequest {
    typealias Response = User
    let userId: String

    var path: String { "/users/{userId}" }
    var method: HTTPMethod { .get }
    var pathParameters: [String: String]? {
        ["userId": userId]
    }
}

// Multiple path parameters
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

// Execute - path will be automatically resolved
let user = try await client.execute(GetUserRequest(userId: "123"))
// Actual URL: https://api.example.com/users/123
```

#### Path Prefix (API Versioning)

```swift
// Define request with path prefix
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

// Execute - prefix will be prepended automatically
let user = try await client.execute(GetUserRequestV1(userId: "123"))
// Actual URL: https://api.example.com/api/v1/users/123
```

#### File Upload (Multipart Form Data)

```swift
// Upload a single file
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

// Upload multiple files with additional parameters
struct UploadDocumentsRequest: NetworkRequest {
    typealias Response = UploadResponse
    let documents: [String: Data]

    var path: String { "/documents" }
    var method: HTTPMethod { .post }
    var files: [String: Data]? { documents }
    var parameters: Parameters? {
        ["folder": "uploads", "overwrite": true]
    }
}

// Execute upload
let imageData = UIImage(named: "avatar")?.jpegData(compressionQuality: 0.8)
let user = try await client.execute(UploadAvatarRequest(
    userId: "123",
    imageData: imageData!
))
```

#### Combining All Features

```swift
// Complex request with all features
struct UpdateUserDocumentRequest: NetworkRequest {
    typealias Response = Document
    let userId: String
    let documentId: String
    let fileData: Data
    let metadata: [String: Any]

    var pathPrefix: String? { "/api/v2" }
    var path: String { "/users/{userId}/documents/{documentId}" }
    var method: HTTPMethod { .put }
    var pathParameters: [String: String]? {
        ["userId": userId, "documentId": documentId]
    }
    var files: [String: Data]? {
        ["document": fileData]
    }
    var parameters: Parameters? { metadata }
    var headers: HTTPHeaders? {
        HTTPHeaders([
            .contentType("multipart/form-data"),
            .accept("application/json")
        ])
    }
    var timeout: TimeInterval? { 120 } // 2 minutes for large files
}
```

#### Testing with Test Infrastructure

```swift
import Testing
@testable import ASC

@Test("NetworkClient executes successful GET request")
func testNetworkClient() async throws {
    setupTest() // Reset mock state

    // Setup mock response using DSL
    let mockUser = TestUser(id: "123", name: "John Doe")
    MockURLProtocol.requestHandler = MockResponseBuilder.success(mockUser).handler()

    // Create client and request using factories
    let client = createMockClient()
    let request = TestRequestFactory.getUser(userId: "123")

    // Execute and verify
    let user = try await client.execute(request)
    #expect(user == mockUser)
}

@Test("NetworkClient handles 404 error")
func testNotFound() async throws {
    setupTest()

    // Setup error response
    MockURLProtocol.requestHandler = MockResponseBuilder.notFound().handler()

    let client = createMockClient()
    let request = TestRequestFactory.getUser(userId: "999")

    do {
        _ = try await client.execute(request)
        Issue.record("Expected error to be thrown")
    } catch let error as ResponseError {
        #expect(error.statusCode == 404)
    }
}

// Parameterized tests
@Test("HTTPStatus validation", arguments: [
    (code: 200, isSuccess: true),
    (code: 404, isSuccess: false),
    (code: 500, isSuccess: false)
])
func testStatusCodes(code: Int, isSuccess: Bool) {
    #expect(HTTPStatus.isSuccess(code) == isSuccess)
}
```

**Test Structure Benefits:**
- Tests reduced from ~40 lines to ~15 lines on average
- Consistent mock setup across all tests
- Easy to write new tests (3-5 lines vs 30-40 lines)
- Better readability with declarative API

## Technical Implementation Details

### Alamofire Integration Strategy

**Custom Session Configuration**
- Use custom `Session` instance (not default singleton)
- Configure dedicated dispatch queues for optimal performance
- Custom `URLSessionConfiguration` with timeout, caching policies
- Session-level interceptors and event monitors

**RequestInterceptor Implementation**
```swift
// Combine RequestAdapter + RequestRetrier protocols
- RequestAdapter: Modify requests before sending
  * Add authentication headers
  * Sign requests
  * Add common headers (User-Agent, Accept-Language)
  * Transform URLRequest

- RequestRetrier: Intelligent retry logic
  * Exponential backoff algorithm
  * Maximum retry attempts
  * Retry conditions (network errors, 5xx, 401 with token refresh)
  * Async token refresh handling
```

**EventMonitor for Observability**
- Implement custom EventMonitor protocol
- Track request lifecycle events:
  * `requestDidResume`: Log request start
  * `request(_:didCreateURLRequest:)`: Log actual URLRequest
  * `request(_:didParseResponse:)`: Log response data
  * `request(_:didCompleteTask:with:)`: Log completion
- Integrate with OSLog subsystems
- Support multiple monitors (logging, analytics, debugging)

**Response Validation & Serialization**
- Use Alamofire's `.validate()` for status code checking
- Custom validation for specific status codes
- `.serializingDecodable()` for automatic Codable parsing
- `.serializingData()` for raw data
- `.serializingString()` for text responses
- Custom response serializers for special formats

**ServerTrustManager Integration**
- Custom SSL/TLS validation policies
- Support certificate pinning
- Development/Production trust evaluators
- Per-host trust policies

**RedirectHandler**
- Custom redirect logic
- Prevent redirects for specific status codes
- Modify redirect requests

**CachedResponseHandler**
- Smart caching strategies per request
- Memory/disk cache control
- Cache validation with ETags/Last-Modified

**Network Reachability**
- Monitor network status changes
- Automatic request queuing when offline
- Retry queued requests when connected
- Publisher/AsyncSequence for status updates

**Request Pipeline**
```
1. Create URLRequest from NetworkRequest protocol
   a. Apply path prefix if specified
   b. Substitute path parameters ({param} → value)
   c. Build full URL (baseURL + pathPrefix + path)
2. Check if multipart request (files present)
   a. If yes: Create multipart/form-data request
   b. If no: Apply parameter encoding (JSON/URL)
3. Apply RequestAdapters (add headers, auth)
4. Validate network reachability
5. Execute via Alamofire Session (request or upload)
6. Monitor via EventMonitors
7. Handle redirects via RedirectHandler
8. Validate response (status, content type)
9. Cache response via CachedResponseHandler
10. Serialize response (Codable, Data, String)
11. Retry on failure via RequestRetrier
12. Return typed Result/throw error
```

### Swift Concurrency Integration

**Async/Await Support**
- All network methods return async throws
- Use Alamofire's native async/await API
- Structured concurrency with Task groups
- Cancellation support via Task.isCancelled

**Progress Tracking**
- AsyncStream for upload/download progress
- Real-time progress updates
- Cancellable progress tracking

### Type Safety & Generics

**Generic Request/Response**
```swift
protocol NetworkRequest {
    associatedtype Response: Decodable
    // Request configuration
}

func execute<T: NetworkRequest>(_ request: T) async throws -> T.Response
```

**Type-safe builders**
- RequestBuilder pattern for complex requests
- Type-safe query parameters
- Type-safe headers enumeration

## Code Standards

### SwiftLint Configuration
The project has a **very strict** SwiftLint configuration (.swiftlint.yml):

- **Force unwrapping/casting/try**: Errors (must avoid `!`, `as!`, `try!`)
- **Line length**: 120 warning, 150 error
- **Function body length**: 50 warning, 100 error
- **Cyclomatic complexity**: 10 warning, 15 error (strict)
- **Function parameters**: 5 warning, 7 error (strict)
- **print() prohibited**: Use Logger instead (warning)
- **!. chaining prohibited**: Use optional chaining (error)
- **Documentation required**: Missing docs on public API (error)
- **Explicit ACL**: All declarations need explicit access control

### Key Rules
- Tests and Package.swift are excluded from linting
- All public APIs must have documentation comments
- Prefer optional chaining over force unwrapping
- Use Logger instead of print()
- Keep functions under 50 lines
- Maximum 5 parameters per function
- Use MARK comments to organize code

## Code Structure

- Use Swift's latest features and protocol-oriented programming.
- Prefer value types (structs) over classes.
- Follow Apple's Human Interface Guidelines.

## Naming
- camelCase for vars/funcs, PascalCase for types
- Verbs for methods (fetchData)
- Boolean: use is/has/should prefixes
- Clear, descriptive names following Apple style
- Use camel case for network model variables


## Swift Best Practices

- Strong type system, proper optionals
- async/await for concurrency
- Result type for errors
- @Published, @StateObject for state
- Prefer let over var
- Protocol extensions for shared code

## 6. Performance

- Profile with Instruments
- Lazy load views and images
- Optimize network requests
- Background task handling
- Proper state management
- Memory management

## Code Quality & Refactoring

### Architecture Improvements

The codebase has undergone systematic refactoring to improve maintainability and testability:

**Priority 1: Code Deduplication**
- Extracted URL building logic (eliminated 68 lines of duplication)
- Extracted multipart upload logic (eliminated 52 lines of duplication)
- Centralized magic strings into TestConstants

**Priority 2: Component Extraction**
- Split NetworkClient from 552 lines into 5 focused components (276 lines main)
- Each component follows Single Responsibility Principle
- URLBuilder: URL construction (81 lines)
- MultipartRequestBuilder: File uploads (67 lines)
- ErrorMapper: Error translation (113 lines)
- NetworkClientConfiguration: Client settings (112 lines)
- Result: 50% reduction in NetworkClient size, improved maintainability

**Priority 3: Test Infrastructure**
- Created TestRequestFactory (149 lines) for request creation
- Created MockResponseBuilder (248 lines) for response mocking
- Converted to parameterized tests (36 test cases in 4 functions)
- Refactored integration tests (40 → 15 lines average)
- Result: ~100 lines saved, 62% reduction in test length

### Current Metrics

**Library Code:**
- NetworkClient components: 649 lines across 5 files
- Clean separation of concerns
- Well-documented public API
- Full Swift 6 concurrency support

**Test Suite:**
- 65 comprehensive tests, 100% pass rate
- Test infrastructure: 676 lines (4 helper files)
- Average test length: 15 lines (vs 40 before)
- Consistent patterns across all tests

**Code Quality:**
- Strict SwiftLint configuration enforced
- All public APIs documented
- Protocol-oriented design throughout
- Type-safe with comprehensive generics

## GitHub Integration

The repository has GitHub Actions configured for Claude Code:
- Claude responds to `@claude` mentions in issues, PRs, and comments
- Workflow file: .github/workflows/claude.yml
