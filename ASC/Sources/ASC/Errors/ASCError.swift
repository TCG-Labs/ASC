// ASCError.swift
// ASC - Alamofire Swift Client

// All error types for ASC library.

import Foundation

/// All errors that can occur in ASC.
public enum ASCError: Error, LocalizedError, Sendable {
    // MARK: - Network Errors

    /// No internet connection available.
    case noConnection

    /// Request timed out.
    case timeout(TimeInterval)

    /// Host cannot be reached.
    case hostUnreachable(String)

    /// SSL/TLS certificate validation failed.
    case certificateValidationFailed(String)

    /// Request was cancelled.
    case cancelled

    /// Generic network error.
    case networkFailure(any Error)

    // MARK: - Response Errors

    /// Invalid HTTP status code received.
    case invalidStatusCode(HTTPStatusCode, Data?)

    /// Failed to parse response data.
    case decodingFailed(any Error, Data)

    /// Response data is missing or empty when it was expected.
    case missingData

    /// Response data is in an invalid or unexpected format.
    case invalidFormat(String)

    /// Server returned an error message.
    case serverError(HTTPStatusCode, String)

    /// Client error (4xx status code).
    case clientError(HTTPStatusCode, String?)

    /// Validation failed for the response.
    case validationFailed(String)

    // MARK: - Authentication Errors

    /// No authentication credentials are available.
    case notAuthenticated

    /// Authentication token has expired.
    case tokenExpired

    /// Authentication token is invalid or malformed.
    case invalidToken

    /// Token refresh failed.
    case tokenRefreshFailed(any Error)

    /// User is not authorized to access the resource.
    case unauthorized(String?)

    /// Access to the resource is forbidden.
    case forbidden(String?)

    /// Authentication credentials are invalid.
    case invalidCredentials(String?)

    // MARK: - LocalizedError Conformance

    public var errorDescription: String? {
        switch self {
        case .noConnection:
            return "No internet connection"

        case let .timeout(interval):
            return "Request timed out after \(interval)s"

        case let .hostUnreachable(host):
            return "Cannot reach host: \(host)"

        case let .certificateValidationFailed(reason):
            return "Certificate validation failed: \(reason)"

        case .cancelled:
            return "Request cancelled"

        case let .networkFailure(error):
            return "Network error: \(error.localizedDescription)"

        case let .invalidStatusCode(code, _):
            return "Invalid HTTP status code: \(code)"

        case let .decodingFailed(error, _):
            return "Failed to decode response: \(error.localizedDescription)"

        case .missingData:
            return "Response data is missing"

        case let .invalidFormat(reason):
            return "Invalid response format: \(reason)"

        case let .serverError(code, message):
            return "Server error (\(code)): \(message)"

        case let .clientError(code, message):
            if let message = message {
                return "Client error (\(code)): \(message)"
            }
            return "Client error (\(code))"

        case let .validationFailed(reason):
            return "Response validation failed: \(reason)"

        case .notAuthenticated:
            return "Not authenticated"

        case .tokenExpired:
            return "Authentication token expired"

        case .invalidToken:
            return "Authentication token is invalid"

        case let .tokenRefreshFailed(error):
            return "Failed to refresh token: \(error.localizedDescription)"

        case let .unauthorized(resource):
            if let resource = resource {
                return "Unauthorized access to: \(resource)"
            }
            return "Unauthorized access"

        case let .forbidden(reason):
            if let reason = reason {
                return "Access forbidden: \(reason)"
            }
            return "Access forbidden"

        case let .invalidCredentials(reason):
            if let reason = reason {
                return "Invalid credentials: \(reason)"
            }
            return "Invalid credentials"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .noConnection:
            return "Check your internet connection"

        case .timeout:
            return "Try again or check your connection"

        case .hostUnreachable:
            return "Check the server address"

        case .certificateValidationFailed:
            return "Verify the server's SSL certificate"

        case .cancelled:
            return nil

        case .networkFailure:
            return "Try again later"

        case let .invalidStatusCode(code, _):
            if HTTPStatus.isServerError(code) {
                return "Server error, try again later"
            } else if HTTPStatus.isClientError(code) {
                return "Check your request"
            }
            return nil

        case .decodingFailed:
            return "Unexpected server response format"

        case .missingData:
            return "Expected data from server"

        case .invalidFormat:
            return "Invalid server response format"

        case .serverError:
            return "Server error, try again later"

        case let .clientError(code, _):
            if code == HTTPStatus.badRequest {
                return "Check your request parameters"
            } else if code == HTTPStatus.notFound {
                return "Resource not found"
            }
            return "Check your request"

        case .validationFailed:
            return "Verify the response data"

        case .notAuthenticated:
            return "Please log in"

        case .tokenExpired:
            return "Session expired, log in again"

        case .invalidToken:
            return "Session invalid, log in again"

        case .tokenRefreshFailed:
            return "Unable to refresh session, log in again"

        case .unauthorized:
            return "You don't have permission"

        case .forbidden:
            return "Action not allowed"

        case .invalidCredentials:
            return "Check your credentials"
        }
    }

    public var failureReason: String? { errorDescription }

    // MARK: - Helpers

    /// The underlying error that caused this error, if any.
    public var underlyingError: (any Error)? {
        switch self {
        case let .networkFailure(error),
             let .decodingFailed(error, _),
             let .tokenRefreshFailed(error):
            return error

        default:
            return nil
        }
    }

    /// The HTTP status code associated with this error, if any.
    public var statusCode: HTTPStatusCode? {
        switch self {
        case let .invalidStatusCode(code, _),
             let .serverError(code, _),
             let .clientError(code, _):
            return code

        default:
            return nil
        }
    }

    /// The response data associated with this error, if any.
    public var responseData: Data? {
        switch self {
        case let .invalidStatusCode(_, data):
            return data

        case let .decodingFailed(_, data):
            return data

        default:
            return nil
        }
    }
}
