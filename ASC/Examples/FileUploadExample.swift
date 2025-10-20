// FileUploadExample.swift
// ASC - File Upload Examples

import ASC
import Foundation

// MARK: - Models

struct UploadResponse: Codable, Sendable {
    let files: [String: String]?
    let form: [String: String]?
}

struct UserProfile: Codable, Sendable {
    let id: Int
    let name: String
    let avatarUrl: String?
}

// MARK: - Upload Requests

enum UploadAPI {
    struct SimpleUpload: NetworkRequest {
        typealias Response = UploadResponse
        let fileData: Data

        var baseURL: String? { "https://httpbin.org" }
        var path: String { "/post" }
        var method: HTTPMethod { .post }
        var files: [String: Data]? { ["file": fileData] }
    }

    struct Avatar: NetworkRequest {
        typealias Response = UserProfile
        let userId: Int
        let imageData: Data
        let fileName: String

        var path: String { "/users/{userId}/avatar" }
        var method: HTTPMethod { .post }
        var pathParameters: [String: String]? { ["userId": String(userId)] }

        var fileUploads: [String: FileUpload]? {
            ["avatar": .jpeg(data: imageData, fileName: fileName)]
        }

        var timeout: TimeInterval? { 120.0 }
    }

    struct Documents: NetworkRequest {
        typealias Response = UploadResponse
        let documents: [String: Data]
        let description: String

        var baseURL: String? { "https://httpbin.org" }
        var path: String { "/post" }
        var method: HTTPMethod { .post }
        var files: [String: Data]? { documents }
        var parameters: Parameters? {
            ["description": description, "uploadedAt": ISO8601DateFormatter().string(from: Date())]
        }
    }

    struct LargeVideo: NetworkRequest {
        typealias Response = UploadResponse
        let videoURL: URL
        let title: String

        var path: String { "/videos/upload" }
        var method: HTTPMethod { .post }

        var largeFileUploads: [LargeFileUpload]? {
            [LargeFileUpload(
                fileURL: videoURL,
                fieldName: "video",
                fileName: videoURL.lastPathComponent,
                mimeType: "video/mp4"
            )]
        }

        var parameters: Parameters? { ["title": title] }
        var timeout: TimeInterval? { 300.0 }
    }
}

// MARK: - Examples

@MainActor
func runFileUploadExamples() async throws {
    let client = NetworkClient()

    debugPrint("=== ASC File Upload Examples ===\n")

    debugPrint("1. Simple file upload:")
    let testData = Data("Hello from ASC!".utf8)
    let response1 = try await client.execute(UploadAPI.SimpleUpload(fileData: testData))
    debugPrint("   Files uploaded: \(response1.files?.count ?? 0)\n")

    debugPrint("2. Multiple files with metadata:")
    let documents: [String: Data] = [
        "doc1.txt": Data("Document 1".utf8),
        "doc2.txt": Data("Document 2".utf8),
    ]
    let response2 = try await client.execute(
        UploadAPI.Documents(documents: documents, description: "Test docs")
    )
    debugPrint("   Files: \(response2.files?.count ?? 0), Form fields: \(response2.form?.count ?? 0)\n")

    debugPrint("3. Avatar upload with custom MIME type:")
    debugPrint("   Request structure:")
    let avatarRequest = UploadAPI.Avatar(
        userId: 123,
        imageData: Data("image".utf8),
        fileName: "avatar.jpg"
    )
    debugPrint("   - Path: \(avatarRequest.path)")
    debugPrint("   - Method: \(avatarRequest.method.rawValue)")
    debugPrint("   - Timeout: \(avatarRequest.timeout ?? 60)s")
    debugPrint("   - File uploads: \(avatarRequest.fileUploads?.count ?? 0)\n")

    debugPrint("4. Large file upload (file-based encoding):")
    debugPrint("   Use largeFileUploads for files > 10MB")
    debugPrint("   This avoids loading entire file into memory\n")

    debugPrint("=== Upload examples completed ===")
}
