// NetworkClient.swift
// ASC - Alamofire Swift Client
//
// Main network client for executing requests with advanced Alamofire features.

import Foundation
import Alamofire

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
    ) async throws where Request.Response == ASCEmptyResponse {
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
        let url = try urlBuilder.buildURL(from: request, baseURL: configuration.baseURL)

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
            throw errorMapper.mapError(error, data: response.data)
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
            throw errorMapper.mapError(error, data: response.data)
        }
    }

    /// Performs a multipart file upload request.
    private func performMultipartRequest<Request: NetworkRequest, Response: Decodable & Sendable>(
        _ request: Request,
        files: [String: Data],
        responseType: Response.Type
    ) async throws -> Response {
        let url = try urlBuilder.buildURL(from: request, baseURL: configuration.baseURL)
        let headers = buildHeaders(for: request)
        let upload = multipartBuilder.buildUpload(
            for: request,
            files: files,
            url: url,
            session: session,
            headers: headers
        )

        let response = await upload
            .validate()
            .serializingDecodable(Response.self)
            .response

        if let error = response.error {
            throw errorMapper.mapError(error, data: response.data)
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
        let url = try urlBuilder.buildURL(from: request, baseURL: configuration.baseURL)
        let headers = buildHeaders(for: request)
        let upload = multipartBuilder.buildUpload(
            for: request,
            files: files,
            url: url,
            session: session,
            headers: headers
        )

        let response = await upload
            .validate()
            .serializingData()
            .response

        if let error = response.error {
            throw errorMapper.mapError(error, data: response.data)
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
