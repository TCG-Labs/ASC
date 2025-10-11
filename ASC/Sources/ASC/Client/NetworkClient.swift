// NetworkClient.swift
// ASC - Alamofire Swift Client
//
// Main network client for executing requests with advanced Alamofire features.

import Foundation
import Alamofire

/// Configuration for NetworkClient.
///
/// Provides fine-grained control over networking behavior using Alamofire's
/// advanced features including interceptors, monitors, handlers, and trust managers.
public struct NetworkClientConfiguration: Sendable {
    /// Default base URL for all requests.
    public let baseURL: String

    /// URLSession configuration.
    public let urlSessionConfiguration: URLSessionConfiguration

    /// Default request timeout in seconds.
    public let defaultTimeout: TimeInterval

    /// Default cache policy.
    public let defaultCachePolicy: URLRequest.CachePolicy

    /// Default headers added to all requests.
    public let defaultHeaders: HTTPHeaders

    /// Request interceptors for adapting and retrying requests.
    public let interceptors: [any RequestInterceptor]

    /// Event monitors for observing request lifecycle.
    public let eventMonitors: [any EventMonitor]

    /// Server trust manager for SSL/TLS validation.
    public let serverTrustManager: ServerTrustManager?

    /// Redirect handler for custom redirect logic.
    public let redirectHandler: (any RedirectHandler)?

    /// Cached response handler for custom caching behavior.
    public let cachedResponseHandler: (any CachedResponseHandler)?

    /// Dispatch queue for root operations.
    public let rootQueue: DispatchQueue

    /// Dispatch queue for request operations.
    public let requestQueue: DispatchQueue

    /// Dispatch queue for serialization operations.
    public let serializationQueue: DispatchQueue

    /// Creates a new network client configuration.
    ///
    /// - Parameters:
    ///   - baseURL: Default base URL for requests
    ///   - urlSessionConfiguration: URLSession configuration (default: .default)
    ///   - defaultTimeout: Default request timeout (default: 60)
    ///   - defaultCachePolicy: Default cache policy (default: .useProtocolCachePolicy)
    ///   - defaultHeaders: Default headers (default: .default)
    ///   - interceptors: Request interceptors (default: [])
    ///   - eventMonitors: Event monitors (default: [])
    ///   - serverTrustManager: Server trust manager (default: nil)
    ///   - redirectHandler: Redirect handler (default: nil)
    ///   - cachedResponseHandler: Cached response handler (default: nil)
    ///   - rootQueue: Root dispatch queue (default: custom queue)
    ///   - requestQueue: Request dispatch queue (default: custom queue)
    ///   - serializationQueue: Serialization dispatch queue (default: custom queue)
    public init(
        baseURL: String,
        urlSessionConfiguration: URLSessionConfiguration = .default,
        defaultTimeout: TimeInterval = 60,
        defaultCachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
        defaultHeaders: HTTPHeaders = .default,
        interceptors: [any RequestInterceptor] = [],
        eventMonitors: [any EventMonitor] = [],
        serverTrustManager: ServerTrustManager? = nil,
        redirectHandler: (any RedirectHandler)? = nil,
        cachedResponseHandler: (any CachedResponseHandler)? = nil,
        rootQueue: DispatchQueue = DispatchQueue(label: "com.asc.networkClient.rootQueue"),
        requestQueue: DispatchQueue = DispatchQueue(
            label: "com.asc.networkClient.requestQueue",
            qos: .userInitiated
        ),
        serializationQueue: DispatchQueue = DispatchQueue(
            label: "com.asc.networkClient.serializationQueue",
            qos: .userInitiated
        )
    ) {
        self.baseURL = baseURL
        self.urlSessionConfiguration = urlSessionConfiguration
        self.defaultTimeout = defaultTimeout
        self.defaultCachePolicy = defaultCachePolicy
        self.defaultHeaders = defaultHeaders
        self.interceptors = interceptors
        self.eventMonitors = eventMonitors
        self.serverTrustManager = serverTrustManager
        self.redirectHandler = redirectHandler
        self.cachedResponseHandler = cachedResponseHandler
        self.rootQueue = rootQueue
        self.requestQueue = requestQueue
        self.serializationQueue = serializationQueue
    }

