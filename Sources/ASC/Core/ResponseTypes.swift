// RequestTypes.swift
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

// MARK: - HTTPResponseType

/// HTTP response type based on status code ranges.
///
/// Unified type that categorizes HTTP responses and provides error handling capabilities.
/// Combines status code categorization with error messages and recovery suggestions.
///
/// Example:
/// ```swift
/// let response: HTTPURLResponse = ...
/// let responseType = HTTPResponseType(statusCode: response.statusCode)
///
/// switch responseType {
/// case .informational:
///     debugPrint("Informational response")
/// case .success:
///     debugPrint("Success!")
/// case .redirection:
///     debugPrint("Redirect")
/// case .clientError(let code, let message):
///     debugPrint("Client error \(code): \(message ?? "Unknown")")
/// case .serverError(let code, let message):
///     debugPrint("Server error \(code): \(message ?? "Unknown")")
/// case .undefined:
///     debugPrint("Unknown status code")
/// }
///
/// // Or use convenience properties
/// if responseType.isSuccess {
///     debugPrint("Request succeeded")
/// } else if let suggestion = responseType.recoverySuggestion {
///     debugPrint("Suggestion: \(suggestion)")
/// }
/// ```
public enum HTTPResponseType: Sendable {
    /// Informational responses (1xx)
    ///
    /// Indicates that the request was received and the process is continuing.
    /// Examples: 100 Continue, 101 Switching Protocols, 102 Processing
    case informational(HTTPStatusCode)

    /// Successful responses (2xx)
    ///
    /// Indicates that the request was successfully received, understood, and accepted.
    /// Examples: 200 OK, 201 Created, 204 No Content
    case success(HTTPStatusCode)

    /// Redirection messages (3xx)
    ///
    /// Indicates that further action needs to be taken to complete the request.
    /// Examples: 301 Moved Permanently, 302 Found, 304 Not Modified
    case redirection(HTTPStatusCode)

    /// Client error responses (4xx)
    ///
    /// Indicates that the request contains bad syntax or cannot be fulfilled.
    /// Examples: 400 Bad Request, 401 Unauthorized, 404 Not Found
    ///
    /// - Parameters:
    ///   - statusCode: The HTTP status code
    ///   - message: Optional error message from the server
    case clientError(HTTPStatusCode, message: String?)

    /// Server error responses (5xx)
    ///
    /// Indicates that the server failed to fulfill a valid request.
    /// Examples: 500 Internal Server Error, 502 Bad Gateway, 503 Service Unavailable
    ///
    /// - Parameters:
    ///   - statusCode: The HTTP status code
    ///   - message: Optional error message from the server
    case serverError(HTTPStatusCode, message: String?)

    /// Undefined or custom status codes
    ///
    /// Status codes outside of standard ranges (< 100 or >= 600)
    case undefined(HTTPStatusCode)

    /// Creates a response type from an HTTP status code.
    ///
    /// - Parameters:
    ///   - statusCode: HTTP status code to categorize
    ///   - message: Optional error message for error responses
    /// - Returns: Appropriate response type category
    public init(statusCode: HTTPStatusCode, message: String? = nil) {
        switch statusCode {
        case 100..<200:
            self = .informational(statusCode)

        case 200..<300:
            self = .success(statusCode)

        case 300..<400:
            self = .redirection(statusCode)

        case 400..<500:
            self = .clientError(statusCode, message: message)

        case 500..<600:
            self = .serverError(statusCode, message: message)

        default:
            self = .undefined(statusCode)
        }
    }

    // MARK: - Computed Properties

    /// The HTTP status code associated with this response type.
    public var statusCode: HTTPStatusCode {
        switch self {
        case .informational(let code),
             .success(let code),
             .redirection(let code),
             .clientError(let code, _),
             .serverError(let code, _),
             .undefined(let code):
            return code
        }
    }

    /// Error message associated with error responses.
    ///
    /// Returns the error message for client and server errors, or nil for other response types.
    public var errorMessage: String? {
        switch self {
        case .clientError(_, let message),
             .serverError(_, let message):
            return message

        default:
            return nil
        }
    }

    /// Indicates whether this response type represents a successful response.
    public var isSuccess: Bool {
        if case .success = self {
            return true
        }
        return false
    }

    /// Indicates whether this response type represents an error.
    public var isError: Bool {
        switch self {
        case .clientError, .serverError:
            return true

        default:
            return false
        }
    }

    /// Suggested recovery action based on the response type.
    ///
    /// Provides user-friendly suggestions for error recovery.
    /// Returns nil for successful responses.
    public var recoverySuggestion: String? {
        switch self {
        case .informational, .success, .redirection:
            return nil

        case .clientError(let code, _):
            switch code {
            case 400:
                return "Please check your request parameters"

            case 401:
                return "Authentication required. Please log in again"

            case 403:
                return "You don't have permission to access this resource"

            case 404:
                return "The requested resource was not found"

            case 429:
                return "Too many requests. Please try again later"

            default:
                return "Please check your request and try again"
            }

        case .serverError:
            return "The server encountered an error. Please try again later"

        case .undefined:
            return nil
        }
    }
}

// MARK: - HTTPURLResponse Extension

public extension HTTPURLResponse {
    /// The response type based on the HTTP status code.
    ///
    /// Categorizes the response into standard HTTP categories.
    ///
    /// Example:
    /// ```swift
    /// let response: HTTPURLResponse = ...
    /// if response.responseType.isSuccess {
    ///     debugPrint("Request succeeded")
    /// } else if response.responseType.isError {
    ///     debugPrint("Request failed")
    /// }
    /// ```
    var responseType: HTTPResponseType {
        HTTPResponseType(statusCode: statusCode)
    }
}

// MARK: - Empty Parameters

/// Empty parameters for requests without parameters.
///
/// Use this type for GET, DELETE, or other requests that don't send parameters.
///
/// Example:
/// ```swift
/// struct GetUserRequest: NetworkRequest {
///     typealias Response = User
///     typealias Parameters = EmptyParameters
///
///     let userId: String
///
///     var path: String { "/users/\(userId)" }
///     var method: HTTPMethod { .get }
/// }
/// ```
public struct EmptyParameters: Encodable, Sendable {
    public init() {}
}
