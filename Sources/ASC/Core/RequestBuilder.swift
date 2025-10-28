// RequestBuilder.swift
// ASC - Alamofire Swift Client

// Request building utilities for network requests.

import Alamofire
import Foundation

/// Builds URLRequests from NetworkRequest configurations.
///
/// Encapsulates all logic for constructing URLRequests including:
/// - URL construction
/// - HTTP method configuration
/// - Timeout and cache policy
/// - Header building
/// - Parameter encoding
internal final class RequestBuilder: Sendable {
    // MARK: - Properties

    private let baseURL: String?
    private let defaultHeaders: HTTPHeaders
    private let defaultTimeout: TimeInterval
    private let defaultCachePolicy: URLRequest.CachePolicy
    private let defaultDecoder: JSONDecoder

    // MARK: - Initialization

    /// Creates a new request builder with configuration.
    ///
    /// - Parameters:
    ///   - baseURL: Default base URL for requests
    ///   - defaultHeaders: Headers to add to all requests
    ///   - defaultTimeout: Default timeout interval
    ///   - defaultCachePolicy: Default cache policy
    ///   - defaultDecoder: JSON decoder for decoding
    internal init(
        baseURL: String?,
        defaultHeaders: HTTPHeaders,
        defaultTimeout: TimeInterval,
        defaultCachePolicy: URLRequest.CachePolicy,
        defaultDecoder: JSONDecoder
    ) {
        self.baseURL = baseURL
        self.defaultHeaders = defaultHeaders
        self.defaultTimeout = defaultTimeout
        self.defaultCachePolicy = defaultCachePolicy
        self.defaultDecoder = defaultDecoder
    }

    // MARK: - Public Methods

    /// Builds a complete URLRequest from a NetworkRequest.
    ///
    /// - Parameter request: The network request to build from
    /// - Returns: Fully configured URLRequest
    /// - Throws: RequestBuildError if URL construction fails
    internal func buildURLRequest<Request: NetworkRequest>(
        from request: Request
    ) throws -> URLRequest {
        // Step 1: Build the URL
        let url = try buildURL(from: request)

        // Step 2: Create base URLRequest
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.timeoutInterval = request.timeout ?? defaultTimeout
        urlRequest.cachePolicy = request.cachePolicy ?? defaultCachePolicy

        // Step 3: Add headers
        let headers = buildHeaders(for: request)
        for header in headers {
            urlRequest.setValue(header.value, forHTTPHeaderField: header.name)
        }

        // Step 4: Encode parameters if present
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

    // MARK: - Private Methods

    /// Builds the URL for a request.
    private func buildURL<Request: NetworkRequest>(
        from request: Request
    ) throws -> URL {
        guard let effectiveBaseURL = request.baseURL ?? baseURL else {
            throw RequestBuildError.missingBaseURL
        }

        let fullURL = effectiveBaseURL + request.path

        guard let url = URL(string: fullURL) else {
            throw RequestBuildError.invalidURL(fullURL)
        }

        return url
    }

    /// Builds HTTP headers for a request.
    private func buildHeaders<Request: NetworkRequest>(
        for request: Request
    ) -> HTTPHeaders {
        var headers = defaultHeaders.copy()

        if request.enableAuthorization {
            headers.add(.authenticationRequired)
        }

        if let requestHeaders = request.headers {
            for header in requestHeaders {
                headers.add(header)
            }
        }

        return headers
    }

    /// Encodes parameters into URLRequest.
    ///
    /// Automatically chooses encoding based on HTTP method:
    /// - GET/HEAD/DELETE: URL-encoded as query string
    /// - POST/PUT/PATCH: JSON-encoded in body
    private func encodeParameters<Params: Encodable & Sendable>(
        _ parameters: Params,
        into urlRequest: inout URLRequest,
        method: HTTPMethod,
        customEncoder: ParameterEncoder?
    ) throws {
        let encoder: ParameterEncoder

        if let customEncoder = customEncoder {
            encoder = customEncoder
        } else {
            switch method {
            case .get, .head, .delete:
                encoder = URLEncodedFormParameterEncoder.default

            default:
                encoder = JSONParameterEncoder.default
            }
        }

        do {
            urlRequest = try encoder.encode(parameters, into: urlRequest)
        } catch {
            throw ASCError.invalidFormat("Failed to encode parameters: \(error.localizedDescription)")
        }
    }
}

// MARK: - RequestBuildError

/// Errors that can occur during request building.
internal enum RequestBuildError: Error, LocalizedError {
    /// The constructed URL string is invalid.
    case invalidURL(String)

    /// Base URL is missing from both client configuration and request.
    case missingBaseURL

    internal var errorDescription: String? {
        switch self {
        case let .invalidURL(urlString):
            return "Invalid URL: \(urlString)"

        case .missingBaseURL:
            return "Base URL is required but not provided"
        }
    }

    internal var recoverySuggestion: String? {
        switch self {
        case .invalidURL:
            return "Check the base URL and path configuration"

        case .missingBaseURL:
            return "Provide baseURL either in NetworkClient configuration or in the request"
        }
    }
}

// MARK: - HTTPHeaders Extension

private extension HTTPHeaders {
    func copy() -> HTTPHeaders {
        var copiedHeaders = HTTPHeaders()
        for header in self {
            copiedHeaders[header.name] = header.value
        }
        return copiedHeaders
    }
}
