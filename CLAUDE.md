# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ASC (Alamofire Swift Client) is a Swift Package Manager library built on top of Alamofire. The project targets iOS 18+ and macOS 15+ and uses Swift 6.2.

### Purpose
Provides a convenient wrapper over Alamofire for:
- **Simplified network requests** - More declarative and type-safe API
- **Convenient response handling** - Automatic parsing and error handling
- **Modern Swift patterns** - Protocol-oriented, async/await, Codable support

### Current Status
- **Version**: 1.0 (feature/verson-1.0 branch)
- **Status**: Production-ready
- **Test Coverage**: 135 tests, 100% pass rate
- **Code Quality**: 0 SwiftLint warnings/errors

## Development Commands

### Building & Testing
```bash
# Build
swift build

# Run all tests
swift test

# Linting (runs automatically during build)
swiftlint
swiftlint --fix
```

## Architecture

### Package Structure
- **Sources/ASC/**: Main library (15 files, 2,250 lines)
  - **Client/**: NetworkClient and components (5 files, 1,027 lines)
    - `NetworkClient.swift` - Main client (309 lines)
    - `MultipartRequestBuilder.swift` - File uploads (288 lines)
    - `ErrorMapper.swift` - Error mapping (164 lines)
    - `URLBuilder.swift` - URL construction (145 lines)
    - `NetworkClientConfiguration.swift` - Configuration (121 lines)
  - **Core/**: Protocols and types (5 files, 560 lines)
  - **Errors/**: Error types (4 files, 405 lines)
  - **Utils/**: Utility classes (1 file, 216 lines)
    - `NetworkReachability.swift` - Connectivity monitoring (216 lines)
- **Tests/ASCTests/**: Test suite (135 tests, 3,527 lines)
  - **Helpers/**: Test infrastructure (676 lines)
  - **Mocks/**: Mock implementations (266 lines)

### Dependencies
- **Alamofire** (5.10.2+): Core networking library
- **SwiftLint** (0.61.0+): Build-time linting

### Testing Framework
Uses Swift Testing framework (not XCTest). Tests use `@Test` attribute and `#expect` for assertions.

## Library Architecture

### Core Design: Protocol-Based Architecture

#### NetworkRequest Protocol
Defines all network request parameters:
- Base URL, path, HTTP method
- Headers, query parameters, body
- Response type (Codable)
- Retry policy, timeout configuration
- **Path parameters** for template substitution (`{userId}` → `123`)
- **Path prefix** for API versioning (`/api/v1`)
- **File uploads** via multipart/form-data

**Organization Pattern**: Use **Namespace Enum + Nested Structs**:
```swift
enum UserAPI {
    struct GetUser: NetworkRequest { /* ... */ }
    struct CreateUser: NetworkRequest { /* ... */ }
}
// Usage: client.execute(UserAPI.GetUser(userId: "123"))
```

#### NetworkClient Components

1. **URLBuilder** - URL Construction
   - Combines base URL with path and prefix
   - Substitutes path parameters
   - Validates and builds final URLs

2. **MultipartRequestBuilder** - File Uploads
   - Constructs multipart/form-data requests
   - Handles files with custom MIME types
   - Automatic encoding selection (memory vs file-based)

3. **ErrorMapper** - Error Translation
   - Maps Alamofire errors to ASC error types
   - Provides recovery suggestions

4. **NetworkClientConfiguration** - Configuration
   - Centralizes client settings
   - Manages interceptors, monitors, trust managers
   - Connectivity checking configuration

5. **NetworkReachability** - Connectivity Monitoring
   - Real-time network status monitoring via NWPathMonitor
   - Detects Wi-Fi, cellular, wired, and other connection types
   - Provides both sync (currentStatus) and async (statusStream) APIs
   - Automatic monitoring lifecycle (start/stop)

### Core Features

**1. Request/Response Interceptors**
- Pre-request modification (auth headers, signing)
- Post-response processing (logging, metrics)
- Error interception and retry logic

**2. Authentication System**
- Token-based authentication
- Automatic token refresh on 401
- Multiple authentication schemes

**3. Error Handling**
- `NetworkError`: Connection, timeout, SSL problems
- `ResponseError`: HTTP status, parsing failures
- `AuthenticationError`: Token expired, unauthorized
- All errors provide errorDescription, recoverySuggestion

**4. File Uploads**
Three-tier multipart/form-data support:
- `files`: Simple uploads (< 10MB, default MIME)
- `fileUploads`: Custom MIME types (< 10MB)
- `largeFileUploads`: File-based encoding (> 10MB, memory-efficient)

**5. Network Connectivity Monitoring**
Automatic connectivity checking before requests:
- Real-time monitoring via Apple's Network.framework
- Configurable via `connectivityCheckEnabled` (default: true)
- Throws `NetworkError.noConnection` immediately when offline
- Supports reactive monitoring via Combine and AsyncStream
- Connection type detection (Wi-Fi, cellular, wired, other)

**6. RetryPolicy**
Convenient factory methods for Alamofire.RetryPolicy:
- `.none` → No retry
- `.default` → 3 retries with exponential backoff
- `.aggressive` → 5 retries
- `.conservative` → 2 retries

**7. Built-in Debug Logger**
ASCLogger with emoji-enhanced visual output:
- OSLog integration for performance and privacy
- 5 log levels: none, error, info, debug, verbose
- Rich emoji visualization for better readability:
  - HTTP methods: 📥 GET, 📤 POST, 🔄 PUT, ✏️ PATCH, 🗑️ DELETE
  - Status codes: ✅ 200, 🎉 201, 🔐 401, 🔍 404, 💥 500
  - Performance: ⚡ fast, 🐌 slow, 🐢 very slow
  - Errors: 📡 no connection, ⏰ timeout, 🔒 SSL error
  - Data types: 📄 JSON, 📝 text, 💾 binary
- Privacy-aware: 🔒 auto-redacts sensitive headers
- See `LOGGER_EMOJIS.md` for complete emoji guide

## Architecture Decision: Type Re-exports

Instead of duplicating Alamofire types, ASC **re-exports them directly**:
- ✅ Uses battle-tested implementations from Alamofire
- ✅ Zero conversion overhead
- ✅ Automatic updates when Alamofire improves
- ✅ Focuses on unique value: protocol-based API, error handling

### Re-exported Types
- **HTTP**: `HTTPHeaders`, `HTTPHeader`, `HTTPMethod`
- **Parameters**: `Parameters`, `ParameterEncoding`, `JSONEncoding`, `URLEncoding`
- **Advanced**: `RequestInterceptor`, `EventMonitor`, `RetryPolicy`, `ServerTrustManager`

## Usage Examples

### Basic Usage

```swift
let client = NetworkClient(baseURL: "https://api.example.com")

