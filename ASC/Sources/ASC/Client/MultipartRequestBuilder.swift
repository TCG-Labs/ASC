// MultipartRequestBuilder.swift
// ASC - Alamofire Swift Client

// Multipart form data request builder.

import Alamofire
import Foundation

/// Builds multipart upload requests.
///
/// Handles construction of multipart/form-data requests with files and parameters.
internal struct MultipartRequestBuilder {
    // MARK: - Constants

    /// Default file extension for uploaded files.
    private static let defaultFileExtension = "dat"

    /// Default MIME type for uploaded files.
    private static let defaultMimeType = "application/octet-stream"

    // MARK: - Public Methods

    /// Builds a multipart upload request.
    ///
    /// Creates an Alamofire UploadRequest with multipart form data containing
    /// files and optional parameters.
    /// - Parameters:
    ///   - request: The network request
    ///   - files: Dictionary of files to upload (fieldName -> data)
    ///   - url: Target URL for upload
    ///   - session: Alamofire session to use for upload
    ///   - headers: HTTP headers for the request
    ///   - interceptor: Optional request interceptor for retry logic
    /// - Returns: Configured UploadRequest ready to execute
    internal func buildUpload<Request: NetworkRequest>(
        for request: Request,
        files: [String: Data],
        url: URL,
        session: Session,
        headers: HTTPHeaders,
        interceptor: (any RequestInterceptor)? = nil
    ) -> UploadRequest {
        session.upload(
            multipartFormData: { multipartFormData in
                // Add files
                for (name, data) in files {
                    multipartFormData.append(
                        data,
                        withName: name,
                        fileName: "\(name).\(Self.defaultFileExtension)",
                        mimeType: Self.defaultMimeType
                    )
                }

                // Add regular parameters as form fields
                if let parameters = request.parameters {
                    for (key, value) in parameters {
                        if let data = self.encodeParameter(value) {
                            multipartFormData.append(data, withName: key)
                        }
                    }
                }
            },
            to: url,
            method: request.method,
            headers: headers,
            interceptor: interceptor
        )
    }

    // MARK: - Private Methods

    /// Encodes a parameter value to Data for multipart form data.
    ///
    /// Handles different parameter types appropriately:
    /// - Strings: Direct UTF-8 encoding
    /// - Booleans: "true" or "false"
    /// - Numbers: String representation
    /// - Arrays/Dictionaries: JSON encoding
    /// - nil: Skipped (returns nil)
    ///
    /// - Parameter value: The parameter value to encode
    /// - Returns: Encoded data, or nil if value should be skipped
    private func encodeParameter(_ value: Any) -> Data? {
        switch value {
        case is NSNull:
            return nil

        case let string as String:
            return Data(string.utf8)

        case let bool as Bool:
            return Data(bool.description.utf8)

        case let number as NSNumber:
            return Data(number.stringValue.utf8)

        case let array as [Any]:
            return encodeJSON(array)

        case let dictionary as [String: Any]:
            return encodeJSON(dictionary)

        default:
            return Data("\(value)".utf8)
        }
    }

    /// Encodes a value as JSON data.
    ///
    /// - Parameter value: The value to encode (Array or Dictionary)
    /// - Returns: JSON-encoded data, or nil if encoding fails
    private func encodeJSON(_ value: Any) -> Data? {
        guard JSONSerialization.isValidJSONObject(value) else {
            // Not a valid JSON object, use string representation
            return Data("\(value)".utf8)
        }

        do {
            return try JSONSerialization.data(withJSONObject: value, options: [])
        } catch {
            // JSON encoding failed, use string representation as fallback
            return Data("\(value)".utf8)
        }
    }
}
