// FileUpload.swift
// ASC - Alamofire Swift Client

// File upload metadata for multipart requests.

import Foundation

/// Metadata for a file upload in a multipart request.
///
/// Use this type when you need fine-grained control over file uploads,
/// including custom MIME types and filenames.
///
/// Example:
/// ```swift
/// let upload = FileUpload(
///     data: imageData,
///     fileName: "profile.jpg",
///     mimeType: "image/jpeg"
/// )
/// ```
public struct FileUpload: Sendable {
    // MARK: - Properties

    /// The file data to upload.
    public let data: Data

    /// The filename to use in the multipart request.
    public let fileName: String

    /// The MIME type of the file.
    ///
    /// Common MIME types:
    /// - Images: `"image/jpeg"`, `"image/png"`, `"image/heic"`
    /// - Videos: `"video/mp4"`, `"video/quicktime"`
    /// - Documents: `"application/pdf"`, `"application/zip"`
    /// - Default: `"application/octet-stream"`
    public let mimeType: String

    // MARK: - Initialization

    /// Creates a new file upload with metadata.
    ///
    /// - Parameters:
    ///   - data: The file data to upload
    ///   - fileName: The filename to use in the multipart request
    ///   - mimeType: The MIME type (defaults to "application/octet-stream")
    public init(
        data: Data,
        fileName: String,
        mimeType: String = "application/octet-stream"
    ) {
        self.data = data
        self.fileName = fileName
        self.mimeType = mimeType
    }

    // MARK: - Convenience Initializers

    /// Creates a file upload for a JPEG image.
    ///
    /// - Parameters:
    ///   - data: The JPEG image data
    ///   - fileName: The filename (defaults to "image.jpg")
    public static func jpeg(data: Data, fileName: String = "image.jpg") -> FileUpload {
        FileUpload(data: data, fileName: fileName, mimeType: "image/jpeg")
    }

    /// Creates a file upload for a PNG image.
    ///
    /// - Parameters:
    ///   - data: The PNG image data
    ///   - fileName: The filename (defaults to "image.png")
    public static func png(data: Data, fileName: String = "image.png") -> FileUpload {
        FileUpload(data: data, fileName: fileName, mimeType: "image/png")
    }

    /// Creates a file upload for a HEIC image.
    ///
    /// - Parameters:
    ///   - data: The HEIC image data
    ///   - fileName: The filename (defaults to "image.heic")
    public static func heic(data: Data, fileName: String = "image.heic") -> FileUpload {
        FileUpload(data: data, fileName: fileName, mimeType: "image/heic")
    }

    /// Creates a file upload for an MP4 video.
    ///
    /// - Parameters:
    ///   - data: The MP4 video data
    ///   - fileName: The filename (defaults to "video.mp4")
    public static func mp4(data: Data, fileName: String = "video.mp4") -> FileUpload {
        FileUpload(data: data, fileName: fileName, mimeType: "video/mp4")
    }

    /// Creates a file upload for a PDF document.
    ///
    /// - Parameters:
    ///   - data: The PDF document data
    ///   - fileName: The filename (defaults to "document.pdf")
    public static func pdf(data: Data, fileName: String = "document.pdf") -> FileUpload {
        FileUpload(data: data, fileName: fileName, mimeType: "application/pdf")
    }

    /// Creates a file upload for a ZIP archive.
    ///
    /// - Parameters:
    ///   - data: The ZIP archive data
    ///   - fileName: The filename (defaults to "archive.zip")
    public static func zip(data: Data, fileName: String = "archive.zip") -> FileUpload {
        FileUpload(data: data, fileName: fileName, mimeType: "application/zip")
    }
}

/// Large file upload reference for file-based encoding.
///
/// Use this type for large files (> 10MB) to avoid loading all data into memory.
/// The file will be streamed from disk during upload.
///
/// Example:
/// ```swift
/// let largeFile = LargeFileUpload(
///     fileURL: videoURL,
///     fieldName: "video",
///     fileName: "my-video.mp4",
///     mimeType: "video/mp4"
/// )
/// ```
public struct LargeFileUpload: Sendable {
    // MARK: - Properties

    /// The URL of the file to upload.
    public let fileURL: URL

    /// The field name in the multipart request.
    public let fieldName: String

    /// The filename to use in the multipart request.
    public let fileName: String

    /// The MIME type of the file.
    public let mimeType: String

    // MARK: - Initialization

    /// Creates a new large file upload.
    ///
    /// - Parameters:
    ///   - fileURL: The URL of the file to upload
    ///   - fieldName: The field name in the multipart request
    ///   - fileName: The filename to use (defaults to the file's name)
    ///   - mimeType: The MIME type (defaults to "application/octet-stream")
    public init(
        fileURL: URL,
        fieldName: String,
        fileName: String? = nil,
        mimeType: String = "application/octet-stream"
    ) {
        self.fileURL = fileURL
        self.fieldName = fieldName
        self.fileName = fileName ?? fileURL.lastPathComponent
        self.mimeType = mimeType
    }
}
