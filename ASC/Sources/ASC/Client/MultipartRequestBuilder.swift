// MultipartRequestBuilder.swift
// ASC - Alamofire Swift Client
//
// Multipart form data request builder.

import Foundation
import Alamofire

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
    /// - Returns: Configured UploadRequest ready to execute
    internal func buildUpload<Request: NetworkRequest>(
        for request: Request,
        files: [String: Data],
        url: URL,
        session: Session,
        headers: HTTPHeaders
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
                        if let data = "\(value)".data(using: .utf8) {
                            multipartFormData.append(data, withName: key)
                        }
                    }
                }
            },
            to: url,
            method: request.method,
            headers: headers
        )
    }
}
