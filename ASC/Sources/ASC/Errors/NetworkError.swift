// NetworkError.swift
// ASC - Alamofire Swift Client
//
// Network-related error types.

import Foundation

/// Errors that occur during network communication.
///
/// These errors represent issues with network connectivity,
/// timeouts, and other transport-level problems.
public enum NetworkError: ASCError {
    /// No internet connection available.
    case noConnection

    /// Request timed out.
    ///
    /// - Parameter timeout: The timeout interval that was exceeded
    case timeout(TimeInterval)

    /// Host cannot be reached.
    ///
    /// - Parameter host: The host that cannot be reached
    case hostUnreachable(String)

    /// SSL/TLS certificate validation failed.
    ///
    /// - Parameter reason: Description of the validation failure
    case certificateValidationFailed(String)

    /// Request was cancelled.
    case cancelled

    /// Generic network error.
    ///
    /// - Parameter underlying: The underlying URLError or NSError
    case networkFailure(any Error)

    // MARK: - ASCError Conformance

    public var errorDescription: String? {
        switch self {
        case .noConnection:
            return "No internet connection available"

        case .timeout(let interval):
            return "Request timed out after \(interval) seconds"

        case .hostUnreachable(let host):
            return "Cannot reach host: \(host)"

        case .certificateValidationFailed(let reason):
            return "Certificate validation failed: \(reason)"

        case .cancelled:
            return "Request was cancelled"

        case .networkFailure(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .noConnection:
            return "Please check your internet connection and try again"

        case .timeout:
            return "Please try again or check your internet connection"

        case .hostUnreachable:
            return "Please check the server address and try again"

        case .certificateValidationFailed:
            return "Please verify the server's SSL certificate"

        case .cancelled:
            return nil

        case .networkFailure:
            return "Please try again later"
        }
    }

    public var underlyingError: (any Error)? {
        switch self {
        case .networkFailure(let error):
            return error

        default:
            return nil
        }
    }
}
