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

# Run a specific test
swift test --filter ASCTests.example
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
- **ASC/Tests/ASCTests/**: Test suite using Swift Testing framework
- **ASC/Package.swift**: SPM configuration with Alamofire dependency

### Dependencies
- **Alamofire** (5.10.2+): Core networking library this package wraps
- **SwiftLint** (0.61.0+): Build-time linting via plugin

### Testing Framework
Uses Swift Testing framework (not XCTest). Tests use the `@Test` attribute and `#expect` for assertions.

## Library Architecture & Features

### Core Design: Protocol-Based Architecture

The library uses protocol-oriented design for maximum flexibility and testability:

#### NetworkRequest Protocol
Defines all network request parameters in a declarative way:
- Base URL, path, HTTP method
- Headers, query parameters, body
- Response type (Codable)
- Retry policy, timeout configuration

#### NetworkClient
Main client that executes requests using Alamofire:
- Async/await API
- Generic response handling
- Interceptor chain execution
- Error transformation

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
2. Apply RequestAdapters (add headers, auth)
3. Validate network reachability
4. Execute via Alamofire Session
5. Monitor via EventMonitors
6. Handle redirects via RedirectHandler
7. Validate response (status, content type)
8. Cache response via CachedResponseHandler
9. Serialize response (Codable, Data, String)
10. Retry on failure via RequestRetrier
11. Return typed Result/throw error
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

## GitHub Integration

The repository has GitHub Actions configured for Claude Code:
- Claude responds to `@claude` mentions in issues, PRs, and comments
- Workflow file: .github/workflows/claude.yml
