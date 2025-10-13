// FileUploadExample.swift
// ASC - File Upload Example
//
// This example demonstrates how to upload files using ASC:
// - Single file upload
// - Multiple files upload
// - Upload with additional parameters
// - Upload progress tracking (concept)

import ASC
import Foundation

// MARK: - Models

/// Response when uploading a file
struct UploadResponse: Codable, Sendable {
    let success: Bool
    let message: String
    let fileId: String?
    let fileName: String?
    let fileSize: Int?
}

/// User profile with avatar
struct UserProfile: Codable, Sendable {
    let id: Int
    let name: String
    let avatarUrl: String?
}

// MARK: - Upload Requests

/// Upload API using Namespace Enum pattern
enum UploadAPI {
    /// Upload a single image file
    struct Avatar: NetworkRequest {
        typealias Response = UserProfile
        let userId: Int
        let imageData: Data
        let fileName: String

        var path: String { "/users/{userId}/avatar" }
        var method: HTTPMethod { .post }
        var pathParameters: [String: String]? {
            ["userId": String(userId)]
        }

        // Files to upload (multipart/form-data)
        var files: [String: Data]? {
            ["avatar": imageData]
        }

        // Custom headers for upload
        var headers: HTTPHeaders? {
            HTTPHeaders([
                HTTPHeader(name: "X-File-Name", value: fileName),
                .accept("application/json")
            ])
        }

        // Longer timeout for uploads
        var timeout: TimeInterval? { 120.0 }
    }

    /// Upload multiple files at once
    struct Documents: NetworkRequest {
        typealias Response = UploadResponse
        let documents: [String: Data]
        let description: String

        var path: String { "/documents/upload" }
        var method: HTTPMethod { .post }

        // Multiple files
        var files: [String: Data]? { documents }

        // Additional form parameters
        var parameters: Parameters? {
            [
                "description": description,
                "uploadedAt": ISO8601DateFormatter().string(from: Date())
            ]
        }

        var timeout: TimeInterval? { 180.0 }
    }

    /// Upload with empty response (204 No Content)
    struct File: NetworkRequest {
        typealias Response = ASCEmptyResponse
        let fileData: Data
        let fileType: String

        var path: String { "/upload" }
        var method: HTTPMethod { .post }
        var files: [String: Data]? {
            ["file": fileData]
        }
        var headers: HTTPHeaders? {
            HTTPHeaders([
                HTTPHeader(name: "X-File-Type", value: fileType)
            ])
        }
    }
}

// MARK: - File Upload Service

@MainActor
class FileUploadService {
    private let client: NetworkClient

    init(baseURL: String = "https://httpbin.org") {
        // httpbin.org provides testing endpoints including file uploads
        self.client = NetworkClient(baseURL: baseURL)
        debugPrint("📤 File Upload Service initialized")
        debugPrint("   Base URL: \(baseURL)")
        debugPrint()
    }

    // MARK: - Example Methods

    /// Example 1: Upload a single image
    func uploadAvatar(userId: Int, imageData: Data, fileName: String) async throws {
        debugPrint("📸 Uploading avatar for user #\(userId)...")
        debugPrint("   File: \(fileName)")
        debugPrint("   Size: \(ByteCountFormatter.string(fromByteCount: Int64(imageData.count), countStyle: .file))")
        debugPrint()

        // Note: This is a simulated example since httpbin doesn't return UserProfile
        // In production, you'd use your actual API endpoint

        // For demo, we'll show the request structure
        let request = UploadAPI.Avatar(
            userId: userId,
            imageData: imageData,
            fileName: fileName
        )

        debugPrint("Request details:")
        debugPrint("   • Method: \(request.method.rawValue)")
        debugPrint("   • Path: \(request.path)")
        debugPrint("   • Files: \(request.files?.count ?? 0)")
        debugPrint("   • Timeout: \(request.timeout ?? 60)s")
        debugPrint()

        // In production:
        // let profile = try await client.execute(request)
        // debugPrint("✅ Avatar uploaded successfully")
        // debugPrint("   Avatar URL: \(profile.avatarUrl ?? "N/A")")

        debugPrint("✅ Avatar upload request prepared")
        debugPrint()
    }

    /// Example 2: Upload multiple documents
    func uploadDocuments() async throws {
        debugPrint("📄 Uploading multiple documents...")

        // Create sample files
        let file1Data = Data("Document 1 content".utf8)
        let file2Data = Data("Document 2 content".utf8)
        let file3Data = Data("Document 3 content".utf8)

        let documents: [String: Data] = [
            "document1.txt": file1Data,
            "document2.txt": file2Data,
            "document3.txt": file3Data
        ]

        debugPrint("   Files: \(documents.count)")
        documents.forEach { fileName, data in
            debugPrint("   • \(fileName) - \(data.count) bytes")
        }
        debugPrint()

        let request = UploadAPI.Documents(
            documents: documents,
            description: "Batch upload of documents"
        )

        debugPrint("Request details:")
        debugPrint("   • Files count: \(request.files?.count ?? 0)")
        debugPrint("   • Has parameters: \(request.parameters != nil)")
        debugPrint("   • Timeout: \(request.timeout ?? 60)s")
        debugPrint()

        debugPrint("✅ Multiple documents upload request prepared")
        debugPrint()
    }

