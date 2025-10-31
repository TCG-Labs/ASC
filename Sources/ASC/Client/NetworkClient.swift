// NetworkClient.swift
// ASC - Alamofire Swift Client
//
//  Copyright (c) 2025 TCG Labs
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

// Main network client for executing requests with advanced Alamofire features.

import Foundation

/// Main network client for executing requests.
///
/// The `NetworkClient` is the primary interface for making network requests.
/// It wraps Alamofire's `Session` and provides a type-safe, protocol-oriented API
/// with full access to Alamofire's advanced features.
///
/// Example:
/// ```swift
/// let config = NetworkClientConfiguration(
///     baseURL: "https://api.example.com",
///     interceptors: [MyAuthInterceptor()],
///     eventMonitors: [MyLogger()]
/// )
/// let client = NetworkClient(configuration: config)
/// let user = try await client.execute(GetUserRequest(userId: "123"))
/// ```
public final class NetworkClient: Sendable {
    // MARK: - Properties

    /// Client configuration.
    private let configuration: NetworkClientConfiguration

    /// Alamofire session used for networking.
    private let session: Session

    /// Request builder for constructing URLRequests.
    private let requestBuilder: RequestBuilder

    /// Error mapper for translating Alamofire errors.
    private let errorMapper: ErrorMapper

    /// Network reachability monitor (optional).
    private let reachability: NetworkReachability?

    // MARK: - Initialization

    /// Creates a new network client with the specified configuration.
    ///
    /// - Parameter configuration: Client configuration
    public init(configuration: NetworkClientConfiguration) {
        self.configuration = configuration
        self.errorMapper = ErrorMapper(defaultTimeout: configuration.defaultTimeout)

        self.requestBuilder = RequestBuilder(
            baseURL: configuration.baseURL,
            defaultHeaders: configuration.defaultHeaders,
            defaultTimeout: configuration.defaultTimeout,
            defaultCachePolicy: configuration.defaultCachePolicy,
            defaultDecoder: configuration.decoder
        )

        if configuration.connectivityCheckEnabled {
            let reachability = NetworkReachability()
            reachability.startMonitoring()
            self.reachability = reachability
        } else {
            self.reachability = nil
        }

        let urlConfig = configuration.urlSessionConfiguration
        urlConfig.timeoutIntervalForRequest = configuration.defaultTimeout
        urlConfig.timeoutIntervalForResource = configuration.defaultTimeout * 2

        self.session = Session(
            configuration: urlConfig,
            rootQueue: configuration.rootQueue,
            requestQueue: configuration.requestQueue,
            serializationQueue: configuration.serializationQueue,
            interceptor: Interceptor(interceptors: configuration.interceptors),
            serverTrustManager: configuration.serverTrustManager,
            redirectHandler: configuration.redirectHandler,
            cachedResponseHandler: configuration.cachedResponseHandler,
            eventMonitors: configuration.eventMonitors
        )
    }

    deinit { reachability?.stopMonitoring() }

    /// Convenience initializer with base URL only.
    ///
    /// - Parameter baseURL: Default base URL for requests
    public convenience init(baseURL: String) {
        self.init(configuration: .default(baseURL: baseURL))
    }

    /// Convenience initializer without base URL.
    ///
    /// Use this when each request will provide its own baseURL.
    public convenience init() {
        self.init(configuration: .default(baseURL: nil))
    }

    // MARK: - Public Methods

    /// Executes a network request and returns the decoded response.
    ///
    /// - Parameter request: The request to execute
    /// - Returns: Decoded response of type `Request.Response`
    /// - Throws: `ASCError`
    public func execute<Request: NetworkRequest>(
        _ request: Request
    ) async throws -> Request.Response {
        guard let response = try await executeRequest(request, responseType: Request.Response.self) else {
            throw ASCError.missingData
        }
        return response
    }

    /// Executes a network request without expecting a response body.
    ///
    /// Useful for requests that return 204 No Content or similar.
    ///
    /// - Parameter request: The request to execute
    /// - Throws: `ASCError`
    public func execute<Request: NetworkRequest>(
        _ request: Request
    ) async throws where Request.Response == ASCEmptyResponse {
        _ = try await executeRequest(request, responseType: nil as ASCEmptyResponse.Type?)
    }

    // MARK: - Private Methods

    /// Executes a network request.
    ///
    /// Centralized request execution that handles both response types.
    /// - Parameters:
    ///   - request: The network request to execute
    ///   - responseType: Expected response type, or nil for empty response
    /// - Returns: Decoded response, or nil for empty response
    /// - Throws: `ASCError`
    private func executeRequest<Request: NetworkRequest, Response: Decodable & Sendable>(
        _ request: Request,
        responseType: Response.Type?
    ) async throws -> Response? where Request.Response == Response {
        let urlRequest = try requestBuilder.buildURLRequest(from: request)

        if let responseType = responseType {
            return try await performRequest(
                request,
                urlRequest: urlRequest,
                responseType: responseType,
                retryPolicy: request.retryPolicy
            )
        } else {
            try await performEmptyRequest(urlRequest, retryPolicy: request.retryPolicy)
            return nil
        }
    }

