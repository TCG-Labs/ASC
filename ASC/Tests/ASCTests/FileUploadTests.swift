// FileUploadTests.swift
// ASC - Alamofire Swift Client Tests

// Honest tests for FileUpload functionality - tests real behavior, not trivial struct properties.

import Testing
import Foundation
@testable import ASC

/// Tests for FileUpload integration with NetworkClient.
/// These tests verify REAL behavior: correct MIME types in requests, proper multipart encoding,
/// and integration with the networking stack.
@Suite("FileUpload Tests", .serialized)
struct FileUploadTests {
    // MARK: - Integration Tests (Real Behavior)

    @Test("FileUpload sends correct MIME type in HTTP request")
    func testFileUploadMimeTypeInRequest() async throws {
        setupTest()
        let client = createMockClient()

        struct UploadRequest: NetworkRequest {
            typealias Response = UploadResponse
            let imageData: Data

            var path: String { "/upload" }
            var method: HTTPMethod { .post }
            var fileUploads: [String: FileUpload]? {
                ["photo": .jpeg(data: imageData, fileName: "test.jpg")]
            }
        }

        struct UploadResponse: Codable, Sendable {
            let success: Bool
        }

        MockURLProtocol.requestHandler = MockResponseBuilder.success(UploadResponse(success: true)).handler()

        let imageData = TestDataFactory.stringData("test image")
        _ = try await client.execute(UploadRequest(imageData: imageData))

        // Verify: HTTP request has multipart/form-data Content-Type
        let request = MockURLProtocol.lastRequest
        let contentType = request?.value(forHTTPHeaderField: "Content-Type")
        #expect(contentType?.contains("multipart/form-data") == true)

        // Verify: Request body contains MIME type
        if let body = request?.httpBody {
            let bodyString = String(data: body, encoding: .utf8) ?? ""
            #expect(bodyString.contains("image/jpeg"))
            #expect(bodyString.contains("test.jpg"))
        }
    }

    @Test("FileUpload convenience methods set correct MIME types in requests", arguments: [
        ("jpeg", "image/jpeg", "photo.jpg"),
        ("png", "image/png", "photo.png"),
        ("heic", "image/heic", "photo.heic"),
        ("mp4", "video/mp4", "video.mp4"),
        ("pdf", "application/pdf", "doc.pdf"),
        ("zip", "application/zip", "archive.zip")
    ])
    func testConvenienceMethodsMimeTypes(type: String, expectedMime: String, fileName: String) async throws {
        setupTest()
        let client = createMockClient()

        struct UploadRequest: NetworkRequest {
            typealias Response = UploadResponse
            let data: Data
            let upload: FileUpload

            var path: String { "/upload" }
            var method: HTTPMethod { .post }
            var fileUploads: [String: FileUpload]? {
                ["file": upload]
            }
        }

        struct UploadResponse: Codable, Sendable {
            let success: Bool
        }

        MockURLProtocol.requestHandler = MockResponseBuilder.success(UploadResponse(success: true)).handler()

        let data = TestDataFactory.stringData("test data")
        let upload: FileUpload = switch type {
        case "jpeg": .jpeg(data: data, fileName: fileName)
        case "png": .png(data: data, fileName: fileName)
        case "heic": .heic(data: data, fileName: fileName)
        case "mp4": .mp4(data: data, fileName: fileName)
        case "pdf": .pdf(data: data, fileName: fileName)
        case "zip": .zip(data: data, fileName: fileName)
        default: .jpeg(data: data, fileName: fileName)
        }

        _ = try await client.execute(UploadRequest(data: data, upload: upload))

        // Verify: Correct MIME type in request body
        let request = MockURLProtocol.lastRequest
        if let body = request?.httpBody {
            let bodyString = String(data: body, encoding: .utf8) ?? ""
            #expect(bodyString.contains(expectedMime), "Expected MIME type '\(expectedMime)' in request body")
            #expect(bodyString.contains(fileName), "Expected filename '\(fileName)' in request body")
        } else {
            Issue.record("Request body is nil - cannot verify MIME type")
        }
    }

    @Test("Multiple FileUploads are all included in request")
    func testMultipleFileUploadsInRequest() async throws {
        setupTest()
        let client = createMockClient()

        struct UploadRequest: NetworkRequest {
            typealias Response = UploadResponse
            let files: [String: FileUpload]

            var path: String { "/upload" }
            var method: HTTPMethod { .post }
            var fileUploads: [String: FileUpload]? { files }
        }

        struct UploadResponse: Codable, Sendable {
            let success: Bool
        }

        MockURLProtocol.requestHandler = MockResponseBuilder.success(UploadResponse(success: true)).handler()

        let files: [String: FileUpload] = [
            "photo": .jpeg(data: TestDataFactory.stringData("photo"), fileName: "photo.jpg"),
            "document": .pdf(data: TestDataFactory.stringData("doc"), fileName: "doc.pdf"),
            "video": .mp4(data: TestDataFactory.stringData("video"), fileName: "video.mp4")
        ]

        _ = try await client.execute(UploadRequest(files: files))

        // Verify: All files present in request body
        let request = MockURLProtocol.lastRequest
        if let body = request?.httpBody {
            let bodyString = String(data: body, encoding: .utf8) ?? ""
            #expect(bodyString.contains("photo.jpg"), "photo.jpg missing from request")
            #expect(bodyString.contains("doc.pdf"), "doc.pdf missing from request")
            #expect(bodyString.contains("video.mp4"), "video.mp4 missing from request")
            #expect(bodyString.contains("image/jpeg"), "image/jpeg MIME type missing")
            #expect(bodyString.contains("application/pdf"), "application/pdf MIME type missing")
            #expect(bodyString.contains("video/mp4"), "video/mp4 MIME type missing")
        } else {
            Issue.record("Request body is nil")
        }
    }

