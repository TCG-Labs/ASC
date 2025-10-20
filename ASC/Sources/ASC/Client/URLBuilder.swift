// URLBuilder.swift
// ASC - Alamofire Swift Client

// URL construction utilities for network requests.

import Foundation

/// Builds URLs from NetworkRequest configurations.
///
/// Handles base URL combination, path prefix application, and path parameter substitution.
internal struct URLBuilder {
    // MARK: - Constants

    /// Cached regex pattern for extracting path parameter placeholders.
    ///
    /// Matches placeholders in the format {parameterName}.
    /// Compiled once and reused for performance.
    private static let placeholderRegex: NSRegularExpression = {
        // swiftlint:disable:next force_try
        try! NSRegularExpression(pattern: #"\{([^}]+)\}"#, options: [])
    }()

    // MARK: - Public Methods

    /// Builds full URL from a NetworkRequest.
    ///
    /// Combines base URL, path prefix, path, and substitutes path parameters.
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

        var fullPath = request.path

        if let pathPrefix = request.pathPrefix {
            fullPath = pathPrefix + fullPath
        }

        if let pathParameters = request.pathParameters {
            fullPath = try substitutePath(fullPath, with: pathParameters)
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
    /// Validates that all required placeholders are provided.
    /// - Parameters:
    ///   - path: Path template with placeholders
    ///   - parameters: Dictionary of parameter values
    /// - Returns: Path with substituted values
    /// - Throws: URLBuildError.missingPathParameters if required parameters are missing
    private func substitutePath(_ path: String, with parameters: [String: String]) throws -> String {
        let requiredKeys = extractPlaceholders(from: path)
        let providedKeys = Set(parameters.keys)
        let missingKeys = requiredKeys.subtracting(providedKeys)

        if !missingKeys.isEmpty {
            throw URLBuildError.missingPathParameters(Array(missingKeys).sorted())
        }

        var result = path
        for (key, value) in parameters {
            result = result.replacingOccurrences(of: "{\(key)}", with: value)
        }

        return result
    }

    /// Extracts placeholder names from a path template.
    ///
    /// Finds all placeholders in the format {parameterName}.
    /// Uses cached regex pattern for optimal performance.
    /// - Parameter path: Path template
    /// - Returns: Set of placeholder names found in the path
    private func extractPlaceholders(from path: String) -> Set<String> {
        var placeholders = Set<String>()

        let nsPath = path as NSString
        let matches = Self.placeholderRegex.matches(
            in: path,
            options: [],
            range: NSRange(location: 0, length: nsPath.length)
        )

        for match in matches where match.numberOfRanges > 1 {
            let range = match.range(at: 1)
            if range.location != NSNotFound {
                let placeholder = nsPath.substring(with: range)
                placeholders.insert(placeholder)
            }
        }

        return placeholders
    }
}

// MARK: - URLBuildError

/// Errors that can occur during URL building.
internal enum URLBuildError: Error, LocalizedError {
    /// The constructed URL string is invalid.
    case invalidURL(String)

    /// Required path parameters are missing.
    ///
    /// - Parameter missingKeys: Array of missing parameter names
    case missingPathParameters([String])

    /// Base URL is missing from both client configuration and request.
    case missingBaseURL

    internal var errorDescription: String? {
        switch self {
        case .invalidURL(let urlString):
            return "Invalid URL: \(urlString)"

        case .missingPathParameters(let keys):
            let keysList = keys.joined(separator: ", ")
            return "Missing required path parameters: \(keysList)"

        case .missingBaseURL:
            return "Base URL is required but not provided"
        }
    }

    internal var recoverySuggestion: String? {
        switch self {
        case .invalidURL:
            return "Check the base URL and path configuration"

        case .missingPathParameters(let keys):
            let keysList = keys.joined(separator: ", ")
            return "Provide values for these path parameters: \(keysList)"

        case .missingBaseURL:
            return "Provide baseURL either in NetworkClient configuration or in the request"
        }
    }
}
