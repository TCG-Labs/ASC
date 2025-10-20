// RequestTypes.swift
// ASC - Alamofire Swift Client

// Common types used in network requests.

import Foundation

/// HTTP status code type alias for better readability.
public typealias HTTPStatusCode = Int

/// Common HTTP status code ranges and values.
///
/// Provides convenient access to standard HTTP status codes.
public enum HTTPStatus {
    // MARK: - Success (2xx)

    /// 200 OK - Request succeeded
    public static let ok = 200

    /// 201 Created - Resource created successfully
    public static let created = 201

    /// 204 No Content - Success with no response body
    public static let noContent = 204

    // MARK: - Redirection (3xx)

    /// 304 Not Modified - Cached version is still valid
    public static let notModified = 304

    // MARK: - Client Errors (4xx)

    /// 400 Bad Request - Invalid request syntax
    public static let badRequest = 400

    /// 401 Unauthorized - Authentication required
    public static let unauthorized = 401

    /// 403 Forbidden - Access denied
    public static let forbidden = 403

    /// 404 Not Found - Resource not found
    public static let notFound = 404

    /// 429 Too Many Requests - Rate limit exceeded
    public static let tooManyRequests = 429

    // MARK: - Server Errors (5xx)

    /// 500 Internal Server Error - Server error
    public static let internalServerError = 500

    /// 502 Bad Gateway - Invalid response from upstream
    public static let badGateway = 502

    /// 503 Service Unavailable - Server temporarily unavailable
    public static let serviceUnavailable = 503

    // MARK: - Helpers

    /// Check if status code is in success range (200-299)
    /// - Parameter code: HTTP status code to check
    /// - Returns: true if status code indicates success
    public static func isSuccess(_ code: HTTPStatusCode) -> Bool {
        (200...299).contains(code)
    }

    /// Check if status code is in client error range (400-499)
    /// - Parameter code: HTTP status code to check
    /// - Returns: true if status code indicates client error
    public static func isClientError(_ code: HTTPStatusCode) -> Bool {
        (400...499).contains(code)
    }

    /// Check if status code is in server error range (500-599)
    /// - Parameter code: HTTP status code to check
    /// - Returns: true if status code indicates server error
    public static func isServerError(_ code: HTTPStatusCode) -> Bool {
        (500...599).contains(code)
    }
}

// MARK: - StatusCodeCategory

/// Categorizes HTTP status codes for consistent error handling.
///
/// Provides structured categories with appropriate recovery suggestions.
public enum StatusCodeCategory: Sendable {
    case success
    case clientError(HTTPStatusCode, String?)
    case serverError(HTTPStatusCode, String?)
    case other(HTTPStatusCode)

    /// Creates a category from a status code and optional error message.
    ///
    /// - Parameters:
    ///   - code: HTTP status code
    ///   - message: Optional error message from response
    /// - Returns: Appropriate status code category
    public init(_ code: HTTPStatusCode, message: String? = nil) {
        switch code {
        case 200...299:
            self = .success

        case 400...499:
            self = .clientError(code, message)

        case 500...599:
            self = .serverError(code, message)

        default:
            self = .other(code)
        }
    }

    /// Suggested recovery action based on the category.
    public var recoverySuggestion: String? {
        switch self {
        case .success:
            return nil

        case .clientError(let code, _):
            switch code {
            case 400:
                return "Please check your request parameters"

            case 404:
                return "The requested resource was not found"

            default:
                return "Please check your request and try again"
            }

        case .serverError:
            return "The server encountered an error. Please try again later"

        case .other:
            return nil
        }
    }
}
