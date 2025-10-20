// AdvancedExample.swift
// ASC - Advanced Features (Interceptors, Monitors, Configuration)

import Alamofire
import ASC
import Foundation

// MARK: - Model

struct Post: Codable, Sendable {
    let id: Int?
    let userId: Int
    let title: String
    let body: String
}

// MARK: - Custom Interceptor

final class AuthInterceptor: RequestInterceptor {
    private var token: String?

    init(token: String? = nil) {
        self.token = token
    }

    func adapt(
        _ urlRequest: URLRequest,
        for session: Session,
        completion: @escaping (Result<URLRequest, any Error>) -> Void
    ) {
        var urlRequest = urlRequest
        if let token = token {
            urlRequest.headers.add(.authorization(bearerToken: token))
        }
        urlRequest.headers.add(name: "X-Client-Version", value: "1.0.0")
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
            debugPrint("Token expired, retrying...")
            completion(.retryWithDelay(1.0))
        } else {
            completion(.doNotRetry)
        }
    }

    func updateToken(_ newToken: String) {
        token = newToken
    }
}

// MARK: - Custom EventMonitor

final class PerformanceMonitor: EventMonitor {
    private var startTimes: [String: Date] = [:]

    func requestDidResume(_ request: Request) {
        let id = ObjectIdentifier(request).debugDescription
        startTimes[id] = Date()
        debugPrint("⏱️  Request started: \(request.description)")
    }

    func request<Value>(
        _ request: DataRequest,
        didParseResponse response: DataResponse<Value, AFError>
    ) {
        let id = ObjectIdentifier(request).debugDescription
        if let start = startTimes[id] {
            let duration = Date().timeIntervalSince(start)
            debugPrint("⏱️  Completed in \(String(format: "%.2f", duration))s")
            startTimes.removeValue(forKey: id)
        }
        if let statusCode = response.response?.statusCode {
            let emoji = statusCode < 300 ? "✅" : "⚠️"
            debugPrint("\(emoji) Status: \(statusCode)")
        }
    }
}

// MARK: - API

enum PostAPI {
    struct Get: NetworkRequest {
        typealias Response = Post
        let postId: Int

        var path: String { "/posts/{id}" }
        var method: HTTPMethod { .get }
        var pathParameters: [String: String]? { ["id": String(postId)] }
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
        var timeout: TimeInterval? { 30.0 }
        var retryPolicy: Alamofire.RetryPolicy? { .aggressive }
    }
}

// MARK: - Advanced Service

@MainActor
func runAdvancedExamples() async throws {
    debugPrint("=== ASC Advanced Features ===\n")

    let authInterceptor = AuthInterceptor(token: "demo-token-123")
    let performanceMonitor = PerformanceMonitor()

    let config = NetworkClientConfiguration(
        baseURL: "https://jsonplaceholder.typicode.com",
        defaultTimeout: 60.0,
        defaultHeaders: HTTPHeaders([
            .accept("application/json"),
            .contentType("application/json"),
        ]),
        interceptors: [authInterceptor],
        eventMonitors: [performanceMonitor]
    )

    let client = NetworkClient(configuration: config)

    debugPrint("1. Request with interceptor and monitor:")
    let post = try await client.execute(PostAPI.Get(postId: 1))
    debugPrint("   Fetched: \(post.title)\n")

    debugPrint("2. Request with aggressive retry policy:")
    let newPost = try await client.execute(
        PostAPI.Create(userId: 1, title: "Test", body: "Content")
    )
    debugPrint("   Created: #\(newPost.id ?? 0)\n")

    debugPrint("3. Token refresh:")
    authInterceptor.updateToken("new-token-456")
    debugPrint("   Token updated\n")

    debugPrint("=== Advanced features demonstrated ===")
}