enum UserAPI {
    struct GetUser: NetworkRequest {
        typealias Response = User
        let userId: String
        var path: String { "/users/\(userId)" }
        var method: HTTPMethod { .get }
    }
}

let user = try await client.execute(UserAPI.GetUser(userId: "123"))
```

### Advanced Configuration

```swift
// Custom interceptor for authentication
final class AuthInterceptor: RequestInterceptor {
    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, any Error>) -> Void) {
        var urlRequest = urlRequest
        urlRequest.headers.add(.authorization(bearerToken: getToken()))
        completion(.success(urlRequest))
    }
}

// Configure client
let config = NetworkClientConfiguration(
    baseURL: "https://api.example.com",
    interceptors: [AuthInterceptor()],
    eventMonitors: [Logger()],
    serverTrustManager: ServerTrustManager(evaluators: ["api.example.com": DefaultTrustEvaluator()])
)
let client = NetworkClient(configuration: config)
```

### Network Connectivity Monitoring

```swift
// Option 1: Automatic connectivity checking (enabled by default)
let config = NetworkClientConfiguration(
    baseURL: "https://api.example.com",
    connectivityCheckEnabled: true  // default value
)
let client = NetworkClient(configuration: config)

// Requests automatically fail fast when offline
do {
    let user = try await client.execute(UserAPI.GetUser(userId: "123"))
} catch NetworkError.noConnection {
    debugPrint("No internet connection available")
}

