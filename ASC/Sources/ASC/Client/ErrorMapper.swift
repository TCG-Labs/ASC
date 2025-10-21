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
        let category = StatusCodeCategory(code, message: errorMessage)

        switch category {
        case .success:
            return ResponseError.invalidStatusCode(code, data)

        case let .clientError(statusCode, message):
            if statusCode == HTTPStatus.unauthorized {
                return ResponseError.clientError(statusCode, message ?? "Unauthorized")
            }
            return ResponseError.clientError(statusCode, message)

        case let .serverError(statusCode, message):
            return ResponseError.serverError(statusCode, message ?? "Server error")

        case .other:
            return ResponseError.invalidStatusCode(code, data)
        }
    }

    // MARK: - Error Message Extraction

    /// Extracts error message from response data.
    ///
    /// Attempts to parse common error response formats:
    /// - `{"error": "message"}`, `{"message": "message"}`
    /// - `{"error_description": "message"}`, `{"errorMessage": "message"}`
    /// - `{"detail": "message"}` (Django REST Framework)
    /// - `{"error": {"message": "message"}}` (nested error objects)
    /// - `{"data": {"message": "message"}}`, `{"status": {"message": "message"}}`
    /// - `{"errors": ["message1", "message2"]}` (array of strings)
    /// - `{"errors": [{"message": "message"}]}` (array of objects)
    ///
    /// - Parameter data: Response data to parse
    /// - Returns: Extracted error message, or nil if parsing fails
    private func extractErrorMessage(from data: Data?) -> String? {
        guard let data = data,
              !data.isEmpty,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        // Check top-level string keys
        let topLevelKeys = ["message", "error", "error_description", "errorMessage", "detail", "error_message"]
        for key in topLevelKeys {
            if let message = json[key] as? String {
                return message
            }
        }

        // Check nested error/data/status objects
        let nestedKeys = ["error", "data", "status"]
        for key in nestedKeys {
            if let errorObject = json[key] as? [String: Any],
               let message = findMessageInObject(errorObject) {
                return message
            }
        }

        // Check errors array (strings)
        if let errors = json["errors"] as? [String], let firstError = errors.first {
            return firstError
        }

        // Check errors array (objects)
        if let errors = json["errors"] as? [[String: Any]],
           let firstError = errors.first,
           let message = findMessageInObject(firstError) {
            return message
        }

        return nil
    }

    /// Finds a message string in an object by checking common key names.
    ///
    /// - Parameter object: Dictionary to search for message
    /// - Returns: Found message string, or nil if not found
    private func findMessageInObject(_ object: [String: Any]) -> String? {
        let messageKeys = ["message", "error_message", "errorMessage", "detail"]
        for key in messageKeys {
            if let message = object[key] as? String {
                return message
            }
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
