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

    /// Multipart request builder for file uploads.
    private let multipartBuilder: MultipartRequestBuilder

    /// Error mapper for translating Alamofire errors.
    private let errorMapper: ErrorMapper

    // MARK: - Initialization

    /// Creates a new network client with the specified configuration.
    ///
    /// - Parameter configuration: Client configuration
    public init(configuration: NetworkClientConfiguration) {
        self.configuration = configuration

        // Initialize components
        self.urlBuilder = URLBuilder()
        self.multipartBuilder = MultipartRequestBuilder()
        self.errorMapper = ErrorMapper(defaultTimeout: configuration.defaultTimeout)

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
        guard let response = try await executeRequest(request, responseType: Request.Response.self) else {
            throw ResponseError.missingData
        }
        return response
    }

    /// Executes a network request without expecting a response body.
    ///
    /// Useful for requests that return 204 No Content or similar.
    ///
    /// - Parameter request: The request to execute
    /// - Throws: `NetworkError`, `ResponseError`, or `AuthenticationError`
    public func execute<Request: NetworkRequest>(
        _ request: Request
    ) async throws where Request.Response == ASCEmptyResponse {
        _ = try await executeRequest(request, responseType: nil as ASCEmptyResponse.Type?)
    }

    // MARK: - Private Methods

    /// Executes a network request, handling both multipart and standard requests.
    ///
    /// Centralized request execution that routes to appropriate handler based on request type.
    /// - Parameters:
    ///   - request: The network request to execute
    ///   - responseType: Expected response type, or nil for empty response
    /// - Returns: Decoded response, or nil for empty response
    /// - Throws: `NetworkError`, `ResponseError`, or `AuthenticationError`
    private func executeRequest<Request: NetworkRequest, Response: Decodable & Sendable>(
        _ request: Request,
        responseType: Response.Type?
    ) async throws -> Response? {
        // Check if this is a multipart request
        let hasFiles = request.files?.isEmpty == false
        let hasFileUploads = request.fileUploads?.isEmpty == false
        let hasLargeFileUploads = request.largeFileUploads?.isEmpty == false

        if hasFiles || hasFileUploads || hasLargeFileUploads {
            return try await performMultipartRequest(
                request,
                responseType: responseType,
                retryPolicy: request.retryPolicy
            )
        }

        // Standard request
        let urlRequest = try buildURLRequest(from: request)

        if let responseType = responseType {
            return try await performRequest(
                urlRequest,
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
        let url = try urlBuilder.buildURL(from: request, baseURL: configuration.baseURL)

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.timeoutInterval = request.timeout ?? configuration.defaultTimeout
        urlRequest.cachePolicy = request.cachePolicy ?? configuration.defaultCachePolicy

        // Add headers using consolidated method
        let headers = buildHeaders(for: request)
        for header in headers {
            urlRequest.setValue(header.value, forHTTPHeaderField: header.name)
        }

        // Encode parameters (only if not multipart)
        if request.files == nil, let parameters = request.parameters {
            urlRequest = try request.parameterEncoding.encode(urlRequest, with: parameters)
        }

        return urlRequest
    }

    /// Performs the actual network request using Alamofire.
    private func performRequest<Response: Decodable & Sendable>(
        _ urlRequest: URLRequest,
        responseType: Response.Type,
        retryPolicy: Alamofire.RetryPolicy?
    ) async throws -> Response {
        let dataTask = session.request(urlRequest, interceptor: retryPolicy)
            .validate()
            .serializingDecodable(Response.self)

        let response = await dataTask.response

        if let error = response.error {
            throw errorMapper.mapError(error, data: response.data)
        }

        guard let value = response.value else {
            throw ResponseError.missingData
        }

        return value
    }

    /// Performs a request without expecting a response body.
    private func performEmptyRequest(
        _ urlRequest: URLRequest,
        retryPolicy: Alamofire.RetryPolicy?
    ) async throws {
        let dataTask = session.request(urlRequest, interceptor: retryPolicy)
            .validate()
            .serializingData()

        let response = await dataTask.response

        if let error = response.error {
            throw errorMapper.mapError(error, data: response.data)
        }
    }

    /// Performs a multipart file upload request.
    ///
    /// Generic method that handles both regular and empty responses.
    /// When responseType is provided, decodes and returns the response.
    /// When responseType is nil, validates the response without decoding.
    ///
    /// Automatically selects between in-memory and file-based encoding
    /// based on total file size.
    private func performMultipartRequest<Request: NetworkRequest, Response: Decodable & Sendable>(
        _ request: Request,
        responseType: Response.Type?,
        retryPolicy: Alamofire.RetryPolicy?
    ) async throws -> Response? {
        let url = try urlBuilder.buildURL(from: request, baseURL: configuration.baseURL)
        let headers = buildHeaders(for: request)

        let upload = multipartBuilder.buildUpload(
            for: request,
            url: url,
            session: session,
            headers: headers,
            interceptor: retryPolicy
        )

        // Handle response based on expected type
        if let responseType = responseType {
            let response = await upload
                .validate()
                .serializingDecodable(responseType)
                .response

            if let error = response.error {
                throw errorMapper.mapError(error, data: response.data)
            }

            guard let value = response.value else {
                throw ResponseError.missingData
            }

            return value
        } else {
            let response = await upload
                .validate()
                .serializingData()
                .response

            if let error = response.error {
                throw errorMapper.mapError(error, data: response.data)
            }

            return nil
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
