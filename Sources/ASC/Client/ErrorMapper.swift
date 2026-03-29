// ErrorMapper.swift
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

        return ASCError.networkFailure(error)
    }

    // MARK: - Private Methods

    /// Maps URLError to ASCError.
    private func mapURLError(_ error: URLError) -> ASCError {
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

    /// Maps validation failure to ASCError.
    private func mapValidationError(
        _ reason: AFError.ResponseValidationFailureReason,
        data: Data?
    ) -> ASCError {
        guard case .unacceptableStatusCode(let code) = reason else {
            return ASCError.validationFailed("Response validation failed")
        }

        let errorMessage = extractErrorMessage(from: data)
        let responseType = HTTPResponseType(statusCode: code, message: errorMessage)

        switch responseType {
        case .success:
            return ASCError.invalidStatusCode(code, data)

        case let .clientError(statusCode, message):
            if statusCode == HTTPStatus.unauthorized {
                return ASCError.clientError(statusCode, message ?? "Unauthorized")
            }
            return ASCError.clientError(statusCode, message)

        case let .serverError(statusCode, message):
            return ASCError.serverError(statusCode, message ?? "Server error")

        case .informational, .redirection, .undefined:
            return ASCError.invalidStatusCode(code, data)
        }
    }

    // MARK: - Error Message Extraction

    /// Extracts error message from response data.
    ///
    /// Delegates to `JSONMessageExtractor` which handles common server error formats.
    ///
    /// - Parameter data: Response data to parse
    /// - Returns: Extracted error message, or nil if parsing fails
    private func extractErrorMessage(from data: Data?) -> String? {
        JSONMessageExtractor.message(from: data)
    }

    /// Maps serialization failure to ASCError.
    private func mapSerializationError(
        _ reason: AFError.ResponseSerializationFailureReason,
        data: Data?
    ) -> ASCError {
        if case .decodingFailed(let error) = reason, let data = data {
            return ASCError.decodingFailed(error, data)
        }

        if case .inputDataNilOrZeroLength = reason {
            return ASCError.missingData
        }

        return ASCError.invalidFormat("Response serialization failed")
    }
}