    /// Performs the actual network request using Alamofire.
    ///
    /// Supports Task cancellation - when the Swift Task is cancelled,
    /// the underlying Alamofire request is automatically cancelled.
    ///
    /// Calls request.validate() on successful response.
    private func performRequest<Request: NetworkRequest, Response: Decodable & Sendable>(
        _ request: Request,
        urlRequest: URLRequest,
        responseType: Response.Type,
        retryPolicy: Alamofire.RetryPolicy?
    ) async throws -> Response where Request.Response == Response {
        try Task.checkCancellation()
        try checkConnectivity()

        // Use request's retry policy, fallback to configuration default
        let effectiveRetryPolicy = retryPolicy ?? configuration.defaultRetryPolicy

        var interceptors: [any RequestInterceptor] = []
        if let effectiveRetryPolicy {
            interceptors.append(effectiveRetryPolicy)
        }
        if let authInterceptor = configuration.authInterceptor {
            interceptors.append(authInterceptor)
        }
        let interceptor: Interceptor = .init(interceptors: interceptors)
        let dataRequest = session.request(urlRequest, interceptor: interceptor)

        // Set request priority
        dataRequest.task?.priority = configuration.defaultPriority

        // Apply automatic validation if enabled
        let validatedRequest = configuration.automaticValidation
            ? dataRequest.validate(statusCode: configuration.acceptableStatusCodes)
            : dataRequest

        let serializedRequest = validatedRequest.serializingDecodable(
            Response.self,
            decoder: configuration.decoder
        )

        return try await withTaskCancellationHandler {
            let response = await serializedRequest.response
            let value = try handleResponse(response)

            try request.validate(response: value)

            return value
        } onCancel: {
            dataRequest.cancel()
        }
    }

    /// Performs a request without expecting a response body.
    ///
    /// Supports Task cancellation - when the Swift Task is cancelled,
    /// the underlying Alamofire request is automatically cancelled.
    private func performEmptyRequest(
        _ urlRequest: URLRequest,
        retryPolicy: Alamofire.RetryPolicy?
    ) async throws {
        try Task.checkCancellation()
        try checkConnectivity()

        // Use request's retry policy, fallback to configuration default
        let effectiveRetryPolicy = retryPolicy ?? configuration.defaultRetryPolicy

        let dataRequest = session.request(urlRequest, interceptor: effectiveRetryPolicy)

        // Set request priority
        dataRequest.task?.priority = configuration.defaultPriority

        // Apply automatic validation if enabled
        let validatedRequest = configuration.automaticValidation
            ? dataRequest.validate(statusCode: configuration.acceptableStatusCodes)
            : dataRequest

        let serializedRequest = validatedRequest.serializingData()

        try await withTaskCancellationHandler {
            let response = await serializedRequest.response
            try validateResponse(response)
        } onCancel: {
            dataRequest.cancel()
        }
    }

    // MARK: - Response Handling

    /// Validates response and extracts value.
    ///
    /// Checks for errors and ensures response value is present.
    ///
    /// - Parameter response: Data response from Alamofire
    /// - Returns: Extracted response value
    /// - Throws: Mapped error or ASCError.missingData
    private func handleResponse<T>(_ response: DataResponse<T, AFError>) throws -> T {
        if let error = response.error {
            throw errorMapper.mapError(error, data: response.data)
        }

        guard let value = response.value else {
            throw ASCError.missingData
        }

        return value
    }

    /// Validates response for empty responses.
    ///
    /// Checks for errors in responses without expected body.
    ///
    /// - Parameter response: Data response from Alamofire
    /// - Throws: Mapped error if present
    private func validateResponse(_ response: DataResponse<Data, AFError>) throws {
        if let error = response.error {
            throw errorMapper.mapError(error, data: response.data)
        }
    }

    // MARK: - Connectivity Check

    /// Checks network connectivity before making a request.
    /// - Throws: ASCError.noConnection if no connection available
    private func checkConnectivity() throws {
        guard let reachability = reachability else { return }

        if case .unreachable = reachability.currentStatus {
            throw ASCError.noConnection
        }
    }
}

// MARK: - EmptyResponse

/// A response type for requests that don't return a body.
///
/// Use this for requests that return 204 No Content or when you
/// don't need to parse the response.
public struct ASCEmptyResponse: Codable, Sendable {
    public init() {}
}

/// Type alias for backward compatibility.
public typealias EmptyResponse = ASCEmptyResponse
