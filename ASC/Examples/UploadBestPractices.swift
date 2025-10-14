// UploadBestPractices.swift
// ASC - File Upload Best Practices
//
// Comprehensive guide to file uploads with ASC library.
// This file demonstrates best practices, common patterns, and gotchas.

import ASC
import Foundation

// MARK: - File Upload Best Practices Guide

/*
 # 📤 File Upload Best Practices with ASC

 ## Table of Contents

 1. [File Size Guidelines](#file-size-guidelines)
 2. [MIME Types](#mime-types)
 3. [Memory Management](#memory-management)
 4. [Error Handling](#error-handling)
 5. [Timeout Configuration](#timeout-configuration)
 6. [Security Considerations](#security-considerations)
 7. [Code Examples](#code-examples)

 ---

 ## 1. File Size Guidelines

 ### Small Files (< 10MB)
 ✅ **DO**: Use `files` or `fileUploads` properties
 ✅ **Encoding**: In-memory (automatic)
 ✅ **Use Cases**: Profile pictures, documents, small images

 ```swift
 struct UploadAvatar: NetworkRequest {
     var files: [String: Data]? {
         ["avatar": imageData]
     }
 }
 ```

 ### Large Files (> 10MB)
 ✅ **DO**: Use `largeFileUploads` property
 ✅ **Encoding**: File-based (automatic)
 ✅ **Use Cases**: Videos, high-resolution images, archives

 ```swift
 struct UploadVideo: NetworkRequest {
     var largeFileUploads: [LargeFileUpload]? {
         [LargeFileUpload(fileURL: videoURL, fieldName: "video")]
     }
 }
 ```

 ### Size Threshold
 - ASC automatically switches to file-based encoding at **10MB**
 - You can force file-based encoding by using `largeFileUploads`
 - File-based encoding prevents memory issues with large files

 ---

 ## 2. MIME Types

 ### Common MIME Types

 **Images:**
 - JPEG: `"image/jpeg"`
 - PNG: `"image/png"`
 - HEIC: `"image/heic"`
 - GIF: `"image/gif"`
 - WebP: `"image/webp"`

 **Videos:**
 - MP4: `"video/mp4"`
 - QuickTime: `"video/quicktime"`
 - WebM: `"video/webm"`

 **Documents:**
 - PDF: `"application/pdf"`
 - ZIP: `"application/zip"`
 - JSON: `"application/json"`
 - Text: `"text/plain"`

 ### Using Custom MIME Types

 **Option 1: Convenience Methods**
 ```swift
 var fileUploads: [String: FileUpload]? {
     ["photo": .jpeg(data: imageData, fileName: "photo.jpg")]
 }
 ```

 **Option 2: Custom MIME Type**
 ```swift
 var fileUploads: [String: FileUpload]? {
     ["photo": FileUpload(
         data: imageData,
         fileName: "photo.jpg",
         mimeType: "image/jpeg"
     )]
 }
 ```

 **Option 3: Simple Upload (Default MIME)**
 ```swift
 var files: [String: Data]? {
     ["file": data]  // Uses "application/octet-stream"
 }
 ```

 ---

 ## 3. Memory Management

 ### ❌ BAD: Loading Large Files into Memory

 ```swift
 // DON'T DO THIS with large files!
 let videoData = try Data(contentsOf: videoURL)  // 100MB in memory!
 var files: [String: Data]? {
     ["video": videoData]  // Another 100MB during upload!
 }
 // Total: 200MB+ memory usage 💥
 ```

 ### ✅ GOOD: Using File-Based Upload

 ```swift
 // DO THIS with large files!
 var largeFileUploads: [LargeFileUpload]? {
     [LargeFileUpload(
         fileURL: videoURL,  // Streamed from disk
         fieldName: "video",
         mimeType: "video/mp4"
     )]
 }
 // Memory usage: ~1-2MB (streaming buffer)
 ```

 ### Memory Usage Comparison

 | File Size | In-Memory | File-Based |
 |-----------|-----------|------------|
 | 1MB       | ~2MB      | ~1MB       |
 | 10MB      | ~20MB     | ~1MB       |
 | 50MB      | ~100MB    | ~1MB       |
 | 100MB     | ~200MB    | ~1MB       |
 | 500MB     | 💥 Crash  | ~1MB       |

 ---

 ## 4. Error Handling

 ### Common Upload Errors

 **1. Timeout Errors**
 ```swift
 do {
     try await client.execute(uploadRequest)
 } catch let error as NetworkError {
     switch error {
     case .timeout(let duration):
         // File too large for timeout
         // Solution: Increase timeout or reduce file size
         debugPrint("Upload timed out after \(duration)s")
     default:
         break
     }
 }
 ```

 **2. Network Connection Lost**
 ```swift
 catch let error as NetworkError {
     switch error {
     case .noConnection:
         // No internet connection
         // Solution: Queue upload for later, show offline message
         debugPrint("No connection - queuing upload")
     case .networkConnectionLost:
         // Connection lost during upload
         // Solution: Retry upload
         debugPrint("Connection lost - retrying")
     default:
         break
     }
 }
 ```

 **3. Server Errors**
 ```swift
 catch let error as ResponseError {
     switch error {
     case .serverError(let code, let message):
         // Server rejected upload (500, 502, 503)
         // Solution: Retry with exponential backoff
         debugPrint("Server error \(code): \(message ?? "")")
     case .clientError(413, _):
         // File too large (413 Payload Too Large)
         // Solution: Compress or resize file
         debugPrint("File too large for server")
     case .clientError(415, _):
         // Unsupported media type
         // Solution: Check MIME type
         debugPrint("Server doesn't support this file type")
     default:
         break
     }
 }
 ```

 ### Robust Error Handling Pattern

 ```swift
 func uploadFile(_ request: some NetworkRequest) async throws {
     var retryCount = 0
     let maxRetries = 3

     while retryCount < maxRetries {
         do {
             return try await client.execute(request)
         } catch let error as NetworkError {
             switch error {
             case .timeout, .networkConnectionLost:
                 retryCount += 1
                 if retryCount < maxRetries {
                     // Exponential backoff
                     try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(retryCount)) * 1_000_000_000))
                     continue
                 }
             case .noConnection:
                 throw UploadError.offline
             default:
                 throw error
             }
         }
         throw error
     }
 }
 ```

 ---

 ## 5. Timeout Configuration

 ### Timeout Guidelines

 **Small Files (< 1MB)**
 - Timeout: 30-60 seconds
 - Use default timeout

 ```swift
 struct UploadSmallFile: NetworkRequest {
     // No custom timeout needed
 }
 ```

 **Medium Files (1-10MB)**
 - Timeout: 60-120 seconds

 ```swift
 struct UploadMediumFile: NetworkRequest {
     var timeout: TimeInterval? { 120.0 }
 }
 ```

 **Large Files (10-100MB)**
 - Timeout: 120-300 seconds (2-5 minutes)

 ```swift
 struct UploadLargeFile: NetworkRequest {
     var timeout: TimeInterval? { 300.0 }
 }
 ```

 **Very Large Files (> 100MB)**
 - Timeout: 300-600 seconds (5-10 minutes)
 - Consider chunked uploads

 ```swift
 struct UploadHugeFile: NetworkRequest {
     var timeout: TimeInterval? { 600.0 }
 }
 ```

 ### Dynamic Timeout Calculation

 ```swift
 func calculateTimeout(for fileSize: Int) -> TimeInterval {
     let sizeInMB = Double(fileSize) / 1_000_000
     let uploadSpeed = 1.0 // MB/s (assume slow connection)
     let baseTimeout = 30.0
     let uploadTime = sizeInMB / uploadSpeed
     return baseTimeout + uploadTime + 30.0 // Add buffer
 }
 ```

 ---

 ## 6. Security Considerations

 ### File Validation

 **1. Check File Size**
 ```swift
 guard fileData.count <= 10_000_000 else {
     throw UploadError.fileTooLarge
 }
 ```

 **2. Validate MIME Type**
 ```swift
 let allowedTypes = ["image/jpeg", "image/png", "application/pdf"]
 guard allowedTypes.contains(mimeType) else {
     throw UploadError.unsupportedFileType
 }
 ```

 **3. Validate File Extension**
 ```swift
 let allowedExtensions = ["jpg", "jpeg", "png", "pdf"]
 let ext = fileURL.pathExtension.lowercased()
 guard allowedExtensions.contains(ext) else {
     throw UploadError.invalidFileExtension
 }
 ```

 **4. Scan for Malware** (if applicable)
 - Use system APIs or third-party scanners
 - Never upload files from untrusted sources without scanning

 ### Privacy Considerations

 **1. Strip Metadata from Images**
 ```swift
 #if canImport(UIKit)
 func stripMetadata(from image: UIImage) -> Data? {
     // Remove EXIF data (GPS, camera info, etc.)
     return image.jpegData(compressionQuality: 0.8)
 }
 #endif
 ```

 **2. Encrypt Sensitive Files**
 - Consider encrypting files before upload
 - Use HTTPS (ASC uses HTTPS by default)

 ---

 ## 7. Code Examples

 ### Example 1: Upload Profile Picture

 ```swift
 enum UserAPI {
     struct UploadAvatar: NetworkRequest {
         typealias Response = User
         let userId: String
         let imageData: Data

         var path: String { "/users/\(userId)/avatar" }
         var method: HTTPMethod { .post }

         var fileUploads: [String: FileUpload]? {
             ["avatar": .jpeg(data: imageData, fileName: "avatar.jpg")]
         }

         var timeout: TimeInterval? { 60.0 }
     }
 }

 // Usage
 func uploadAvatar(_ image: UIImage) async throws -> User {
     guard let imageData = image.jpegData(compressionQuality: 0.7) else {
         throw UploadError.invalidImage
     }

     guard imageData.count <= 5_000_000 else {
         throw UploadError.fileTooLarge
     }

     let request = UserAPI.UploadAvatar(userId: "123", imageData: imageData)
     return try await client.execute(request)
 }
 ```

 ### Example 2: Upload Large Video (Memory-Efficient)

 ```swift
 enum MediaAPI {
     struct UploadVideo: NetworkRequest {
         typealias Response = Video
         let videoURL: URL
         let title: String

         var path: String { "/videos" }
         var method: HTTPMethod { .post }

         var largeFileUploads: [LargeFileUpload]? {
             [LargeFileUpload(
                 fileURL: videoURL,
                 fieldName: "video",
                 fileName: "\(UUID().uuidString).mp4",
                 mimeType: "video/mp4"
             )]
         }

         var parameters: Parameters? {
             ["title": title]
         }

         var timeout: TimeInterval? { 300.0 }
     }
 }

 // Usage
 func uploadVideo(at url: URL, title: String) async throws -> Video {
     // Validate file exists
     guard FileManager.default.fileExists(atPath: url.path) else {
         throw UploadError.fileNotFound
     }

     // Get file size
     let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
     let fileSize = attributes[.size] as? Int ?? 0

     // Check max size (e.g., 500MB)
     guard fileSize <= 500_000_000 else {
         throw UploadError.fileTooLarge
     }

     let request = MediaAPI.UploadVideo(videoURL: url, title: title)
     return try await client.execute(request)
 }
 ```

 ### Example 3: Upload Multiple Files

 ```swift
 enum DocumentAPI {
     struct UploadDocuments: NetworkRequest {
         typealias Response = UploadResult
         let documents: [Document]

         var path: String { "/documents/batch" }
         var method: HTTPMethod { .post }

         var fileUploads: [String: FileUpload]? {
             var uploads: [String: FileUpload] = [:]
             for (index, doc) in documents.enumerated() {
                 uploads["document_\(index)"] = FileUpload(
                     data: doc.data,
                     fileName: doc.fileName,
                     mimeType: doc.mimeType
                 )
             }
             return uploads
         }

         var timeout: TimeInterval? { 180.0 }
     }
 }

 struct Document {
     let data: Data
     let fileName: String
     let mimeType: String
 }

 // Usage
 func uploadDocuments(_ documents: [Document]) async throws -> UploadResult {
     // Validate total size
     let totalSize = documents.reduce(0) { $0 + $1.data.count }
     guard totalSize <= 50_000_000 else { // 50MB total
         throw UploadError.totalSizeTooLarge
     }

     let request = DocumentAPI.UploadDocuments(documents: documents)
     return try await client.execute(request)
 }
 ```

 ### Example 4: Upload with Progress Tracking (Conceptual)

 ```swift
 // Note: Progress tracking requires additional Alamofire APIs
 // This is a conceptual example
 func uploadWithProgress(
     _ request: some NetworkRequest,
     onProgress: @escaping (Double) -> Void
 ) async throws {
     // ASC doesn't expose progress directly yet
     // You would need to access the underlying Alamofire Session
     // or extend NetworkClient to support progress
 }
 ```

 ---

 ## Summary Checklist

 ### Before Upload ✅

 - [ ] Validate file size
 - [ ] Validate file type/extension
 - [ ] Choose correct upload method (files vs largeFileUploads)
 - [ ] Set appropriate timeout
 - [ ] Strip sensitive metadata if needed
 - [ ] Compress large images if needed

 ### During Upload ✅

 - [ ] Handle timeout errors
 - [ ] Handle network errors
 - [ ] Show progress indicator to user
 - [ ] Allow cancellation if needed

 ### After Upload ✅

 - [ ] Verify upload success
 - [ ] Clean up temporary files
 - [ ] Update UI with result
 - [ ] Handle server errors gracefully

 ---

 ## Common Mistakes to Avoid

 ### ❌ Mistake 1: Loading Large Files into Memory
 ```swift
 // BAD: 100MB file loaded into memory
 let data = try Data(contentsOf: largeFileURL)
 var files: [String: Data]? { ["file": data] }
 ```

 ### ✅ Fix: Use File-Based Upload
 ```swift
 // GOOD: File streamed from disk
 var largeFileUploads: [LargeFileUpload]? {
     [LargeFileUpload(fileURL: largeFileURL, fieldName: "file")]
 }
 ```

 ### ❌ Mistake 2: Default Timeout for Large Files
 ```swift
 // BAD: 100MB file with 60s timeout
 struct Upload: NetworkRequest {
     // Will timeout!
 }
 ```

 ### ✅ Fix: Custom Timeout
 ```swift
 // GOOD: Long timeout for large file
 struct Upload: NetworkRequest {
     var timeout: TimeInterval? { 300.0 }
 }
 ```

 ### ❌ Mistake 3: Not Handling Upload Errors
 ```swift
 // BAD: No error handling
 try await client.execute(uploadRequest)
 ```

 ### ✅ Fix: Comprehensive Error Handling
 ```swift
 // GOOD: Handle all error types
 do {
     try await client.execute(uploadRequest)
 } catch let error as NetworkError {
     // Handle network errors
 } catch let error as ResponseError {
     // Handle server errors
 }
 ```

 ### ❌ Mistake 4: Wrong MIME Type
 ```swift
 // BAD: All files use default MIME type
 var files: [String: Data]? {
     ["image": jpegData]  // "application/octet-stream"
 }
 ```

 ### ✅ Fix: Correct MIME Type
 ```swift
 // GOOD: Correct MIME type
 var fileUploads: [String: FileUpload]? {
     ["image": .jpeg(data: jpegData, fileName: "photo.jpg")]
 }
 ```

 ---

 ## Performance Tips

 1. **Compress Images**: Use 70-80% JPEG quality
 2. **Resize Large Images**: Max 2048x2048 for most apps
 3. **Use File-Based Upload**: For files > 10MB
 4. **Background Uploads**: Consider URLSession background tasks for very large files
 5. **Chunked Uploads**: For files > 100MB, consider implementing chunked upload
 6. **Cancel Uploads**: Implement cancellation for better UX
 7. **Queue Uploads**: Don't upload multiple large files simultaneously

 ---

 ## Testing Tips

 1. **Test with Large Files**: Test with 50MB+ files
 2. **Test Slow Networks**: Simulate 3G/EDGE speeds
 3. **Test Network Loss**: Simulate connection drops
 4. **Test Timeouts**: Verify timeout handling
 5. **Test Server Errors**: Mock 500, 503 errors
 6. **Test Memory**: Profile with Instruments
 7. **Test Edge Cases**: Empty files, huge files, invalid types

 ---

 **Generated by**: ASC Library Documentation Team
 **Last Updated**: October 13, 2025
 **Version**: 1.0
 */

// MARK: - Custom Error Type

enum UploadError: Error, LocalizedError {
    case fileTooLarge
    case totalSizeTooLarge
    case unsupportedFileType
    case invalidFileExtension
    case invalidImage
    case fileNotFound
    case offline

    var errorDescription: String? {
        switch self {
        case .fileTooLarge:
            return "File size exceeds maximum allowed"
        case .totalSizeTooLarge:
            return "Total size of all files exceeds maximum allowed"
        case .unsupportedFileType:
            return "File type not supported"
        case .invalidFileExtension:
            return "File extension not allowed"
        case .invalidImage:
            return "Invalid or corrupted image file"
        case .fileNotFound:
            return "File not found at specified path"
        case .offline:
            return "No internet connection"
        }
    }
}