// Option 2: Manual monitoring with NetworkReachability
let reachability = NetworkReachability()
reachability.startMonitoring()

// Check current status
if case .reachable(let type) = reachability.currentStatus {
    debugPrint("Connected via \(type)")
}

// Monitor status changes
Task {
    for await status in reachability.statusStream {
        switch status {
        case .reachable(.wifi):
            debugPrint("Wi-Fi available")
        case .reachable(.cellular):
            debugPrint("Cellular available")
        case .unreachable:
            debugPrint("No connection")
        default:
            break
        }
    }
}
```

### Path Parameters & Prefix

```swift
enum UserAPIv1 {
    struct GetUser: NetworkRequest {
        typealias Response = User
        let userId: String
        var pathPrefix: String? { "/api/v1" }
        var path: String { "/users/{userId}" }
        var method: HTTPMethod { .get }
        var pathParameters: [String: String]? { ["userId": userId] }
    }
}

// Actual URL: https://api.example.com/api/v1/users/123
let user = try await client.execute(UserAPIv1.GetUser(userId: "123"))
```

### File Upload

```swift
enum UserAPI {
    struct UploadAvatar: NetworkRequest {
        typealias Response = User
        let userId: String
        let imageData: Data

        var path: String { "/users/{userId}/avatar" }
        var method: HTTPMethod { .post }
        var pathParameters: [String: String]? { ["userId": userId] }
        var fileUploads: [String: FileUpload]? {
            ["avatar": .jpeg(data: imageData, fileName: "avatar.jpg")]
        }
    }
}
```

### RetryPolicy Configuration

```swift
enum DataAPI {
    struct GetCriticalData: NetworkRequest {
        typealias Response = Data
        var path: String { "/critical-data" }
        var method: HTTPMethod { .get }
        var retryPolicy: Alamofire.RetryPolicy? { .aggressive } // 5 retries
    }
}
```

### Optional BaseURL

```swift
// Client without base URL
let client = NetworkClient()

// Request provides its own base URL
struct CustomRequest: NetworkRequest {
    typealias Response = User
    var baseURL: String? { "https://custom-api.example.com" }
    var path: String { "/users" }
    var method: HTTPMethod { .get }
}

let user = try await client.execute(CustomRequest())
```

## Code Standards

### SwiftLint Configuration
**Very strict** configuration enforced:
- **Force unwrapping/casting/try**: Errors (avoid `!`, `as!`, `try!`)
- **Line length**: 120 warning, 150 error
- **Function body length**: 50 warning, 100 error
- **Cyclomatic complexity**: 10 warning, 15 error
- **Function parameters**: 5 warning, 7 error
- **print() prohibited**: Use debugPrint/Logger instead
- **Documentation required**: All public APIs must have docs
- **Explicit ACL**: All declarations need access control

### Key Rules
- Prefer optional chaining over force unwrapping
- Use debugPrint instead of print
- Use Mutex instead of NSLock
- Keep functions under 50 lines
- Maximum 5 parameters per function
- Use MARK comments to organize code

## Code Quality Metrics

**Library Code:**
- 2,034 lines across 14 files
- Zero code duplication
- All public APIs documented
- Full Swift 6 concurrency support

**Test Suite:**
- 135 comprehensive tests, 100% pass rate
- 3,527 lines of test code
- Test infrastructure: 676 lines (helpers), 266 lines (mocks)
- Average test length: 15 lines

**Code Quality:**
- 0 SwiftLint warnings/errors
- Protocol-oriented design throughout
- Type-safe with comprehensive generics

## GitHub Integration

GitHub Actions configured for Claude Code:
- Claude responds to `@claude` mentions in issues/PRs
- Workflow: .github/workflows/claude.yml

---

**Last Updated**: October 20, 2025
**Maintained by**: ASC Development Team
