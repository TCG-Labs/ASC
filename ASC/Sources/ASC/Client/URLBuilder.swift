// URLBuilder.swift
// ASC - Alamofire Swift Client

// URL construction utilities for network requests.

import Foundation

/// Builds URLs from NetworkRequest configurations.
///
/// Handles base URL combination, path prefix application, and path parameter substitution.
internal struct URLBuilder {
    // MARK: - Public Methods

    /// Builds full URL from a NetworkRequest.
    ///
    /// Combines base URL, path prefix, path, and substitutes path parameters.
    /// - Parameters:
    ///   - request: The network request
    ///   - baseURL: Base URL to use (from client configuration or request)
    /// - Returns: Fully constructed URL
    /// - Throws: URLBuildError if URL is invalid
    internal func buildURL<Request: NetworkRequest>(
        from request: Request,
        baseURL: String
    ) throws -> URL {
        let effectiveBaseURL = request.baseURL ?? baseURL

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

        let fullURL = effectiveBaseURL + fullPath

        guard let url = URL(string: fullURL) else {
            throw URLBuildError.invalidURL(fullURL)
        }

        return url
    }

    // MARK: - Private Methods

    /// Substitutes path parameters in the path template.
    ///
    /// Replaces placeholders like {userId} with actual values.
    /// - Parameters:
    ///   - path: Path template with placeholders
    ///   - parameters: Dictionary of parameter values
    /// - Returns: Path with substituted values
    private func substitutePath(_ path: String, with parameters: [String: String]) -> String {
        var result = path
        for (key, value) in parameters {
            result = result.replacingOccurrences(of: "{\(key)}", with: value)
        }
        return result
    }
}

// MARK: - URLBuildError

/// Errors that can occur during URL building.
internal enum URLBuildError: Error, LocalizedError {
    /// The constructed URL string is invalid.
    case invalidURL(String)

    internal var errorDescription: String? {
        switch self {
        case .invalidURL(let urlString):
            return "Invalid URL: \(urlString)"
        }
    }
}
