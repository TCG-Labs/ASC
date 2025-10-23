// ErrorMapper.swift
// ASC - Alamofire Swift Client

// Maps Alamofire errors to ASC error types.

import Alamofire
import Foundation

/// Maps Alamofire errors to ASC-specific error types.
///
/// Provides centralized error transformation logic for better error handling
/// and user-friendly error messages.
internal struct ErrorMapper {
    // MARK: - Properties

    /// Default timeout value for error messages.
    private let defaultTimeout: TimeInterval

    // MARK: - Initialization

    /// Creates a new error mapper.
    ///
    /// - Parameter defaultTimeout: Default timeout to use in error messages
    internal init(defaultTimeout: TimeInterval) {
        self.defaultTimeout = defaultTimeout
    }

    // MARK: - Public Methods

    /// Maps Alamofire errors to ASC errors.
    ///
    /// - Parameters:
    ///   - error: Alamofire error to map
    ///   - data: Optional response data for context
    /// - Returns: Mapped ASC error
    internal func mapError(_ error: AFError, data: Data?) -> any Error {
        if case .explicitlyCancelled = error {
            return CancellationError()
        }

        if let underlyingError = error.underlyingError as? URLError {
            return mapURLError(underlyingError)
        }

        if case .responseValidationFailed(let reason) = error {
            return mapValidationError(reason, data: data)
        }

        if case .responseSerializationFailed(let reason) = error {
            return mapSerializationError(reason, data: data)
        }

        return NetworkError.networkFailure(error)
    }

    // MARK: - Private Methods

    /// Maps URLError to NetworkError.
    private func mapURLError(_ error: URLError) -> NetworkError {
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost:
            return .noConnection

        case .timedOut:
            return .timeout(defaultTimeout)

        case .cannotFindHost, .cannotConnectToHost:
            return .hostUnreachable(error.failureURLString ?? "unknown")

        case .serverCertificateUntrusted, .serverCertificateHasUnknownRoot:
            return .certificateValidationFailed(error.localizedDescription)

        case .cancelled:
            return .cancelled

        default:
            return .networkFailure(error)
        }
    }

    /// Maps validation failure to ResponseError.
    private func mapValidationError(
        _ reason: AFError.ResponseValidationFailureReason,
        data: Data?
    ) -> ResponseError {
        guard case .unacceptableStatusCode(let code) = reason else {
            return ResponseError.validationFailed("Response validation failed")
        }

        let errorMessage = extractErrorMessage(from: data)
        let responseType = HTTPResponseType(statusCode: code, message: errorMessage)

        switch responseType {
        case .success:
            return ResponseError.invalidStatusCode(code, data)

        case let .clientError(statusCode, message):
            if statusCode == HTTPStatus.unauthorized {
                return ResponseError.clientError(statusCode, message ?? "Unauthorized")
            }
            return ResponseError.clientError(statusCode, message)

        case let .serverError(statusCode, message):
            return ResponseError.serverError(statusCode, message ?? "Server error")

        case .informational, .redirection, .undefined:
            return ResponseError.invalidStatusCode(code, data)
        }
    }

    // MARK: - Error Message Extraction

    /// Extracts error message from response data.
    ///
    /// Attempts to parse common error response formats using recursive search:
    /// - `{"error": "message"}`, `{"message": "message"}`
    /// - `{"error_description": "message"}`, `{"errorMessage": "message"}`
    /// - `{"detail": "message"}` (Django REST Framework)
    /// - `{"error": {"message": "message"}}` (nested error objects)
    /// - `{"data": {"message": "message"}}`, `{"status": {"message": "message"}}`
    /// - `{"errors": ["message1", "message2"]}` (array of strings)
    /// - `{"errors": [{"message": "message"}]}` (array of objects)
    /// - Arbitrary nesting levels supported
    ///
    /// - Parameter data: Response data to parse
    /// - Returns: Extracted error message, or nil if parsing fails
    private func extractErrorMessage(from data: Data?) -> String? {
        guard let data = data,
              !data.isEmpty,
              let json = try? JSONSerialization.jsonObject(with: data) else {
            return nil
        }

        return findMessage(in: json)
    }

    /// Recursively finds a message string in any JSON structure.
    ///
    /// Searches through dictionaries, arrays, and nested structures to find
    /// error messages using common key names.
    ///
    /// - Parameter value: JSON value to search (can be String, Dictionary, Array, etc.)
    /// - Returns: Found message string, or nil if not found
    private func findMessage(in value: Any) -> String? {
        // Direct string value
        if let string = value as? String {
            return string
        }

        // Dictionary: check common message keys first, then recurse
        if let dict = value as? [String: Any] {
            let messageKeys = [
                "message",
                "error",
                "error_description",
                "errorMessage",
                "detail",
                "error_message",
            ]

            // Check common message keys first
            for key in messageKeys {
                if let message = dict[key] as? String {
                    return message
                }
            }

            // Recursively search nested values
            for (_, nestedValue) in dict {
                if let message = findMessage(in: nestedValue) {
                    return message
                }
            }
        }

        // Array: check first element
        if let array = value as? [Any], let first = array.first {
            return findMessage(in: first)
        }

        return nil
    }

    /// Maps serialization failure to ResponseError.
    private func mapSerializationError(
        _ reason: AFError.ResponseSerializationFailureReason,
        data: Data?
    ) -> ResponseError {
        if case .decodingFailed(let error) = reason, let data = data {
            return ResponseError.decodingFailed(error, data)
        }

        if case .inputDataNilOrZeroLength = reason {
            return ResponseError.missingData
        }

        return ResponseError.invalidFormat("Response serialization failed")
    }
}
