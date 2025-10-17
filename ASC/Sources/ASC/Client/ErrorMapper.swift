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
        if case .unacceptableStatusCode(let code) = reason {
            // Try to extract error message from response
            let errorMessage = extractErrorMessage(from: data)

            if code == HTTPStatus.unauthorized {
                return ResponseError.clientError(code, errorMessage ?? "Unauthorized")
            }
            if HTTPStatus.isServerError(code) {
                return ResponseError.serverError(code, errorMessage ?? "Server error")
            }
            if HTTPStatus.isClientError(code) {
                return ResponseError.clientError(code, errorMessage)
            }
            return ResponseError.invalidStatusCode(code, data)
        }

        return ResponseError.validationFailed("Response validation failed")
    }

    // MARK: - Error Message Extraction

    /// Extracts error message from response data.
    ///
    /// Attempts to parse common error response formats:
    /// - `{"error": "message"}`
    /// - `{"message": "message"}`
    /// - `{"error_description": "message"}`
    /// - `{"errors": ["message1", "message2"]}`
    ///
    /// - Parameter data: Response data to parse
    /// - Returns: Extracted error message, or nil if parsing fails
    private func extractErrorMessage(from data: Data?) -> String? {
        guard let data = data,
              !data.isEmpty,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        // Try common error message keys in order of priority
        let topLevelKeys = ["message", "error", "error_description"]
        for key in topLevelKeys {
            if let message = json[key] as? String {
                return message
            }
        }

        // Handle nested error object
        if let errorObject = json["error"] as? [String: Any],
           let message = errorObject["message"] as? String {
            return message
        }

        // Handle array of errors
        if let errors = json["errors"] as? [String], let firstError = errors.first {
            return firstError
        }

        // Handle array of error objects
        if let errors = json["errors"] as? [[String: Any]],
           let firstError = errors.first,
           let message = firstError["message"] as? String {
            return message
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
