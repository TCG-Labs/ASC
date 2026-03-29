# ASC - Alamofire Swift Client

## Project Info

- **Type:** SPM Library (open-source, MIT)
- **Package name:** ASC
- **Scheme:** ASC (SPM scheme)
- **Main target:** ASC
- **Test target:** ASCTests
- **Minimum deployment:** iOS 18.0 / macOS 15.0
- **Swift tools version:** 6.2
- **Swift concurrency:** strict (`Sendable` throughout)

## Architecture

Single-module SPM library, no Clean Architecture layers. Flat structure:

```
Sources/ASC/
  Auth/          — Token storage, interceptors, OAuth authenticator
  Client/        — NetworkClient (main entry point), configuration, error mapper
  Core/          — Endpoint protocol, error types, HTTP types, request builder
  EventMonitors/ — Logging, response monitoring
  Extensions/    — Data, HTTPURLResponse, RetryPolicy helpers
  Utils/         — NetworkReachability, typealiases
```

**Key types:**
- `NetworkClient` — main public API, wraps Alamofire `Session`
- `Endpoint` — protocol for defining type-safe requests (associated types `Request`/`Response`)
- `NetworkClientConfiguration` — configuration builder with presets (`.default`, `.development`, `.production`, `.testing`)
- `ASCError` — unified error enum with `LocalizedError` conformance
- `AuthInterceptor` / `OAuthAuthenticator` — auth via `TokenStorage` / `OAuthTokenStorage` protocols
- `LoggingMonitor` — built-in os.Logger-based request/response logger

## Dependencies

| Package | Version | Purpose |
|---|---|---|
| Alamofire | >= 5.10.2 | HTTP networking |
| JWTDecode.swift | 3.3.0 (exact) | JWT token expiration parsing in `OAuthCredential` |

## Build & Test

```bash
# Build
swift build

# Test
swift test
```

Or via Xcode: scheme `ASC`, test target `ASCTests`.

SwiftLint runs as a Build Phase, violations appear in build output.

## Conventions

- All public types are `Sendable` (Swift 6 strict concurrency)
- `NetworkClient` is `final class`, thread-safe
- Auth types use `@unchecked Sendable` where Alamofire protocols demand completion handlers
- Internal types (`ErrorMapper`, `RequestBuilder`) are `internal`/`struct`/`final class`
- os.Logger subsystem: `com.asc.networking`, category: `NetworkClient`
- MIT license header required in all source files (see `scripts/add_license_headers.sh`)
- JSON: snake_case keys, ISO8601 dates by default (configurable via `NetworkClientConfiguration`)
- `Empty` (Alamofire) used as `Request`/`Response` associated type for endpoints without parameters/body

## Known Decisions

- `OAuthCredential.requiresRefresh` uses 14-minute window (hardcoded, not 5 min as the comment suggests) — intentional for current backend
- `OAuthAuthenticator.didRequest(_:with:failDueToAuthenticationError:)` returns `false` — server does not invalidate credentials; refresh triggered only by `requiresRefresh`
- `executeWithProgress` is commented out — API not finalized
- `ErrorMapper.findMessage(in:)` uses recursive JSON traversal to extract error messages from arbitrary server response formats
- Download methods return `URL?` (destination file URL), not decoded response

## Fragile Areas

- `LoggingMonitor` is `/*public*/` — visibility intentionally restricted, may become public later
- `AuthInterceptor.adapt` fails with `.invalidToken` when token is nil, not silently skipping — consumers must handle this
- `NetworkReachability` uses NWPathMonitor under the hood; `startMonitoring`/`stopMonitoring` lifecycle tied to `NetworkClient` init/deinit

## Example App

Located in `Examples/TestExample/` — standalone Xcode project (not part of SPM package). Uses ASC via local package dependency. Contains examples for:
- Basic requests (`UsersViewModel`)
- Downloads (`DownloadExampleView/ViewModel`)
- Unauthorized status handling (`UnauthorizedStatusExampleView/ViewModel`)
