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
- **Version**: 1.0
- **Status**: Production-ready
- **Test Coverage**: 112 tests in 6 suites, 100% pass rate
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
- **Sources/ASC/**: Main library (13 files, ~2,915 lines)
  - **Auth/**: Authentication (3 files, 236 lines)
    - `AuthInterceptor.swift` - Token refresh (98 lines)
    - `TokenStorage.swift` - Token storage protocol (43 lines)
    - `TokenType.swift` - Token types (56 lines)
  - **Client/**: NetworkClient and components (5 files, ~1,557 lines)
    - `NetworkClient.swift` - Main client (455 lines)
    - `NetworkClientConfiguration.swift` - Configuration (463 lines)
    - `ErrorMapper.swift` - Error mapping (157 lines)
    - `ASCLogger.swift` - Debug logging with request correlation (377 lines)
    - `URLBuilder.swift` - URL construction (69 lines)
  - **Core/**: Protocols and types (3 files, ~305 lines)
    - `NetworkRequest.swift` - Request protocol + Alamofire re-export (187 lines)
    - `ResponseTypes.swift` - HTTP types (67 lines)
    - `RetryPolicy.swift` - Retry helpers (51 lines)
  - **Errors/**: Error types (1 file, 271 lines)
    - `ASCError.swift` - Unified error handling (271 lines)
  - **Utils/**: Utility classes (1 file, 216 lines)
    - `NetworkReachability.swift` - Connectivity monitoring (216 lines)
- **Tests/ASCTests/**: Test suite (112 tests, 6 suites)
  - Core tests: ASCErrorTests (27), NetworkRequestTests (21), URLBuilderTests (10)
  - Component tests: ErrorMapperTests (28), NetworkClientTests (17), AuthInterceptorTests (9)
  - **Helpers/**: Test utilities (TestHelpers.swift)
  - **Mocks/**: Mock implementations (MockURLProtocol, MockNetworkRequest, MockTokenStorage)

### Dependencies
- **Alamofire** (5.10.2+): Core networking library
- **SwiftLint** (0.61.0+): Build-time linting

### Testing Framework
Uses Swift Testing framework (not XCTest). Tests use `@Test` attribute and `#expect` for assertions.

**Mock Infrastructure:**
- **MockURLProtocol**: Thread-safe HTTP response mocking using `Mutex<T>` for Swift 6 concurrency
- **MockNetworkRequest**: Reusable request types (GET, POST, authenticated, empty, validated, custom encoded)
- **MockTokenStorage**: Thread-safe token storage for authentication testing
- **TestHelpers**: Factory methods for creating test data, responses, and errors

**Test Patterns:**
- `.serialized` trait for tests requiring sequential execution (prevents race conditions)
- `defer { MockURLProtocol.reset() }` pattern for guaranteed cleanup
- `withCheckedThrowingContinuation` for async adapter testing
- `await #expect(throws: ASCError.self)` for error validation

## Library Architecture

### Core Design: Protocol-Based Architecture

#### NetworkRequest Protocol
Defines all network request parameters:
- Base URL, path, HTTP method
- Headers, query parameters, body
- Response type (Codable)
- Retry policy, timeout configuration

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
   - Combines base URL with path
   - Validates and builds final URLs

2. **ErrorMapper** - Error Translation
   - Maps Alamofire errors to ASC error types
   - Provides recovery suggestions

3. **NetworkClientConfiguration** - Configuration
   - Centralizes client settings
   - Manages interceptors, monitors, trust managers
   - Connectivity checking configuration

4. **NetworkReachability** - Connectivity Monitoring
   - Real-time network status monitoring via NWPathMonitor
   - Detects Wi-Fi, cellular, wired, and other connection types
   - Provides both sync (currentStatus) and async (statusStream) APIs
   - Automatic monitoring lifecycle (start/stop)

5. **ASCLogger** - Debug Logging
   - OSLog-based logging with emoji-enhanced output
   - 5 log levels with privacy-aware redaction
   - Visual indicators for methods, status codes, performance
   - Request correlation tracking with numbered requests (#1, #2, etc)
   - Thread-safe request tracking using Mutex
   - Automatic memory management (prevents leaks in long-running apps)

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
Unified `ASCError` enum with three categories:
- **Network Errors**: Connection, timeout, SSL problems
- **Response Errors**: HTTP status, parsing failures
- **Authentication Errors**: Token expired, unauthorized
- All errors provide errorDescription, recoverySuggestion, and failureReason

**4. Network Connectivity Monitoring**
Automatic connectivity checking before requests:
- Real-time monitoring via Apple's Network.framework
- Configurable via `connectivityCheckEnabled` (default: true)
- Throws `ASCError.noConnection` immediately when offline
- Supports reactive monitoring via AsyncStream
- Connection type detection (Wi-Fi, cellular, wired, other)

**5. RetryPolicy**
Convenient factory methods for Alamofire.RetryPolicy:
- `.none` → No retry
- `.default` → 3 retries with exponential backoff
- `.aggressive` → 5 retries
- `.conservative` → 2 retries
- Can be set globally via `defaultRetryPolicy` in configuration

**6. Advanced Configuration Options**
- **JSON Coding**: Custom JSONDecoder/JSONEncoder with configurable strategies
- **Session Types**: Default, ephemeral (private), or background sessions
- **Network Constraints**: Control cellular, expensive, and constrained network access
- **Automatic Validation**: HTTP status code validation with custom acceptable ranges
- **Request Priority**: Set default priority for all network requests
- **Preset Configurations**: `.development`, `.production`, `.testing` for quick setup

**7. Built-in Debug Logger**
ASCLogger with emoji-enhanced visual output:
- OSLog integration for performance and privacy
- 5 log levels: none, error, info, debug, verbose
- **Request correlation tracking**: Numbered requests (#1, #2) for easy debugging
- **Thread-safe**: Uses Mutex for concurrent request tracking
- **Memory efficient**: Automatic cleanup prevents leaks in long-running apps
- Rich emoji visualization for better readability:
  - HTTP methods: 📥 GET, 📤 POST, 🔄 PUT, ✏️ PATCH, 🗑️ DELETE
  - Status codes: ✅ 200, 🎉 201, 🔐 401, 🔍 404, 💥 500
  - Performance: ⚡ fast, 🐌 slow, 🐢 very slow
  - Errors: 📡 no connection, ⏰ timeout, 🔒 SSL error
  - Data types: 📄 JSON, 📝 text, 💾 binary
- Privacy-aware: 🔒 auto-redacts sensitive headers
- See `LOGGER_EMOJIS.md` for complete emoji guide

## Architecture Decision: @_exported import Alamofire

ASC uses `@_exported import Alamofire` to **re-export all Alamofire types**:
- ✅ **No need to import Alamofire** - all types available when you `import ASC`
- ✅ Uses battle-tested implementations from Alamofire
- ✅ Zero conversion overhead
- ✅ Automatic updates when Alamofire improves
- ✅ Minimal imports inside library - only NetworkRequest.swift imports Alamofire

### How It Works
- **NetworkRequest.swift** uses `@_exported import Alamofire`
- All other library files don't need to import Alamofire
- When users `import ASC`, they get all Alamofire types automatically

### Available Types (via re-export)
All Alamofire types are available including:
- `HTTPMethod`, `HTTPHeaders`, `HTTPHeader`
- `Parameters`, `ParameterEncoding`, `JSONEncoding`, `URLEncoding`
- `RequestInterceptor`, `EventMonitor`, `RetryPolicy`
- `ServerTrustManager`, `RedirectHandler`, `CachedResponseHandler`
- `Session`, `DataRequest`, `UploadRequest`, and all other Alamofire types

### Public Typealiases
For commonly used types, ASC also defines typealiases in **NetworkRequest.swift** for better discoverability:
- `HTTPMethod`, `HTTPHeaders`, `HTTPHeader`
- `Parameters`, `ParameterEncoding`, `JSONEncoding`, `URLEncoding`
- `RetryPolicy`, `RequestInterceptor`, `EventMonitor`
- `ServerTrustManager`, `RedirectHandler`, `CachedResponseHandler`, `Interceptor`

## Usage Examples

**Note**: Only `import ASC` is needed - all Alamofire types are automatically available via `@_exported import`.

### Basic Usage

```swift
import ASC

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

### Preset Configurations

ASC provides three preset configurations optimized for different environments:

```swift
import ASC

// 1. Development - verbose logging, relaxed timeouts
let client = NetworkClient(configuration: .development(baseURL: "https://dev-api.example.com"))
// Features: verbose logging, 120s timeout, no retries

// 2. Production - optimized for performance
let client = NetworkClient(configuration: .production(baseURL: "https://api.example.com"))
// Features: error-only logging, 30s timeout, conservative retries

// 3. Testing - minimal overhead for unit tests
let client = NetworkClient(configuration: .testing(baseURL: "http://localhost:8080"))
// Features: no logging, 10s timeout, connectivity check disabled

// 4. Default - customizable defaults
let client = NetworkClient(configuration: .default(
    baseURL: "https://api.example.com",
    logLevel: .debug,
    timeout: 90,
    retryPolicy: .default
))
```

### Advanced Configuration

```swift
import ASC

// Custom JSON decoder/encoder (or use defaults)
let decoder = JSONDecoder()
decoder.dateDecodingStrategy = .secondsSince1970
decoder.keyDecodingStrategy = .useDefaultKeys

let encoder = JSONEncoder()
encoder.dateEncodingStrategy = .secondsSince1970

// Custom interceptor for authentication
final class AuthInterceptor: RequestInterceptor {
    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, any Error>) -> Void) {
        var urlRequest = urlRequest
        urlRequest.headers.add(.authorization(bearerToken: getToken()))
        completion(.success(urlRequest))
    }
}

// Network constraints configuration
let networkConstraints = NetworkConstraints(
    waitsForConnectivity: true,
    allowsCellularAccess: true,
    allowsExpensiveNetworkAccess: false,  // Save data on expensive networks
    allowsConstrainedNetworkAccess: false   // Respect Low Data Mode
)
// Or use presets: .default, .restrictive

// Validation configuration
let validation = ValidationOptions(
    isEnabled: true,
    acceptableStatusCodes: 200..<300
)
// Or use presets: .default, .disabled

// Full configuration with all options
let config = NetworkClientConfiguration(
    baseURL: "https://api.example.com",
    sessionType: .default,  // or .ephemeral, .background(identifier:)
    defaultTimeout: 60,
    defaultHeaders: .default,
    interceptors: [AuthInterceptor()],
    eventMonitors: [Logger()],
    serverTrustManager: ServerTrustManager(evaluators: ["api.example.com": DefaultTrustEvaluator()]),
    logLevel: .debug,
    decoder: decoder,  // or use NetworkClientConfigurationDefaults.decoder
    encoder: encoder,  // or use NetworkClientConfigurationDefaults.encoder
    defaultRetryPolicy: .conservative,
    networkConstraints: networkConstraints,
    validation: validation,
    defaultPriority: 0.7  // Higher priority for important requests
)
let client = NetworkClient(configuration: config)
```

**Key Configuration Features:**

1. **SessionType**: Choose between default, ephemeral (private), or background sessions
2. **JSON Coding**: Custom decoder/encoder or use `NetworkClientConfigurationDefaults` (ISO8601 + snake_case)
3. **Default Retry Policy**: Applied to all requests unless overridden
4. **NetworkConstraints**: Grouped network access settings with presets (`.default`, `.restrictive`)
5. **ValidationOptions**: Grouped validation settings with presets (`.default`, `.disabled`)
6. **Request Priority**: Set default priority for all requests (0.0-1.0)

### Network Connectivity Monitoring

```swift
import ASC

// Option 1: Automatic connectivity checking (enabled by default)
let config = NetworkClientConfiguration(
    baseURL: "https://api.example.com",
    connectivityCheckEnabled: true  // default value
)
let client = NetworkClient(configuration: config)

// Requests automatically fail fast when offline
do {
    let user = try await client.execute(UserAPI.GetUser(userId: "123"))
} catch ASCError.noConnection {
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

### RetryPolicy Configuration

```swift
import ASC

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
import ASC

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
- ~2,915 lines across 13 files
- Zero code duplication
- All public APIs documented
- Full Swift 6 concurrency support

**Test Suite:**
- 112 comprehensive tests across 6 suites, 100% pass rate
- Test framework: Swift Testing (not XCTest)
- Thread-safe mock infrastructure with `Mutex<T>`
- Test breakdown:
  - **Core Tests** (58 tests):
    - ASCErrorTests: 27 tests (error enum, descriptions, recovery suggestions)
    - NetworkRequestTests: 21 tests (protocol defaults, encoding, validation)
    - URLBuilderTests: 10 tests (URL construction, validation)
  - **Component Tests** (54 tests):
    - ErrorMapperTests: 28 tests (AFError/URLError mapping, error messages)
    - NetworkClientTests: 17 tests (initialization, request execution, retry, validation)
    - AuthInterceptorTests: 9 tests (token types, header injection, error handling)

**Code Coverage (Priority 1 Components):**
- ErrorMapper: 89.09% (was 1.82%)
- NetworkClient: 68.35% (was 6.33%)
- AuthInterceptor: 100% (was 0%)

**Code Quality:**
- 0 SwiftLint warnings/errors
- Protocol-oriented design throughout
- Type-safe with comprehensive generics
- All tests are honest (no tautological assertions)
- Consistent test patterns (defer cleanup, inline creation, minimal comments)

## GitHub Integration

GitHub Actions configured for Claude Code:
- Claude responds to `@claude` mentions in issues/PRs
- Workflow: .github/workflows/claude.yml

---

**Last Updated**: October 28, 2025
**Maintained by**: ASC Development Team