    /// Example 3: Upload to httpbin.org (working example)
    func uploadToHttpBin() async throws {
        debugPrint("🌐 Uploading to httpbin.org (real test)...")

        // Create test file data
        let testData = Data("Hello from ASC! This is a test file upload.".utf8)

        // httpbin.org endpoint for testing uploads
        struct HttpBinUploadRequest: NetworkRequest {
            typealias Response = HttpBinResponse
            let fileData: Data

            var baseURL: String? { "https://httpbin.org" }
            var path: String { "/post" }
            var method: HTTPMethod { .post }
            var files: [String: Data]? {
                ["file": fileData]
            }
        }

        struct HttpBinResponse: Codable, Sendable {
            let files: [String: String]?
            let form: [String: String]?
            let headers: [String: String]?
        }

        debugPrint("   Uploading test file (\(testData.count) bytes)...")

        let response = try await client.execute(
            HttpBinUploadRequest(fileData: testData)
        )

        debugPrint("\n✅ Upload successful!")
        debugPrint("   Files received by server: \(response.files?.count ?? 0)")
        if let files = response.files {
            files.forEach { key, value in
                debugPrint("   • \(key): \(value.prefix(50))...")
            }
        }
        debugPrint()
    }

    /// Example 4: Upload with additional form data
    func uploadWithMetadata() async throws {
        debugPrint("📋 Uploading file with metadata...")

        let imageData = createSampleImageData()
        let fileName = "profile-picture.jpg"

        // Request with both files and parameters
        struct UploadWithMetadataRequest: NetworkRequest {
            typealias Response = HttpBinResponse
            let imageData: Data
            let metadata: [String: Any]

            var baseURL: String? { "https://httpbin.org" }
            var path: String { "/post" }
            var method: HTTPMethod { .post }

            var files: [String: Data]? {
                ["image": imageData]
            }

            var parameters: Parameters? {
                [
                    "fileName": "profile-picture.jpg",
                    "category": "profile",
                    "public": true,
                    "tags": ["profile", "avatar", "user"]
                ]
            }
        }

        struct HttpBinResponse: Codable, Sendable {
            let files: [String: String]?
            let form: [String: String]?
        }

        debugPrint("   File: \(fileName)")
        debugPrint("   Size: \(ByteCountFormatter.string(fromByteCount: Int64(imageData.count), countStyle: .file))")
        debugPrint("   Metadata: 4 fields")
        debugPrint()

        let response = try await client.execute(
            UploadWithMetadataRequest(imageData: imageData, metadata: [:])
        )

        debugPrint("✅ Upload with metadata successful!")
        debugPrint("   Form fields received: \(response.form?.count ?? 0)")
        if let form = response.form {
            form.forEach { key, value in
                debugPrint("   • \(key): \(value)")
            }
        }
        debugPrint()
    }

    /// Example 5: Handle upload errors
    func demonstrateUploadError() async {
        debugPrint("⚠️  Demonstrating upload error handling...")
        debugPrint()

        let largeFile = Data(repeating: 0, count: 100_000_000) // 100MB

        struct LargeUploadRequest: NetworkRequest {
            typealias Response = ASCEmptyResponse
            let fileData: Data

            var baseURL: String? { "https://httpbin.org" }
            var path: String { "/post" }
            var method: HTTPMethod { .post }
            var files: [String: Data]? { ["file": fileData] }
            var timeout: TimeInterval? { 5.0 } // Short timeout to trigger error
        }

        do {
            debugPrint("   Attempting to upload \(ByteCountFormatter.string(fromByteCount: Int64(largeFile.count), countStyle: .file)) file...")
            debugPrint("   Timeout: 5s (intentionally short)")
            debugPrint()

            try await client.execute(LargeUploadRequest(fileData: largeFile))

            debugPrint("✅ Upload completed (unexpected)")
        } catch let error as NetworkError {
            debugPrint("❌ Network error occurred (as expected):")
            switch error {
            case .timeout(let duration):
                debugPrint("   • Timeout after \(duration)s")
                debugPrint("   • Solution: Increase timeout or reduce file size")
            case .noConnection:
                debugPrint("   • No internet connection")
            default:
                debugPrint("   • \(error.errorDescription ?? "Unknown error")")
            }
        } catch let error as ResponseError {
            debugPrint("❌ Response error:")
            debugPrint("   • \(error.errorDescription ?? "Unknown error")")
        } catch {
            debugPrint("❌ Unexpected error:")
            debugPrint("   • \(error.localizedDescription)")
        }
        debugPrint()
    }

    // MARK: - Helper Methods

    private func createSampleImageData() -> Data {
        // Create a simple "image" (just text for demo)
        let imageContent = """
        SAMPLE IMAGE DATA
        This would be actual image bytes in production.
        For example: JPEG, PNG, or HEIC data.
        """
        return Data(imageContent.utf8)
    }
}

// MARK: - File Upload Examples Runner

