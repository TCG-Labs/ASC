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

    // MARK: - Convenience Factory

    /// Creates a file upload for a specific file type.
    ///
    /// - Parameters:
    ///   - data: The file data
    ///   - type: The file type (determines MIME type and default filename)
    ///   - fileName: Optional custom filename (uses type's default if nil)
    /// - Returns: Configured FileUpload instance
    public static func create(data: Data, type: FileType, fileName: String? = nil) -> FileUpload {
        FileUpload(
            data: data,
            fileName: fileName ?? type.defaultFileName,
            mimeType: type.mimeType
        )
    }

    /// Convenience initializers for common file types.
    public static func jpeg(data: Data, fileName: String = "image.jpg") -> FileUpload {
        create(data: data, type: .jpeg, fileName: fileName)
    }

    public static func png(data: Data, fileName: String = "image.png") -> FileUpload {
        create(data: data, type: .png, fileName: fileName)
    }

    public static func heic(data: Data, fileName: String = "image.heic") -> FileUpload {
        create(data: data, type: .heic, fileName: fileName)
    }

    public static func mp4(data: Data, fileName: String = "video.mp4") -> FileUpload {
        create(data: data, type: .mp4, fileName: fileName)
    }

    public static func pdf(data: Data, fileName: String = "document.pdf") -> FileUpload {
        create(data: data, type: .pdf, fileName: fileName)
    }

    public static func zip(data: Data, fileName: String = "archive.zip") -> FileUpload {
        create(data: data, type: .zip, fileName: fileName)
    }
}

// MARK: - FileType

/// Enum representing common file types with their MIME types and default extensions.
///
/// Makes it easy to create file uploads with correct MIME types.
public enum FileType: Sendable {
    case jpeg
    case png
    case heic
    case mp4
    case pdf
    case zip
    case custom(mimeType: String, extension: String)

    /// MIME type for this file type.
    public var mimeType: String {
        switch self {
        case .jpeg: return "image/jpeg"
        case .png: return "image/png"
        case .heic: return "image/heic"
        case .mp4: return "video/mp4"
        case .pdf: return "application/pdf"
        case .zip: return "application/zip"
        case .custom(let mimeType, _): return mimeType
        }
    }

    /// Default file extension for this file type.
    public var fileExtension: String {
        switch self {
        case .jpeg: return "jpg"
        case .png: return "png"
        case .heic: return "heic"
        case .mp4: return "mp4"
        case .pdf: return "pdf"
        case .zip: return "zip"
        case .custom(_, let ext): return ext
        }
    }

    /// Default filename for this file type.
    public var defaultFileName: String {
        switch self {
        case .jpeg, .png, .heic:
            return "image.\(fileExtension)"
        case .mp4:
            return "video.\(fileExtension)"
        case .pdf:
            return "document.\(fileExtension)"
        case .zip:
            return "archive.\(fileExtension)"
        case .custom:
            return "file.\(fileExtension)"
        }
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
