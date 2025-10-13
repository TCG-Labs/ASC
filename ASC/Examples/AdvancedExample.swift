// AdvancedExample.swift
// ASC - Advanced Features Example
//
// This example demonstrates advanced ASC features:
// - Custom Request Interceptors (authentication, logging)
// - Event Monitors (request tracking)
// - Custom Configuration
// - Retry Policies
// - Error Recovery

import Alamofire
import ASC
import Foundation

// MARK: - Models

struct Post: Codable, Sendable {
    let id: Int?
    let userId: Int
    let title: String
    let body: String
}

// MARK: - Custom Interceptors

/// Interceptor that adds authentication headers to requests
final class AuthenticationInterceptor: RequestInterceptor {
    private var accessToken: String?

    init(accessToken: String? = nil) {
        self.accessToken = accessToken
    }

    func adapt(
        _ urlRequest: URLRequest,
        for session: Session,
        completion: @escaping (Result<URLRequest, any Error>) -> Void
    ) {
        var urlRequest = urlRequest

        // Add authentication header if token is available
        if let token = accessToken {
            urlRequest.headers.add(.authorization(bearerToken: token))
            debugPrint("🔐 Added auth token to request")
        }

        // Add custom headers
        urlRequest.headers.add(name: "X-Client-Version", value: "1.0.0")
        urlRequest.headers.add(name: "X-Platform", value: "iOS")

        completion(.success(urlRequest))
    }

    func retry(
        _ request: Request,
        for session: Session,
        dueTo error: any Error,
        completion: @escaping (RetryResult) -> Void
    ) {
        // Check if this is a 401 Unauthorized error
        if let response = request.task?.response as? HTTPURLResponse,
           response.statusCode == 401 {
            debugPrint("🔄 Token expired, refreshing...")

            // In a real app, you would refresh the token here
            // For demo purposes, we'll just retry once
            completion(.retryWithDelay(1.0))
        } else {
            completion(.doNotRetry)
        }
    }

    // Update the token (e.g., after refresh)
    func updateToken(_ newToken: String) {
        self.accessToken = newToken
        debugPrint("✅ Token updated")
    }
}

/// Interceptor that logs all requests
final class LoggingInterceptor: RequestInterceptor {
    func adapt(
        _ urlRequest: URLRequest,
        for session: Session,
        completion: @escaping (Result<URLRequest, any Error>) -> Void
    ) {
        // Log the request
        debugPrint("📤 Request: \(urlRequest.httpMethod ?? "?") \(urlRequest.url?.absoluteString ?? "?")")

        if let headers = urlRequest.allHTTPHeaderFields, !headers.isEmpty {
            debugPrint("📋 Headers:")
            headers.forEach { key, value in
                // Mask sensitive information
                let displayValue = key.lowercased().contains("auth") ? "***" : value
                debugPrint("   \(key): \(displayValue)")
            }
        }

        completion(.success(urlRequest))
    }
}

// MARK: - Custom Event Monitor

/// Monitor that tracks request lifecycle and performance
final class PerformanceMonitor: EventMonitor {
    private var requestStartTimes: [String: Date] = [:]

    func requestDidResume(_ request: Request) {
        let requestId = ObjectIdentifier(request).debugDescription
        requestStartTimes[requestId] = Date()

        debugPrint("⏱️  Request started: \(request.description)")
    }

    func request<Value>(
        _ request: DataRequest,
        didParseResponse response: DataResponse<Value, AFError>
    ) {
        let requestId = ObjectIdentifier(request).debugDescription

        if let startTime = requestStartTimes[requestId] {
            let duration = Date().timeIntervalSince(startTime)
            debugPrint("⏱️  Request completed in \(String(format: "%.2f", duration))s")
            requestStartTimes.removeValue(forKey: requestId)
        }

        if let statusCode = response.response?.statusCode {
            let emoji = statusCode < 300 ? "✅" : (statusCode < 500 ? "⚠️" : "❌")
            debugPrint("\(emoji) Response: \(statusCode)")
        }
    }

    func request(
        _ request: Request,
        didCompleteTask task: URLSessionTask,
        with error: AFError?
    ) {
        if let error = error {
            debugPrint("❌ Request failed: \(error.localizedDescription)")
        }
    }
}

// MARK: - Requests

/// Post API using Namespace Enum pattern
enum PostAPI {
    struct Get: NetworkRequest {
        typealias Response = Post
        let postId: Int

        var path: String { "/posts/{id}" }
        var method: HTTPMethod { .get }
        var pathParameters: [String: String]? {
            ["id": String(postId)]
        }

        // Custom retry policy for this specific request
        var retryPolicy: Alamofire.RetryPolicy? { .default }
    }

    struct Create: NetworkRequest {
        typealias Response = Post
        let userId: Int
        let title: String
        let body: String

        var path: String { "/posts" }
        var method: HTTPMethod { .post }
        var parameters: Parameters? {
            ["userId": userId, "title": title, "body": body]
        }

        // Custom timeout for this request
        var timeout: TimeInterval? { 30.0 }

        // Aggressive retry policy
        var retryPolicy: Alamofire.RetryPolicy? { .aggressive }
    }
}

// MARK: - Advanced Service

@MainActor
class AdvancedAPIService {
    private let client: NetworkClient
    private let authInterceptor: AuthenticationInterceptor

