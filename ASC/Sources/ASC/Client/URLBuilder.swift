// URLBuilder.swift
// ASC - Alamofire Swift Client

// URL construction utilities for network requests.

import Foundation

/// Builds URLs from NetworkRequest configurations.
///
/// Simple URL builder that combines base URL with path.
internal struct URLBuilder {
    // MARK: - Public Methods

    /// Builds full URL from a NetworkRequest.
    ///
    /// Combines base URL with path.
    /// - Parameters:
    ///   - request: The network request
    ///   - baseURL: Base URL from client configuration (optional)
    /// - Returns: Fully constructed URL
    /// - Throws: URLBuildError if URL is invalid or baseURL is missing
    internal func buildURL<Request: NetworkRequest>(
        from request: Request,
        baseURL: String?
    ) throws -> URL {
        guard let effectiveBaseURL = request.baseURL ?? baseURL else {
            throw URLBuildError.missingBaseURL
        }

        let fullURL = effectiveBaseURL + request.path

        guard let url = URL(string: fullURL) else {
            throw URLBuildError.invalidURL(fullURL)
        }

        return url
    }
}

// MARK: - URLBuildError

/// Errors that can occur during URL building.
internal enum URLBuildError: Error, LocalizedError {
    /// The constructed URL string is invalid.
    case invalidURL(String)

    /// Base URL is missing from both client configuration and request.
    case missingBaseURL

    internal var errorDescription: String? {
        switch self {
        case .invalidURL(let urlString):
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
