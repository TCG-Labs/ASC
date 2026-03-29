// RequestBuilder.swift
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

// Request building utilities for network requests.

import Alamofire
import Foundation

/// Builds URLRequests from Endpoint configurations.
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

    /// Builds a complete URLRequest from an Endpoint.
    ///
    /// - Parameter request: The endpoint to build from
    /// - Returns: Fully configured URLRequest
    /// - Throws: RequestBuildError if URL construction fails
    internal func buildURLRequest<E: Endpoint>(from request: E) throws -> URLRequest {
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
    internal func buildURL<E: Endpoint>(from request: E) throws -> URL {
        guard let effectiveBaseURL = request.baseURL ?? baseURL else {
            throw RequestBuildError.missingBaseURL
        }

        guard var components = URLComponents(string: effectiveBaseURL) else {
            throw RequestBuildError.invalidURL(effectiveBaseURL)
        }

        let fullPath = request.path
        if !fullPath.isEmpty {
            // Split path from inline query string if present (e.g. "/search?q=swift")
            let pathPart: String
            let queryPart: String?
            if let queryStart = fullPath.firstIndex(of: "?") {
                pathPart = String(fullPath[fullPath.startIndex..<queryStart])
                queryPart = String(fullPath[fullPath.index(after: queryStart)...])
            } else {
                pathPart = fullPath
                queryPart = nil
            }

            // Ensure exactly one slash between base path and endpoint path
            let basePath = components.path.hasSuffix("/") ? String(components.path.dropLast()) : components.path
            let endpointPath = pathPart.hasPrefix("/") ? pathPart : "/\(pathPart)"
            components.path = basePath + endpointPath

            if let query = queryPart {
                // Append to existing query if any
                if let existing = components.query, !existing.isEmpty {
                    components.query = existing + "&" + query
                } else {
                    components.query = query
                }
            }
        }

        guard let url = components.url else {
            throw RequestBuildError.invalidURL(effectiveBaseURL + fullPath)
        }

        return url
    }

    /// Builds HTTP headers for a request.
    private func buildHeaders<E: Endpoint>(
        for request: E
    ) -> HTTPHeaders {
        var headers = defaultHeaders.copy()

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
            return "Provide baseURL either in NetworkClient configuration or in the endpoint"
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
