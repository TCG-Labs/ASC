// NetworkClient.swift
// ASC - Alamofire Swift Client

// Main network client for executing requests with advanced Alamofire features.

import Alamofire
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

    /// URL builder for constructing request URLs.
    private let urlBuilder: URLBuilder

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
        self.urlBuilder = URLBuilder()
        self.errorMapper = ErrorMapper(defaultTimeout: configuration.defaultTimeout)

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

    /// Checks if a request contains files and should use multipart encoding.
    ///
    /// - Parameter request: The network request to check
    /// - Returns: True if request contains any files, false otherwise
    private func isMultipartRequest<Request: NetworkRequest>(_ request: Request) -> Bool {
        request.files?.isEmpty == false
    }

    /// Executes a network request, handling both multipart and standard requests.
    ///
    /// Centralized request execution that routes to appropriate handler based on request type.
    /// - Parameters:
    ///   - request: The network request to execute
    ///   - responseType: Expected response type, or nil for empty response
    /// - Returns: Decoded response, or nil for empty response
    /// - Throws: `ASCError`
    private func executeRequest<Request: NetworkRequest, Response: Decodable & Sendable>(
        _ request: Request,
        responseType: Response.Type?
    ) async throws -> Response? where Request.Response == Response {
        if isMultipartRequest(request) {
            return try await performMultipartRequest(
                request,
                responseType: responseType,
                retryPolicy: request.retryPolicy
            )
        }

        let urlRequest = try buildURLRequest(from: request)

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

    /// Builds a URLRequest from a NetworkRequest.
    private func buildURLRequest<Request: NetworkRequest>(
        from request: Request
    ) throws -> URLRequest {
        let url = try urlBuilder.buildURL(
            from: request,
            baseURL: configuration.baseURL
        )

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.timeoutInterval = request.timeout ?? configuration.defaultTimeout
        urlRequest.cachePolicy = request.cachePolicy ?? configuration.defaultCachePolicy

        let headers = buildHeaders(for: request)
        for header in headers {
            urlRequest.setValue(header.value, forHTTPHeaderField: header.name)
        }

        if request.files == nil, let parameters = request.parameters {
            urlRequest = try request.parameterEncoding.encode(urlRequest, with: parameters)
        }

        return urlRequest
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

        let dataRequest = session.request(urlRequest, interceptor: effectiveRetryPolicy)

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

    /// Performs a multipart file upload request.
    ///
    /// Simple multipart upload using Alamofire directly.
    ///
    /// Supports Task cancellation - when the Swift Task is cancelled,
    /// the underlying Alamofire upload request is automatically cancelled.
    ///
    /// Calls request.validate() on successful response.
    private func performMultipartRequest<Request: NetworkRequest, Response: Decodable & Sendable>(
        _ request: Request,
        responseType: Response.Type?,
        retryPolicy: Alamofire.RetryPolicy?
    ) async throws -> Response? where Request.Response == Response {
        try Task.checkCancellation()
        try checkConnectivity()

        let url = try urlBuilder.buildURL(
            from: request,
            baseURL: configuration.baseURL
        )
        let headers = buildHeaders(for: request)

        // Use request's retry policy, fallback to configuration default
        let effectiveRetryPolicy = retryPolicy ?? configuration.defaultRetryPolicy

        // Build multipart upload using Alamofire directly
        let upload = session.upload(
            multipartFormData: { formData in
                // Add files
                if let files = request.files {
                    for (fieldName, data) in files {
                        formData.append(data, withName: fieldName, fileName: "file", mimeType: "application/octet-stream")
                    }
                }

                // Add parameters if any
                if let parameters = request.parameters {
                    for (key, value) in parameters {
                        if let data = "\(value)".data(using: .utf8) {
                            formData.append(data, withName: key)
                        }
                    }
                }
            },
            to: url,
            method: request.method,
            headers: headers,
            interceptor: effectiveRetryPolicy
        )

        // Set request priority
        upload.task?.priority = configuration.defaultPriority

        // Apply automatic validation if enabled
        let validatedUpload = configuration.automaticValidation
            ? upload.validate(statusCode: configuration.acceptableStatusCodes)
            : upload

        if let responseType = responseType {
            let uploadRequest = validatedUpload.serializingDecodable(
                responseType,
                decoder: configuration.decoder
            )

            return try await withTaskCancellationHandler {
                let response = await uploadRequest.response
                let value = try handleResponse(response)

                try request.validate(response: value)

                return value
            } onCancel: {
                upload.cancel()
            }
        } else {
            let uploadRequest = validatedUpload.serializingData()

            try await withTaskCancellationHandler {
                let response = await uploadRequest.response
                try validateResponse(response)
            } onCancel: {
                upload.cancel()
            }
            return nil
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

    // MARK: - Header Building

    /// Builds HTTP headers for a request.
    private func buildHeaders<Request: NetworkRequest>(for request: Request) -> HTTPHeaders {
        var headers = configuration.defaultHeaders

        if request.isAuthorized {
            headers.add(HeaderKeys.authorization)
        }

        if let requestHeaders = request.headers {
            for header in requestHeaders {
                headers.add(header)
            }
        }

        return headers
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
