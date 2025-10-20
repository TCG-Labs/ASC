// TestDataFactory.swift
// ASC Tests
//
// Factory for creating test data and temporary files.

import Foundation

/// Factory for creating test data and temporary files.
///
/// Centralizes creation of test data to avoid duplication and improve test readability.
public enum TestDataFactory {
    // MARK: - File Size Constants

    /// Common file sizes for testing.
    public enum FileSize {
        /// Small file size: 5MB (below 10MB threshold).
        public static let small = 5_000_000

        /// Threshold file size: 10MB (boundary for encoding selection).
        public static let threshold = 10_000_000

        /// Large file size: 15MB (above 10MB threshold).
        public static let large = 15_000_000

        /// Very large file size: 100MB (stress test).
        public static let veryLarge = 100_000_000

        /// Just below threshold: 10MB - 1 byte.
        public static let justBelowThreshold = 9_999_999

        /// Just above threshold: 10MB + 1 byte.
        public static let justAboveThreshold = 10_000_001

        /// Tiny file: 100 bytes.
        public static let tiny = 100

        /// Medium file: 11MB.
        public static let medium = 11_000_000

        /// Extra large file: 12MB.
        public static let extraLarge = 12_000_000
    }

    // MARK: - Data Patterns

    /// Common byte patterns for test data.
    public enum Pattern {
        /// 0xFF pattern.
        public static let ff: UInt8 = 0xFF

        /// 0xAA pattern.
        public static let aa: UInt8 = 0xAA

        /// 0xAB pattern.
        public static let ab: UInt8 = 0xAB

        /// 0xBB pattern.
        public static let bb: UInt8 = 0xBB

        /// 0xCC pattern.
        public static let cc: UInt8 = 0xCC
    }

    // MARK: - Data Creation

    /// Creates test data with specified size and pattern.
    ///
    /// - Parameters:
    ///   - size: Size of data in bytes
    ///   - pattern: Byte pattern to repeat (default: 0xFF)
    /// - Returns: Data filled with pattern
    public static func data(size: Int, pattern: UInt8 = Pattern.ff) -> Data {
        Data(repeating: pattern, count: size)
    }

    /// Creates small test data (5MB).
    public static func smallData(pattern: UInt8 = Pattern.ff) -> Data {
        data(size: FileSize.small, pattern: pattern)
    }

    /// Creates large test data (15MB).
    public static func largeData(pattern: UInt8 = Pattern.ff) -> Data {
        data(size: FileSize.large, pattern: pattern)
    }

    /// Creates data just below 10MB threshold.
    public static func justBelowThresholdData(pattern: UInt8 = Pattern.ff) -> Data {
        data(size: FileSize.justBelowThreshold, pattern: pattern)
    }

    /// Creates data just above 10MB threshold.
    public static func justAboveThresholdData(pattern: UInt8 = Pattern.ff) -> Data {
        data(size: FileSize.justAboveThreshold, pattern: pattern)
    }

    // MARK: - Temporary File Creation

    /// Result of creating a temporary file.
    public struct TempFile {
        /// URL of the temporary file.
        public let url: URL

        /// Cleanup closure that removes the file.
        public let cleanup: () -> Void

        /// Executes cleanup automatically.
        public func remove() {
            cleanup()
        }
    }

    /// Creates a temporary file with test data.
    ///
    /// The file is created in the system temporary directory.
    /// Call `cleanup()` or use `defer { cleanup() }` to remove the file.
    ///
    /// - Parameters:
    ///   - name: File name (default: random UUID)
    ///   - extension: File extension (default: "dat")
    ///   - size: Size of file data in bytes
    ///   - pattern: Byte pattern for data (default: 0xFF)
    /// - Returns: Tuple with file URL and cleanup closure
    /// - Throws: If file creation fails
    public static func createTempFile(
        name: String = UUID().uuidString,
        extension: String = "dat",
        size: Int,
        pattern: UInt8 = Pattern.ff
    ) throws -> TempFile {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir
            .appendingPathComponent(name)
            .appendingPathExtension(`extension`)

        let fileData = data(size: size, pattern: pattern)
        try fileData.write(to: fileURL)

        let cleanup = {
            _ = try? FileManager.default.removeItem(at: fileURL)
        }

        return TempFile(url: fileURL, cleanup: cleanup)
    }

    /// Creates a small temporary file (5MB).
    public static func createSmallTempFile(
        name: String = UUID().uuidString,
        extension: String = "dat",
        pattern: UInt8 = Pattern.ff
    ) throws -> TempFile {
        try createTempFile(
            name: name,
            extension: `extension`,
            size: FileSize.small,
            pattern: pattern
        )
    }

    /// Creates a large temporary file (15MB).
    public static func createLargeTempFile(
        name: String = UUID().uuidString,
        extension: String = "dat",
        pattern: UInt8 = Pattern.ff
    ) throws -> TempFile {
        try createTempFile(
            name: name,
            extension: `extension`,
            size: FileSize.large,
            pattern: pattern
        )
    }

    /// Creates a temporary video file.
    public static func createTempVideoFile(
        name: String = "video",
        size: Int = FileSize.large
    ) throws -> TempFile {
        try createTempFile(name: name, extension: "mp4", size: size)
    }

    /// Creates multiple temporary files.
    ///
    /// - Parameter specs: Array of (name, extension, size) tuples
    /// - Returns: Array of TempFile structs
    /// - Throws: If any file creation fails
    public static func createMultipleTempFiles(
        specs: [(name: String, extension: String, size: Int)]
    ) throws -> [TempFile] {
        try specs.map { name, ext, size in
            try createTempFile(name: name, extension: ext, size: size)
        }
    }

    // MARK: - File Management

    /// Counts temporary .multipart files in temp directory.
    ///
    /// Used for testing encoding method selection (in-memory vs file-based).
    ///
    /// - Returns: Number of .multipart files
    /// - Throws: If directory enumeration fails
    public static func countMultipartFiles() throws -> Int {
        let tempDir = FileManager.default.temporaryDirectory
        let files = try FileManager.default.contentsOfDirectory(
            at: tempDir,
            includingPropertiesForKeys: nil
        )
        return files.filter { $0.pathExtension == "multipart" }.count
    }

    /// Cleans up all .multipart files in temp directory.
    ///
    /// Useful for test cleanup in setUp/tearDown.
    public static func cleanupMultipartFiles() {
        let tempDir = FileManager.default.temporaryDirectory
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: tempDir,
            includingPropertiesForKeys: nil
        ) else { return }

        files
            .filter { $0.pathExtension == "multipart" }
            .forEach { try? FileManager.default.removeItem(at: $0) }
    }

    // MARK: - Convenience Methods

    /// Creates test data with UTF-8 string content.
    public static func stringData(_ string: String) -> Data {
        Data(string.utf8)
    }

    /// Creates empty data.
    public static var emptyData: Data {
        Data()
    }
}
