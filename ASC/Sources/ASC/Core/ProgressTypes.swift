// ProgressTypes.swift
// ASC - Alamofire Swift Client

// Types for tracking upload and download progress.

import Foundation

/// Represents the progress of a network request.
///
/// Use this with `executeWithProgress()` to track upload/download progress.
///
/// Example:
/// ```swift
/// for try await update in client.executeWithProgress(uploadRequest) {
///     switch update {
///     case .progress(let value):
///         progressView.progress = value
///     case .completed(let response):
///         // Upload complete
///     }
/// }
/// ```
public enum ProgressUpdate<Response>: Sendable where Response: Sendable {
    /// Progress update with a value between 0.0 and 1.0.
    ///
    /// - Parameter value: Progress value from 0.0 (0%) to 1.0 (100%)
    case progress(Double)

    /// Request completed successfully with response.
    ///
    /// - Parameter response: The decoded response
    case completed(Response)
}

/// Detailed progress information.
///
/// Provides granular information about upload/download progress.
public struct ProgressInfo: Sendable {
    /// Number of bytes completed.
    public let completedBytes: Int64

    /// Total number of bytes (if known).
    ///
    /// May be `nil` for chunked transfer encoding or streaming responses.
    public let totalBytes: Int64?

    /// Progress as a fraction from 0.0 to 1.0.
    ///
    /// Returns `nil` if total bytes is unknown.
    public var fractionCompleted: Double? {
        guard let totalBytes = totalBytes, totalBytes > 0 else {
            return nil
        }
        return Double(completedBytes) / Double(totalBytes)
    }

    /// Progress as a percentage from 0 to 100.
    ///
    /// Returns `nil` if total bytes is unknown.
    public var percentComplete: Int? {
        guard let fraction = fractionCompleted else {
            return nil
        }
        return Int(fraction * 100)
    }

    /// Creates progress info.
    ///
    /// - Parameters:
    ///   - completedBytes: Number of bytes completed
    ///   - totalBytes: Total number of bytes (optional)
    public init(completedBytes: Int64, totalBytes: Int64?) {
        self.completedBytes = completedBytes
        self.totalBytes = totalBytes
    }
}
