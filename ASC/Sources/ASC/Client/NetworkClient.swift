// NetworkClient.swift
// ASC - Alamofire Swift Client

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

        // Encode parameters if present
        if let parameters = request.parameters {
            try encodeParameters(
                parameters,
                into: &urlRequest,
                method: request.method,
                customEncoder: request.parameterEncoder
            )
        }

        return urlRequest
    }

    /// Encodes parameters into URLRequest using custom or automatic encoder.
    ///
    /// Uses modern Alamofire ParameterEncoder API which works with Encodable directly.
    ///
    /// **Automatic encoding (when customEncoder is nil):**
    /// - GET/HEAD/DELETE: URL-encoded as query string (URLEncodedFormParameterEncoder)
    /// - POST/PUT/PATCH/other: JSON-encoded in request body (JSONParameterEncoder)
    ///
    /// **Custom encoding:**
    /// If customEncoder is provided, it takes precedence over automatic selection.
    ///
    /// - Parameters:
    ///   - parameters: Encodable parameters to encode
    ///   - urlRequest: URLRequest to modify (inout)
    ///   - method: HTTP method (determines encoding strategy when customEncoder is nil)
    ///   - customEncoder: Optional custom encoder from NetworkRequest
    /// - Throws: ASCError if encoding fails
    private func encodeParameters<Params: Encodable & Sendable>(
        _ parameters: Params,
        into urlRequest: inout URLRequest,
        method: HTTPMethod,
        customEncoder: ParameterEncoder?
    ) throws {
        // Use custom encoder if provided, otherwise choose based on HTTP method
        let encoder: ParameterEncoder

        if let customEncoder = customEncoder {
            // Custom encoder takes precedence
            encoder = customEncoder
        } else {
            // Automatic selection based on HTTP method
            switch method {
            case .get, .head, .delete:
                // For GET/HEAD/DELETE - query string (URL encoding)
                encoder = URLEncodedFormParameterEncoder.default

            default:
                // For POST/PUT/PATCH - JSON in body
                encoder = JSONParameterEncoder.default
            }
        }

        // Encode Encodable → URLRequest directly (no Dictionary conversion!)
        do {
            urlRequest = try encoder.encode(parameters, into: urlRequest)
        } catch {
            throw ASCError.invalidFormat("Failed to encode parameters: \(error.localizedDescription)")
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
            headers.add(.authenticationRequired)
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