@MainActor
func runFileUploadExamples() async {
    debugPrint("=" * 70)
    debugPrint("ASC Library - File Upload Examples")
    debugPrint("=" * 70)
    debugPrint()

    let service = FileUploadService()

    do {
        // Example 1: Single file upload (structure demo)
        let sampleImage = Data("Sample image data".utf8)
        try await service.uploadAvatar(
            userId: 123,
            imageData: sampleImage,
            fileName: "avatar.jpg"
        )

        // Example 2: Multiple files (structure demo)
        try await service.uploadDocuments()

        // Example 3: Real upload to httpbin.org
        try await service.uploadToHttpBin()

        // Example 4: Upload with metadata
        try await service.uploadWithMetadata()

        // Example 5: Error handling
        await service.demonstrateUploadError()

        debugPrint("=" * 70)
        debugPrint("✅ File upload examples completed!")
        debugPrint("=" * 70)

    } catch {
        debugPrint("\n❌ Example failed:")
        debugPrint(error)
    }
}

// Helper
extension String {
    static func * (left: String, right: Int) -> String {
        String(repeating: left, count: right)
    }
}

// MARK: - Usage Guide

/*
 # File Upload with ASC

 ## Basic Structure

 To upload files, define the `files` property in your NetworkRequest:

 ```swift
 struct UploadRequest: NetworkRequest {
     typealias Response = UploadResponse

     let fileData: Data

     var path: String { "/upload" }
     var method: HTTPMethod { .post }

     // Define files to upload
     var files: [String: Data]? {
         ["file": fileData]
     }
 }
 ```

 ## Key Concepts

 ### 1. Multipart Form Data
 When `files` is not nil, ASC automatically:
 - Sets Content-Type to multipart/form-data
 - Creates proper boundaries
 - Encodes files and parameters correctly

 ### 2. File Keys
 The dictionary key is the form field name:
 ```swift
 var files: [String: Data]? {
     ["avatar": imageData]  // Server expects "avatar" field
 }
 ```

 ### 3. Multiple Files
 Upload multiple files at once:
 ```swift
 var files: [String: Data]? {
     [
         "document1": file1Data,
         "document2": file2Data,
         "photo": imageData
     ]
 }
 ```

 ### 4. Files + Parameters
 Combine files with form parameters:
 ```swift
 var files: [String: Data]? {
     ["file": fileData]
 }

 var parameters: Parameters? {
     ["description": "My file", "public": true]
 }
 ```

 ### 5. Custom Headers
 Add metadata via headers:
 ```swift
 var headers: HTTPHeaders? {
     HTTPHeaders([
         HTTPHeader(name: "X-File-Name", value: fileName),
         HTTPHeader(name: "X-File-Type", value: "image/jpeg")
     ])
 }
 ```

 ### 6. Timeouts
 Upload large files need longer timeouts:
 ```swift
 var timeout: TimeInterval? {
     300.0  // 5 minutes
 }
 ```

 ## Best Practices

 1. **Check File Size**
    ```swift
    let maxSize = 10 * 1024 * 1024 // 10MB
    guard fileData.count <= maxSize else {
        throw UploadError.fileTooLarge
    }
    ```

 2. **Set Appropriate Timeouts**
    - Small files (< 1MB): 30-60 seconds
    - Medium files (1-10MB): 60-120 seconds
    - Large files (> 10MB): 120-300 seconds

 3. **Compress Images**
    ```swift
    if let image = UIImage(data: imageData) {
        imageData = image.jpegData(compressionQuality: 0.7)
    }
    ```

 4. **Handle Network Errors**
    Always catch timeout and connection errors:
    ```swift
    do {
        try await client.execute(uploadRequest)
    } catch let error as NetworkError {
        // Handle timeout, no connection, etc.
    }
    ```

 5. **Use Empty Response When Appropriate**
    If server returns 204 No Content:
    ```swift
    typealias Response = ASCEmptyResponse
    ```

 ## Production Example

 ```swift
 class ImageUploadService {
     private let client: NetworkClient

     init() {
         self.client = NetworkClient(baseURL: "https://api.example.com")
     }

     func uploadProfilePicture(
         userId: String,
         image: UIImage
     ) async throws -> String {
         // Compress image
         guard let imageData = image.jpegData(compressionQuality: 0.7) else {
             throw UploadError.invalidImage
         }

         // Check size
         guard imageData.count <= 5_000_000 else { // 5MB
             throw UploadError.fileTooLarge
         }

         // Create request
         struct Request: NetworkRequest {
             typealias Response = UploadResponse
             let userId: String
             let imageData: Data

             var path: String { "/users/\(userId)/avatar" }
             var method: HTTPMethod { .post }
             var files: [String: Data]? { ["avatar": imageData] }
             var timeout: TimeInterval? { 120.0 }
         }

         let response = try await client.execute(
             Request(userId: userId, imageData: imageData)
         )

         return response.imageUrl
     }
 }
 ```

 ## Testing

 Use httpbin.org for testing uploads:
 - Endpoint: https://httpbin.org/post
 - Returns: Echo of uploaded data
 - Free and public

 ## Run Examples

 ```swift
 Task {
     await runFileUploadExamples()
 }
 ```
 */