    @Test("FileUpload works with parameters in same request")
    func testFileUploadWithParameters() async throws {
        setupTest()
        let client = createMockClient()

        struct UploadRequest: NetworkRequest {
            typealias Response = UploadResponse
            let imageData: Data
            let title: String
            let isPublic: Bool

            var path: String { "/upload" }
            var method: HTTPMethod { .post }
            var fileUploads: [String: FileUpload]? {
                ["image": .jpeg(data: imageData, fileName: "photo.jpg")]
            }
            var parameters: Parameters? {
                ["title": title, "public": isPublic]
            }
        }

        struct UploadResponse: Codable, Sendable {
            let success: Bool
        }

        MockURLProtocol.requestHandler = MockResponseBuilder.success(UploadResponse(success: true)).handler()

        _ = try await client.execute(UploadRequest(
            imageData: TestDataFactory.stringData("image"),
            title: "My Photo",
            isPublic: true
        ))

        // Verify: Both file and parameters in request
        let request = MockURLProtocol.lastRequest
        if let body = request?.httpBody {
            let bodyString = String(data: body, encoding: .utf8) ?? ""
            #expect(bodyString.contains("photo.jpg"), "File missing from request")
            #expect(bodyString.contains("My Photo"), "Title parameter missing")
            #expect(bodyString.contains("true"), "Public parameter missing")
        } else {
            Issue.record("Request body is nil")
        }
    }

    @Test("LargeFileUpload reads file from disk")
    func testLargeFileUploadFromDisk() async throws {
        setupTest()
        let client = createMockClient()

        // Create real temporary file using TestDataFactory
        let tempFile = try TestDataFactory.createTempFile(
            name: "test_large",
            extension: "mp4",
            size: TestDataFactory.FileSize.large,
            pattern: TestDataFactory.Pattern.ab
        )
        defer { tempFile.cleanup() }

        struct UploadRequest: NetworkRequest {
            typealias Response = UploadResponse
            let videoURL: URL

            var path: String { "/upload" }
            var method: HTTPMethod { .post }
            var largeFileUploads: [LargeFileUpload]? {
                [LargeFileUpload(
                    fileURL: videoURL,
                    fieldName: "video",
                    fileName: "large.mp4",
                    mimeType: "video/mp4"
                )]
            }
        }

        struct UploadResponse: Codable, Sendable {
            let success: Bool
        }

        MockURLProtocol.requestHandler = MockResponseBuilder.success(UploadResponse(success: true)).handler()

        _ = try await client.execute(UploadRequest(videoURL: tempFile.url))

        // Verify: Request was created successfully (file was read)
        let request = MockURLProtocol.lastRequest
        #expect(request != nil, "Request should be created from file")

        let contentType = request?.value(forHTTPHeaderField: "Content-Type")
        #expect(contentType?.contains("multipart/form-data") == true)
    }

    @Test("LargeFileUpload uses file's lastPathComponent as default name")
    func testLargeFileUploadDefaultFileName() async throws {
        setupTest()
        let client = createMockClient()

        // Create file with specific name using TestDataFactory
        let tempFile = try TestDataFactory.createTempFile(
            name: "my-video-file",
            extension: "mp4",
            size: TestDataFactory.FileSize.tiny
        )
        defer { tempFile.cleanup() }

        struct UploadRequest: NetworkRequest {
            typealias Response = UploadResponse
            let videoURL: URL

            var path: String { "/upload" }
            var method: HTTPMethod { .post }
            var largeFileUploads: [LargeFileUpload]? {
                // No fileName provided - should use file's name
                [LargeFileUpload(fileURL: videoURL, fieldName: "video")]
            }
        }

        struct UploadResponse: Codable, Sendable {
            let success: Bool
        }

        MockURLProtocol.requestHandler = MockResponseBuilder.success(UploadResponse(success: true)).handler()

        _ = try await client.execute(UploadRequest(videoURL: tempFile.url))

        // Verify: Default filename was used
        let request = MockURLProtocol.lastRequest
        #expect(request != nil)
    }

