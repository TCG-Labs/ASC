// AuthenticationError.swift
// ASC - Alamofire Swift Client
//
// Authentication and authorization errors.

import Foundation

/// Errors related to authentication and authorization.
///
/// These errors represent issues with user authentication,
/// token management, and access permissions.
public enum AuthenticationError: ASCError {
    /// No authentication credentials are available.
    case notAuthenticated

    /// Authentication token has expired.
    case tokenExpired

    /// Authentication token is invalid or malformed.
    case invalidToken

    /// Token refresh failed.
    ///
    /// - Parameter underlying: The error that caused refresh to fail
    case tokenRefreshFailed(any Error)

    /// User is not authorized to access the resource.
    ///
    /// - Parameter resource: The resource that access was denied to
    case unauthorized(String?)

    /// Access to the resource is forbidden.
    ///
    /// User may be authenticated but lacks permissions.
    /// - Parameter reason: Reason for the forbidden access
    case forbidden(String?)

    /// Authentication credentials are invalid.
    ///
    /// - Parameter reason: Reason for invalid credentials
    case invalidCredentials(String?)

    /// Maximum authentication retry attempts exceeded.
    case maxRetryAttemptsExceeded

    // MARK: - ASCError Conformance

    public var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Not authenticated"

        case .tokenExpired:
            return "Authentication token has expired"

        case .invalidToken:
            return "Authentication token is invalid"

        case .tokenRefreshFailed(let error):
            return "Failed to refresh authentication token: \(error.localizedDescription)"

        case .unauthorized(let resource):
            if let resource = resource {
                return "Unauthorized access to: \(resource)"
            }
            return "Unauthorized access"

        case .forbidden(let reason):
            if let reason = reason {
                return "Access forbidden: \(reason)"
            }
            return "Access forbidden"

        case .invalidCredentials(let reason):
            if let reason = reason {
                return "Invalid credentials: \(reason)"
            }
            return "Invalid credentials"

        case .maxRetryAttemptsExceeded:
            return "Maximum authentication retry attempts exceeded"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .notAuthenticated:
            return "Please log in to continue"

        case .tokenExpired:
            return "Your session has expired. Please log in again"

        case .invalidToken:
            return "Your session is invalid. Please log in again"

        case .tokenRefreshFailed:
            return "Unable to refresh your session. Please log in again"

        case .unauthorized:
            return "You don't have permission to access this resource"

        case .forbidden:
            return "You don't have permission to perform this action"

        case .invalidCredentials:
            return "Please check your credentials and try again"

        case .maxRetryAttemptsExceeded:
            return "Please log in again"
        }
    }

    public var underlyingError: (any Error)? {
        switch self {
        case .tokenRefreshFailed(let error):
            return error
        default:
            return nil
        }
    }
}