    /// Creates a default configuration with the specified base URL.
    ///
    /// - Parameter baseURL: Default base URL for requests
    /// - Returns: A default configuration
    public static func `default`(baseURL: String) -> NetworkClientConfiguration {
        NetworkClientConfiguration(baseURL: baseURL)
    }
}

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

    // MARK: - Initialization

    /// Creates a new network client with the specified configuration.
    ///
    /// - Parameter configuration: Client configuration
    public init(configuration: NetworkClientConfiguration) {
        self.configuration = configuration

        // Configure URLSession
        let urlConfig = configuration.urlSessionConfiguration
        urlConfig.timeoutIntervalForRequest = configuration.defaultTimeout
        urlConfig.timeoutIntervalForResource = configuration.defaultTimeout * 2

        // Create Alamofire Session with advanced configuration
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

    /// Convenience initializer with base URL only.
    ///
    /// - Parameter baseURL: Default base URL for requests
    public convenience init(baseURL: String) {
        self.init(configuration: .default(baseURL: baseURL))
    }

    // MARK: - Public Methods

    /// Executes a network request and returns the decoded response.
    ///
    /// - Parameter request: The request to execute
    /// - Returns: Decoded response of type `Request.Response`
    /// - Throws: `NetworkError`, `ResponseError`, or `AuthenticationError`
    public func execute<Request: NetworkRequest>(
        _ request: Request
    ) async throws -> Request.Response {
        // Check if this is a multipart request
        if let files = request.files, !files.isEmpty {
            return try await performMultipartRequest(
                request,
                files: files,
                responseType: Request.Response.self
            )
        }

        let urlRequest = try buildURLRequest(from: request)
        return try await performRequest(urlRequest, responseType: Request.Response.self)
    }

    /// Executes a network request without expecting a response body.
    ///
    /// Useful for requests that return 204 No Content or similar.
    ///
    /// - Parameter request: The request to execute
    /// - Throws: `NetworkError`, `ResponseError`, or `AuthenticationError`
    public func execute<Request: NetworkRequest>(
        _ request: Request
    ) async throws where Request.Response == EmptyResponse {
        // Check if this is a multipart request
        if let files = request.files, !files.isEmpty {
            try await performMultipartEmptyRequest(request, files: files)
            return
        }

        let urlRequest = try buildURLRequest(from: request)
        try await performEmptyRequest(urlRequest)
    }

    // MARK: - Private Methods

    /// Builds a URLRequest from a NetworkRequest.
    private func buildURLRequest<Request: NetworkRequest>(
        from request: Request
    ) throws -> URLRequest {
        let baseURLString = request.baseURL ?? configuration.baseURL

        // Build full path with prefix and parameter substitution
        var fullPath = request.path

        // Apply path prefix if specified
        if let pathPrefix = request.pathPrefix {
            fullPath = pathPrefix + fullPath
        }

        // Substitute path parameters
        if let pathParameters = request.pathParameters {
            fullPath = substitutePath(fullPath, with: pathParameters)
        }

        let fullURL = baseURLString + fullPath

        guard let url = URL(string: fullURL) else {
            throw ResponseError.invalidFormat("Invalid URL: \(fullURL)")
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.timeoutInterval = request.timeout ?? configuration.defaultTimeout
        urlRequest.cachePolicy = request.cachePolicy ?? configuration.defaultCachePolicy

        // Add default headers first
        for header in configuration.defaultHeaders {
            urlRequest.setValue(header.value, forHTTPHeaderField: header.name)
        }

        // Add request-specific headers (overrides defaults)
        if let headers = request.headers {
            for header in headers {
                urlRequest.setValue(header.value, forHTTPHeaderField: header.name)
            }
        }

        // Encode parameters (only if not multipart)
        if request.files == nil, let parameters = request.parameters {
            urlRequest = try request.parameterEncoding.encode(urlRequest, with: parameters)
        }

        return urlRequest
    }

    /// Substitutes path parameters in the path template.
    ///
    /// Replaces placeholders like {userId} with actual values.
    /// - Parameters:
    ///   - path: Path template with placeholders
    ///   - parameters: Dictionary of parameter values
    /// - Returns: Path with substituted values
    internal func substitutePath(_ path: String, with parameters: [String: String]) -> String {
        var result = path
        for (key, value) in parameters {
            result = result.replacingOccurrences(of: "{\(key)}", with: value)
        }
        return result
    }

    /// Performs the actual network request using Alamofire.
    private func performRequest<Response: Decodable & Sendable>(
        _ request: URLRequest,
        responseType: Response.Type
    ) async throws -> Response {
        let dataTask = session.request(request)
            .validate()
            .serializingDecodable(Response.self)

        let response = await dataTask.response

        if let error = response.error {
            throw mapAlamofireError(error, data: response.data)
        }

        guard let value = response.value else {
            throw ResponseError.missingData
        }

        return value
    }

    /// Performs a request without expecting a response body.
    private func performEmptyRequest(_ request: URLRequest) async throws {
        let dataTask = session.request(request)
            .validate()
            .serializingData()

        let response = await dataTask.response

        if let error = response.error {
            throw mapAlamofireError(error, data: response.data)
        }
    }

    /// Performs a multipart file upload request.
    private func performMultipartRequest<Request: NetworkRequest, Response: Decodable & Sendable>(
        _ request: Request,
        files: [String: Data],
        responseType: Response.Type
    ) async throws -> Response {
        let baseURLString = request.baseURL ?? configuration.baseURL

        // Build full path with prefix and parameter substitution
        var fullPath = request.path

        if let pathPrefix = request.pathPrefix {
            fullPath = pathPrefix + fullPath
        }

        if let pathParameters = request.pathParameters {
            fullPath = substitutePath(fullPath, with: pathParameters)
        }

        let fullURL = baseURLString + fullPath

        guard let url = URL(string: fullURL) else {
            throw ResponseError.invalidFormat("Invalid URL: \(fullURL)")
        }

        // Create multipart form data
        let upload = session.upload(
            multipartFormData: { multipartFormData in
                // Add files
                for (name, data) in files {
                    multipartFormData.append(
                        data,
                        withName: name,
                        fileName: "\(name).dat",
                        mimeType: "application/octet-stream"
                    )
                }

                // Add regular parameters as form fields
                if let parameters = request.parameters {
                    for (key, value) in parameters {
                        if let data = "\(value)".data(using: .utf8) {
                            multipartFormData.append(data, withName: key)
                        }
                    }
                }
            },
            to: url,
            method: request.method,
            headers: buildHeaders(for: request)
        )

        let dataTask = upload
            .validate()
            .serializingDecodable(Response.self)

        let response = await dataTask.response

        if let error = response.error {
            throw mapAlamofireError(error, data: response.data)
        }

        guard let value = response.value else {
            throw ResponseError.missingData
        }

        return value
    }

    /// Performs a multipart file upload request without expecting a response body.
    private func performMultipartEmptyRequest<Request: NetworkRequest>(
        _ request: Request,
        files: [String: Data]
    ) async throws {
        let baseURLString = request.baseURL ?? configuration.baseURL

        // Build full path with prefix and parameter substitution
        var fullPath = request.path

        if let pathPrefix = request.pathPrefix {
            fullPath = pathPrefix + fullPath
        }

        if let pathParameters = request.pathParameters {
            fullPath = substitutePath(fullPath, with: pathParameters)
        }

        let fullURL = baseURLString + fullPath

        guard let url = URL(string: fullURL) else {
            throw ResponseError.invalidFormat("Invalid URL: \(fullURL)")
        }

        // Create multipart form data
        let upload = session.upload(
            multipartFormData: { multipartFormData in
                // Add files
                for (name, data) in files {
                    multipartFormData.append(
                        data,
                        withName: name,
                        fileName: "\(name).dat",
                        mimeType: "application/octet-stream"
                    )
                }

                // Add regular parameters as form fields
                if let parameters = request.parameters {
                    for (key, value) in parameters {
                        if let data = "\(value)".data(using: .utf8) {
                            multipartFormData.append(data, withName: key)
                        }
                    }
                }
            },
            to: url,
            method: request.method,
            headers: buildHeaders(for: request)
        )

        let dataTask = upload
            .validate()
            .serializingData()

        let response = await dataTask.response

        if let error = response.error {
            throw mapAlamofireError(error, data: response.data)
        }
    }

    /// Builds HTTP headers for a request.
    private func buildHeaders<Request: NetworkRequest>(for request: Request) -> HTTPHeaders {
        var headers = configuration.defaultHeaders

        // Add request-specific headers (overrides defaults)
        if let requestHeaders = request.headers {
            for header in requestHeaders {
                headers.add(header)
            }
        }

        return headers
    }

    /// Maps Alamofire errors to ASC errors.
    private func mapAlamofireError(_ error: AFError, data: Data?) -> any Error {
        if let underlyingError = error.underlyingError as? URLError {
            return mapURLError(underlyingError)
        }

        if case .responseValidationFailed(let reason) = error {
            return mapValidationError(reason, data: data)
        }

        if case .responseSerializationFailed(let reason) = error {
            return mapSerializationError(reason, data: data)
        }

        return NetworkError.networkFailure(error)
    }

    /// Maps URLError to NetworkError.
    private func mapURLError(_ error: URLError) -> NetworkError {
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost:
            return .noConnection

        case .timedOut:
            return .timeout(configuration.defaultTimeout)

        case .cannotFindHost, .cannotConnectToHost:
            return .hostUnreachable(error.failureURLString ?? "unknown")

        case .serverCertificateUntrusted, .serverCertificateHasUnknownRoot:
            return .certificateValidationFailed(error.localizedDescription)

        case .cancelled:
            return .cancelled

        default:
            return .networkFailure(error)
        }
    }

    /// Maps validation failure to ResponseError.
    private func mapValidationError(
        _ reason: AFError.ResponseValidationFailureReason,
        data: Data?
    ) -> ResponseError {
        if case .unacceptableStatusCode(let code) = reason {
            if code == HTTPStatus.unauthorized {
                return ResponseError.clientError(code, "Unauthorized")
            }
            if HTTPStatus.isServerError(code) {
                return ResponseError.serverError(code, "Server error")
            }
            if HTTPStatus.isClientError(code) {
                return ResponseError.clientError(code, nil)
            }
            return ResponseError.invalidStatusCode(code, data)
        }

        return ResponseError.validationFailed("Response validation failed")
    }

    /// Maps serialization failure to ResponseError.
    private func mapSerializationError(
        _ reason: AFError.ResponseSerializationFailureReason,
        data: Data?
    ) -> ResponseError {
        if case .decodingFailed(let error) = reason, let data = data {
            return ResponseError.decodingFailed(error, data)
        }

        if case .inputDataNilOrZeroLength = reason {
            return ResponseError.missingData
        }

        return ResponseError.invalidFormat("Response serialization failed")
    }
}

// MARK: - EmptyResponse

/// A response type for requests that don't return a body.
///
/// Use this for requests that return 204 No Content or when you
/// don't need to parse the response.
public struct EmptyResponse: Decodable, Sendable {
    public init() {}
}
