// ASCConstants.swift
// ASC - Alamofire Swift Client

// Centralized constants for the ASC library.

import Foundation

/// Centralized constants used throughout the ASC library.
///
/// Provides a single source of truth for default values and thresholds.
public enum ASCConstants {
    // MARK: - File Upload

    /// Constants related to file upload and multipart encoding.
    public enum FileUpload {
        /// Default file size threshold for switching encoding methods.
        ///
        /// Files larger than this threshold use file-based encoding to avoid memory issues.
        /// Files smaller than this threshold use in-memory encoding for better performance.
        ///
        /// Default is 10MB (10,000,000 bytes).
        public static let defaultSizeThreshold: Int = 10_000_000

        /// Default file extension for uploads without specified extension.
        public static let defaultExtension: String = "dat"

        /// Default MIME type for files without specified type.
        public static let defaultMimeType: String = "application/octet-stream"
    }

    // MARK: - Network

    /// Constants related to network requests and responses.
    public enum Network {
        /// Default request timeout in seconds.
        public static let defaultTimeout: TimeInterval = 60.0

        /// Default retry limit for failed requests.
        public static let defaultRetryLimit: Int = 3
    }
}