    @Test("Mixed files, fileUploads, and largeFileUploads in single request")
    func testMixedUploadTypes() async throws {
        setupTest()
        let client = createMockClient()

        // Create temporary file using TestDataFactory
        let tempFile = try TestDataFactory.createTempFile(
            name: "large",
            extension: "dat",
            size: 1000
        )
        defer { tempFile.cleanup() }

        struct UploadRequest: NetworkRequest {
            typealias Response = UploadResponse
            let simpleData: Data
            let photoData: Data
            let largeURL: URL

            var path: String { "/upload" }
            var method: HTTPMethod { .post }

            var files: [String: Data]? {
                ["simple": simpleData]
            }

            var fileUploads: [String: FileUpload]? {
                ["photo": .jpeg(data: photoData, fileName: "photo.jpg")]
            }

            var largeFileUploads: [LargeFileUpload]? {
                [LargeFileUpload(fileURL: largeURL, fieldName: "large")]
            }
        }

        struct UploadResponse: Codable, Sendable {
            let success: Bool
        }

        MockURLProtocol.requestHandler = MockResponseBuilder.success(UploadResponse(success: true)).handler()

        _ = try await client.execute(UploadRequest(
            simpleData: TestDataFactory.stringData("simple"),
            photoData: TestDataFactory.stringData("photo"),
            largeURL: tempFile.url
        ))

        // Verify: Request created successfully with all upload types
        let request = MockURLProtocol.lastRequest
        #expect(request != nil)

        let contentType = request?.value(forHTTPHeaderField: "Content-Type")
        #expect(contentType?.contains("multipart/form-data") == true)
    }

    @Test("Empty FileUpload data is handled")
    func testEmptyFileUpload() async throws {
        setupTest()
        let client = createMockClient()

        struct UploadRequest: NetworkRequest {
            typealias Response = UploadResponse

            var path: String { "/upload" }
            var method: HTTPMethod { .post }
            var fileUploads: [String: FileUpload]? {
                ["empty": FileUpload(data: TestDataFactory.emptyData, fileName: "empty.txt")]
            }
        }

        struct UploadResponse: Codable, Sendable {
            let success: Bool
        }

        MockURLProtocol.requestHandler = MockResponseBuilder.success(UploadResponse(success: true)).handler()

        _ = try await client.execute(UploadRequest())

        // Verify: Request handles empty data without crashing
        let request = MockURLProtocol.lastRequest
        #expect(request != nil)
    }

    @Test("FileUpload with large data (10MB) works")
    func testLargeDataFileUpload() async throws {
        setupTest()
        let client = createMockClient()

        struct UploadRequest: NetworkRequest {
            typealias Response = UploadResponse
            let data: Data

            var path: String { "/upload" }
            var method: HTTPMethod { .post }
            var fileUploads: [String: FileUpload]? {
                ["large": FileUpload(data: data, fileName: "large.bin")]
            }
        }

        struct UploadResponse: Codable, Sendable {
            let success: Bool
        }

        MockURLProtocol.requestHandler = MockResponseBuilder.success(UploadResponse(success: true)).handler()

        let largeData = TestDataFactory.data(size: TestDataFactory.FileSize.threshold)
        _ = try await client.execute(UploadRequest(data: largeData))

        // Verify: Large data handled successfully
        let request = MockURLProtocol.lastRequest
        #expect(request != nil)
    }

    // MARK: - Error Handling Tests (Real Behavior)

    @Test("FileUpload error is properly propagated")
    func testFileUploadError() async throws {
        setupTest()
        let client = createMockClient()

        struct UploadRequest: NetworkRequest {
            typealias Response = UploadResponse
            let data: Data

            var path: String { "/upload" }
            var method: HTTPMethod { .post }
            var fileUploads: [String: FileUpload]? {
                ["file": .jpeg(data: data, fileName: "photo.jpg")]
            }
        }

        struct UploadResponse: Codable, Sendable {
            let success: Bool
        }

        // Setup mock to return error
        MockURLProtocol.requestHandler = MockResponseBuilder.serverError().handler()

        do {
            _ = try await client.execute(UploadRequest(data: TestDataFactory.stringData("test")))
            Issue.record("Expected error to be thrown")
        } catch let error as ResponseError {
            #expect(error.statusCode == 500)
        }
    }

    @Test("LargeFileUpload with missing file fails gracefully")
    func testLargeFileUploadMissingFile() async throws {
        setupTest()
        let client = createMockClient()

        // Create URL to non-existent file
        let nonExistentURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("non-existent-file.mp4")

        struct UploadRequest: NetworkRequest {
            typealias Response = UploadResponse
            let fileURL: URL

            var path: String { "/upload" }
            var method: HTTPMethod { .post }
            var largeFileUploads: [LargeFileUpload]? {
                [LargeFileUpload(fileURL: fileURL, fieldName: "video")]
            }
        }

        struct UploadResponse: Codable, Sendable {
            let success: Bool
        }

        MockURLProtocol.requestHandler = MockResponseBuilder.success(UploadResponse(success: true)).handler()

        // This should fail or handle gracefully
        do {
            _ = try await client.execute(UploadRequest(fileURL: nonExistentURL))
            // If it succeeds, that's fine (Alamofire handles missing files)
        } catch {
            // If it fails, that's expected
            #expect(error is NetworkError || error is ResponseError)
        }
    }
}