    init() {
        // Create custom interceptors
        self.authInterceptor = AuthenticationInterceptor(accessToken: "demo-token-123")
        let loggingInterceptor = LoggingInterceptor()

        // Create performance monitor
        let performanceMonitor = PerformanceMonitor()

        // Configure custom client
        let configuration = NetworkClientConfiguration(
            baseURL: "https://jsonplaceholder.typicode.com",
            defaultTimeout: 60.0,
            defaultHeaders: HTTPHeaders([
                .accept("application/json"),
                .contentType("application/json"),
                HTTPHeader(name: "X-App-Name", value: "ASC-Demo")
            ]),
            interceptors: [
                authInterceptor,
                loggingInterceptor
            ],
            eventMonitors: [
                performanceMonitor
            ]
        )

        self.client = NetworkClient(configuration: configuration)

        debugPrint("🚀 Advanced API Service initialized")
        debugPrint("   • Authentication: Enabled")
        debugPrint("   • Logging: Enabled")
        debugPrint("   • Performance Monitoring: Enabled")
        debugPrint()
    }

    // MARK: - Example Methods

    /// Fetch a post with full logging and monitoring
    func fetchPost(id: Int) async throws -> Post {
        debugPrint("\n📖 Fetching post #\(id)...")
        debugPrint("   • Retry policy: Enabled (max 3 attempts)")
        debugPrint("   • Timeout: 60s")
        debugPrint()

        let post = try await client.execute(PostAPI.Get(postId: id))

        debugPrint("\n✅ Successfully fetched post:")
        debugPrint("   • Title: \(post.title)")
        debugPrint("   • User ID: \(post.userId)")
        debugPrint()

        return post
    }

    /// Create a post with aggressive retry
    func createPost(title: String, body: String) async throws -> Post {
        debugPrint("\n✍️  Creating post...")
        debugPrint("   • Retry policy: Aggressive (max 5 attempts)")
        debugPrint("   • Timeout: 30s")
        debugPrint()

        let post = try await client.execute(
            PostAPI.Create(userId: 1, title: title, body: body)
        )

        debugPrint("\n✅ Successfully created post:")
        debugPrint("   • ID: \(post.id ?? 0)")
        debugPrint("   • Title: \(post.title)")
        debugPrint()

        return post
    }

    /// Demonstrate token refresh
    func demonstrateTokenRefresh() async {
        debugPrint("\n🔄 Demonstrating token refresh...")
        debugPrint()

        // Update the token
        authInterceptor.updateToken("new-refreshed-token-456")

        // Make a request with the new token
        do {
            _ = try await fetchPost(id: 1)
        } catch {
            debugPrint("❌ Error: \(error.localizedDescription)")
        }
    }

    /// Demonstrate concurrent requests with monitoring
    func fetchMultiplePostsConcurrently() async throws {
        debugPrint("\n⚡ Fetching 3 posts concurrently...")
        debugPrint("   • Each request is logged and monitored")
        debugPrint()

        let postIds = [1, 2, 3]

        let posts = try await withThrowingTaskGroup(of: Post.self) { group in
            for postId in postIds {
                group.addTask {
                    try await self.client.execute(PostAPI.Get(postId: postId))
                }
            }

            var results: [Post] = []
            for try await post in group {
                results.append(post)
            }
            return results
        }

        debugPrint("\n✅ Fetched \(posts.count) posts concurrently")
        posts.forEach { post in
            debugPrint("   • [\(post.id ?? 0)] \(post.title)")
        }
        debugPrint()
    }

    /// Demonstrate retry behavior
    func demonstrateRetry() async {
        debugPrint("\n🔄 Demonstrating retry behavior...")
        debugPrint("   • Will attempt to fetch non-existent resource")
        debugPrint("   • Should retry 3 times before failing")
        debugPrint()

        do {
            // This will fail with 404, but won't retry (404 is not retryable)
            _ = try await client.execute(PostAPI.Get(postId: 99999))
        } catch let error as ResponseError {
            debugPrint("\n❌ Request failed (as expected):")
            debugPrint("   • Error: \(error.errorDescription ?? "Unknown")")
            debugPrint("   • Note: 404 errors are not retryable by design")
        } catch {
            debugPrint("\n❌ Unexpected error: \(error)")
        }
        debugPrint()
    }
}

// MARK: - Advanced Examples Runner

@MainActor
func runAdvancedExamples() async {
    debugPrint("=" * 70)
    debugPrint("ASC Library - Advanced Features Example")
    debugPrint("=" * 70)
    debugPrint()

    let service = AdvancedAPIService()

    do {
        // Example 1: Fetch with monitoring and logging
        _ = try await service.fetchPost(id: 1)

        // Wait a bit to see the output clearly
        try? await Task.sleep(for: .seconds(1))

        // Example 2: Create with aggressive retry
        _ = try await service.createPost(
            title: "Advanced ASC Example",
            body: "Demonstrating interceptors, monitors, and custom configuration"
        )

        try? await Task.sleep(for: .seconds(1))

        // Example 3: Token refresh
        await service.demonstrateTokenRefresh()

        try? await Task.sleep(for: .seconds(1))

        // Example 4: Concurrent requests
        try await service.fetchMultiplePostsConcurrently()

        try? await Task.sleep(for: .seconds(1))

        // Example 5: Retry behavior
        await service.demonstrateRetry()

        debugPrint("=" * 70)
        debugPrint("✅ Advanced examples completed!")
        debugPrint("=" * 70)

    } catch {
        debugPrint("\n❌ Example failed:")
        debugPrint(error)
    }
}

// Helper
extension String {
    static func * (left: String, right: Int) -> String {
        String(repeating: left, count: right)
    }
}

// MARK: - Usage

/*
 To run these advanced examples:

 ```swift
 Task {
     await runAdvancedExamples()
 }
 ```

 What you'll learn:
 - ✅ Creating custom RequestInterceptors for auth and logging
 - ✅ Implementing EventMonitors for performance tracking
 - ✅ Configuring retry policies per-request
 - ✅ Setting custom timeouts
 - ✅ Managing authentication tokens
 - ✅ Concurrent request handling with monitoring

 These patterns are production-ready and can be adapted to your needs!
 */
