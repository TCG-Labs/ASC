// ResponseError.swift
// ASC - Alamofire Swift Client

// Response parsing and validation errors.

import Foundation

/// Errors that occur during response processing.
///
/// These errors represent issues with HTTP responses,
/// including status codes, data parsing, and validation.
public enum ResponseError: ASCError {
    /// Invalid HTTP status code received.
    ///
    /// - Parameters:
    ///   - statusCode: The HTTP status code that was received
    ///   - data: Response data, if available
    case invalidStatusCode(HTTPStatusCode, Data?)

    /// Failed to parse response data.
    ///
    /// - Parameters:
    ///   - error: The decoding error that occurred
    ///   - data: The raw response data
    case decodingFailed(any Error, Data)

    /// Response data is missing or empty when it was expected.
    case missingData

    /// Response data is in an invalid or unexpected format.
    ///
    /// - Parameter reason: Description of the format issue
    case invalidFormat(String)

    /// Server returned an error message.
    ///
    /// - Parameters:
    ///   - statusCode: The HTTP status code
    ///   - message: Error message from server
    case serverError(HTTPStatusCode, String)

    /// Client error (4xx status code).
    ///
    /// - Parameters:
    ///   - statusCode: The HTTP status code
    ///   - message: Error message, if available
    case clientError(HTTPStatusCode, String?)

    /// Validation failed for the response.
    ///
    /// - Parameter reason: Description of the validation failure
    case validationFailed(String)

    // MARK: - ASCError Conformance

    public var errorDescription: String? {
        switch self {
        case .invalidStatusCode(let code, _):
            return "Invalid HTTP status code: \(code)"

        case .decodingFailed(let error, _):
            return "Failed to decode response: \(error.localizedDescription)"

        case .missingData:
            return "Response data is missing"

        case .invalidFormat(let reason):
            return "Invalid response format: \(reason)"

        case let .serverError(code, message):
            return "Server error (\(code)): \(message)"

        case let .clientError(code, message):
            if let message = message {
                return "Client error (\(code)): \(message)"
            }
            return "Client error (\(code))"

        case .validationFailed(let reason):
            return "Response validation failed: \(reason)"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .invalidStatusCode(let code, _):
            if HTTPStatus.isServerError(code) {
                return "The server encountered an error. Please try again later"
            } else if HTTPStatus.isClientError(code) {
                return "Please check your request and try again"
            }
            return nil

        case .decodingFailed:
            return "The server response format is unexpected. Please contact support"

        case .missingData:
            return "Expected data from server but received none"

        case .invalidFormat:
            return "The server response format is invalid"

        case .serverError:
            return "The server encountered an error. Please try again later"

        case .clientError(let code, _):
            if code == HTTPStatus.badRequest {
                return "Please check your request parameters"
            } else if code == HTTPStatus.notFound {
                return "The requested resource was not found"
            }
            return "Please check your request and try again"

        case .validationFailed:
            return "Please verify the response data"
        }
    }

    public var underlyingError: (any Error)? {
        switch self {
        case .decodingFailed(let error, _):
            return error

        default:
            return nil
        }
    }

    // MARK: - Helpers

    /// The HTTP status code associated with this error, if any.
    public var statusCode: HTTPStatusCode? {
        switch self {
        case .invalidStatusCode(let code, _),
             .serverError(let code, _),
             .clientError(let code, _):
            return code

        default:
            return nil
        }
    }

    /// The response data associated with this error, if any.
    public var responseData: Data? {
        switch self {
        case .invalidStatusCode(_, let data):
            return data

        case .decodingFailed(_, let data):
            return data

        default:
            return nil
        }
    }
}
