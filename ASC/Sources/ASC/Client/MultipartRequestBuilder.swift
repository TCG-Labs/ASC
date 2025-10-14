// MultipartRequestBuilder.swift
// ASC - Alamofire Swift Client

// Multipart form data request builder.

import Alamofire
import Foundation

/// Builds multipart upload requests.
///
/// Handles construction of multipart/form-data requests with files and parameters.
/// Supports both in-memory and file-based encoding for optimal memory usage.
internal struct MultipartRequestBuilder {
    // MARK: - Constants

    /// Default file extension for uploaded files.
    private static let defaultFileExtension = "dat"

    /// Default MIME type for uploaded files.
    private static let defaultMimeType = "application/octet-stream"

    /// Threshold for using file-based encoding (10MB).
    /// Files larger than this will use file-based encoding to avoid memory issues.
    private static let fileSizeThreshold: Int = 10_000_000 // 10MB

    // MARK: - Public Methods

    /// Builds a multipart upload request.
    ///
    /// Creates an Alamofire UploadRequest with multipart form data containing
    /// files and optional parameters. Automatically selects between in-memory
    /// and file-based encoding based on total file size.
    ///
    /// - Parameters:
    ///   - request: The network request
    ///   - url: Target URL for upload
    ///   - session: Alamofire session to use for upload
    ///   - headers: HTTP headers for the request
    ///   - interceptor: Optional request interceptor for retry logic
    /// - Returns: Configured UploadRequest ready to execute
    internal func buildUpload<Request: NetworkRequest>(
        for request: Request,
        url: URL,
        session: Session,
        headers: HTTPHeaders,
        interceptor: (any RequestInterceptor)? = nil
    ) -> UploadRequest {
        // Calculate total size to determine encoding method
        let totalSize = calculateTotalSize(for: request)

        // Use file-based encoding for large uploads (> 10MB)
        if totalSize > Self.fileSizeThreshold || request.largeFileUploads != nil {
            return buildFileBasedUpload(
                for: request,
                url: url,
                session: session,
                headers: headers,
                interceptor: interceptor
            )
        }

        // Use in-memory encoding for small uploads
        return buildInMemoryUpload(
            for: request,
            url: url,
            session: session,
            headers: headers,
            interceptor: interceptor
        )
    }

    // MARK: - Private Methods - Encoding Selection

    /// Calculates total size of all files in the request.
    private func calculateTotalSize<Request: NetworkRequest>(for request: Request) -> Int {
        // Optimization: Large file uploads always trigger file-based encoding
        // Return early to avoid unnecessary size calculations
        if request.largeFileUploads != nil {
            return Int.max
        }

        var totalSize = 0

        // Add size from simple files
        if let files = request.files {
            totalSize += files.values.reduce(0) { $0 + $1.count }
        }

        // Add size from file uploads with metadata
        if let fileUploads = request.fileUploads {
            totalSize += fileUploads.values.reduce(0) { $0 + $1.data.count }
        }

        return totalSize
    }

    // MARK: - In-Memory Upload

    /// Builds upload using in-memory encoding (for small files < 10MB).
    private func buildInMemoryUpload<Request: NetworkRequest>(
        for request: Request,
        url: URL,
        session: Session,
        headers: HTTPHeaders,
        interceptor: (any RequestInterceptor)?
    ) -> UploadRequest {
        session.upload(
            multipartFormData: { multipartFormData in
                // Add simple files (without metadata)
                if let files = request.files {
                    for (name, data) in files {
                        multipartFormData.append(
                            data,
                            withName: name,
                            fileName: "\(name).\(Self.defaultFileExtension)",
                            mimeType: Self.defaultMimeType
                        )
                    }
                }

                // Add file uploads with custom metadata
                if let fileUploads = request.fileUploads {
                    for (fieldName, upload) in fileUploads {
                        multipartFormData.append(
                            upload.data,
                            withName: fieldName,
                            fileName: upload.fileName,
                            mimeType: upload.mimeType
                        )
                    }
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

    // MARK: - File-Based Upload

    /// Builds upload using file-based encoding (for large files > 10MB).
    ///
    /// This method writes multipart data to a temporary file on disk,
    /// then uploads from that file. This is memory-efficient for large files.
    private func buildFileBasedUpload<Request: NetworkRequest>(
        for request: Request,
        url: URL,
        session: Session,
        headers: HTTPHeaders,
        interceptor: (any RequestInterceptor)?
    ) -> UploadRequest {
        // Create temporary file URL
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("multipart")

        // Build multipart form data
        let formData = MultipartFormData()

        // Add simple files (without metadata)
        if let files = request.files {
            for (name, data) in files {
                formData.append(
                    data,
                    withName: name,
                    fileName: "\(name).\(Self.defaultFileExtension)",
                    mimeType: Self.defaultMimeType
                )
            }
        }

        // Add file uploads with custom metadata
        if let fileUploads = request.fileUploads {
            for (fieldName, upload) in fileUploads {
                formData.append(
                    upload.data,
                    withName: fieldName,
                    fileName: upload.fileName,
                    mimeType: upload.mimeType
                )
            }
        }

        // Add large file uploads from URLs
        if let largeFileUploads = request.largeFileUploads {
            for upload in largeFileUploads {
                formData.append(
                    upload.fileURL,
                    withName: upload.fieldName,
                    fileName: upload.fileName,
                    mimeType: upload.mimeType
                )
            }
        }

        // Add regular parameters as form fields
        if let parameters = request.parameters {
            for (key, value) in parameters {
                if let data = encodeParameter(value) {
                    formData.append(data, withName: key)
                }
            }
        }

        // Write to temporary file
        do {
            try formData.writeEncodedData(to: tempURL)
        } catch {
            debugPrint("⚠️ Failed to write multipart data to file: \(error)")
        }

        // Upload from file
        return session.upload(
            tempURL,
            to: url,
            method: request.method,
            headers: headers,
            interceptor: interceptor
        )
    }

    // MARK: - Parameter Encoding

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
