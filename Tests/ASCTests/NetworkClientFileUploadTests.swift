// NetworkClientFileUploadTests.swift
// ASC - Alamofire Swift Client Tests
//
//  Copyright (c) 2025 TCG Labs
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation
import Testing
@testable import ASC

// MARK: - Mock Upload Requests

struct MockDataUploadRequest: Endpoint {
    typealias Response = MockResponse
    typealias Request = Empty

    let uploadDataValue: Data

    var path: String { "/upload" }
    var method: HTTPMethod { .post }
    var uploadData: UploadData? {
        .data(uploadDataValue)
    }
}

struct MockFileUploadRequest: Endpoint {
    typealias Response = MockResponse
    typealias Request = Empty

    let fileURL: URL

    var path: String { "/upload" }
    var method: HTTPMethod { .post }
    var uploadData: UploadData? {
        .file(fileURL)
    }
}

struct MockMultipartUploadRequest: Endpoint {
    typealias Response = MockResponse
    typealias Request = Empty

    let items: [MultipartItem]

    var path: String { "/upload" }
    var method: HTTPMethod { .post }
    var uploadData: UploadData? {
        .multipart(items)
    }
}

struct MockMultipartWithParametersRequest: Endpoint {
    typealias Response = MockResponse

    struct Params: Encodable, Sendable {
        let description: String
    }
    typealias Request = Params

    let items: [MultipartItem]
    let description: String

    var path: String { "/upload" }
    var method: HTTPMethod { .post }
    var parameters: Params? {
        Params(description: description)
    }
    var uploadData: UploadData? {
        .multipart(items)
    }
}

@Suite("NetworkClient File Upload Tests", .serialized)
struct NetworkClientFileUploadTests {
    // MARK: - Data Upload Tests

    @Test("Upload data using .data case")
    func testUploadData() async throws {
        // Given
        MockURLProtocol.reset()
        defer { MockURLProtocol.reset() }

        let uploadData = "test content".data(using: .utf8)!
        let responseData = try JSONEncoder().encode(MockResponse(id: 1, name: "Uploaded"))
        MockURLProtocol.setSuccessResponse(data: responseData)

        let request = MockDataUploadRequest(uploadDataValue: uploadData)
        let client = NetworkClient(configuration: createTestConfiguration())

        // When
        let response = try await client.execute(request)

        // Then
        #expect(response.id == 1)
        #expect(response.name == "Uploaded")
    }

    @Test("Upload file using .file case")
    func testUploadFile() async throws {
        // Given
        MockURLProtocol.reset()
        defer { MockURLProtocol.reset() }

        let tempFile = try createTempFile(content: "file content")
        defer { try? FileManager.default.removeItem(at: tempFile) }

        let responseData = try JSONEncoder().encode(MockResponse(id: 2, name: "File uploaded"))
        MockURLProtocol.setSuccessResponse(data: responseData)

        let request = MockFileUploadRequest(fileURL: tempFile)
        let client = NetworkClient(configuration: createTestConfiguration())

        // When
        let response = try await client.execute(request)

        // Then
        #expect(response.id == 2)
        #expect(response.name == "File uploaded")
    }

    @Test("Upload file throws error when file does not exist")
    func testUploadFileThrowsErrorWhenFileDoesNotExist() async throws {
        // Given
        MockURLProtocol.reset()
        defer { MockURLProtocol.reset() }

        let nonExistentFile = URL(fileURLWithPath: "/nonexistent/file.txt")
        let request = MockFileUploadRequest(fileURL: nonExistentFile)
        let client = NetworkClient(configuration: createTestConfiguration())

        // When & Then
        await #expect(throws: ASCError.self) {
            try await client.execute(request)
        }
    }

    // MARK: - Multipart Upload Tests

    @Test("Upload multipart with data items")
    func testUploadMultipartWithDataItems() async throws {
        // Given
        MockURLProtocol.reset()
        defer { MockURLProtocol.reset() }

        let data1 = "file1 content".data(using: .utf8)!
        let data2 = "file2 content".data(using: .utf8)!

        let items: [MultipartItem] = [
            .data(fieldName: "file1", data: data1, fileName: "file1.txt", mimeType: "text/plain"),
            .data(fieldName: "file2", data: data2, fileName: "file2.txt", mimeType: "text/plain")
        ]

        let responseData = try JSONEncoder().encode(MockResponse(id: 3, name: "Multipart uploaded"))
        MockURLProtocol.setSuccessResponse(data: responseData)

        let request = MockMultipartUploadRequest(items: items)
        let client = NetworkClient(configuration: createTestConfiguration())

        // When
        let response = try await client.execute(request)

        // Then
        #expect(response.id == 3)
        #expect(response.name == "Multipart uploaded")
    }

    @Test("Upload multipart with file items")
    func testUploadMultipartWithFileItems() async throws {
        // Given
        MockURLProtocol.reset()
        defer { MockURLProtocol.reset() }

        let tempFile1 = try createTempFile(content: "file1 content")
        let tempFile2 = try createTempFile(content: "file2 content")
        defer {
            try? FileManager.default.removeItem(at: tempFile1)
            try? FileManager.default.removeItem(at: tempFile2)
        }

        let items: [MultipartItem] = [
            .file(fieldName: "document1", fileURL: tempFile1, fileName: "doc1.pdf", mimeType: "application/pdf"),
            .file(fieldName: "document2", fileURL: tempFile2, fileName: "doc2.pdf", mimeType: "application/pdf")
        ]

        let responseData = try JSONEncoder().encode(MockResponse(id: 4, name: "Files uploaded"))
        MockURLProtocol.setSuccessResponse(data: responseData)

        let request = MockMultipartUploadRequest(items: items)
        let client = NetworkClient(configuration: createTestConfiguration())

        // When
        let response = try await client.execute(request)

        // Then
        #expect(response.id == 4)
        #expect(response.name == "Files uploaded")
    }

    @Test("Upload multipart with mixed items")
    func testUploadMultipartWithMixedItems() async throws {
        // Given
        MockURLProtocol.reset()
        defer { MockURLProtocol.reset() }

        let data = "image data".data(using: .utf8)!
        let tempFile = try createTempFile(content: "document content")
        defer { try? FileManager.default.removeItem(at: tempFile) }

        let items: [MultipartItem] = [
            .data(fieldName: "image", data: data, fileName: "image.jpg", mimeType: "image/jpeg"),
            .file(fieldName: "document", fileURL: tempFile, fileName: "doc.pdf", mimeType: "application/pdf"),
            .parameter(fieldName: "description", value: "Test upload")
        ]

        let responseData = try JSONEncoder().encode(MockResponse(id: 5, name: "Mixed upload"))
        MockURLProtocol.setSuccessResponse(data: responseData)

        let request = MockMultipartUploadRequest(items: items)
        let client = NetworkClient(configuration: createTestConfiguration())

        // When
        let response = try await client.execute(request)

        // Then
        #expect(response.id == 5)
        #expect(response.name == "Mixed upload")
    }

    @Test("Upload multipart with parameters")
    func testUploadMultipartWithParameters() async throws {
        // Given
        MockURLProtocol.reset()
        defer { MockURLProtocol.reset() }

        let data = "file content".data(using: .utf8)!
        let items: [MultipartItem] = [
            .data(fieldName: "file", data: data, fileName: "file.txt", mimeType: "text/plain")
        ]

        let responseData = try JSONEncoder().encode(MockResponse(id: 6, name: "Upload with params"))
        MockURLProtocol.setSuccessResponse(data: responseData)

        let request = MockMultipartWithParametersRequest(items: items, description: "Test description")
        let client = NetworkClient(configuration: createTestConfiguration())

        // When
        let response = try await client.execute(request)

        // Then
        #expect(response.id == 6)
        #expect(response.name == "Upload with params")
    }

    @Test("Upload multipart throws error when file does not exist")
    func testUploadMultipartThrowsErrorWhenFileDoesNotExist() async throws {
        // Given
        MockURLProtocol.reset()
        defer { MockURLProtocol.reset() }

        let nonExistentFile = URL(fileURLWithPath: "/nonexistent/file.txt")
        let items: [MultipartItem] = [
            .file(fieldName: "file", fileURL: nonExistentFile, fileName: "file.txt", mimeType: "text/plain")
        ]

        let request = MockMultipartUploadRequest(items: items)
        let client = NetworkClient(configuration: createTestConfiguration())

        // When & Then
        await #expect(throws: ASCError.self) {
            try await client.execute(request)
        }
    }

    // MARK: - Progress Tracking Tests

//    @Test("Execute with progress returns progress updates")
//    func testExecuteWithProgress() async throws {
//        // Given
//        MockURLProtocol.reset()
//        defer { MockURLProtocol.reset() }
//
//        let uploadData = "test content".data(using: .utf8)!
//        let responseData = try JSONEncoder().encode(MockResponse(id: 7, name: "Progress test"))
//        MockURLProtocol.setSuccessResponse(data: responseData)
//
//        let request = MockDataUploadRequest(uploadDataValue: uploadData)
//        let client = NetworkClient(configuration: createTestConfiguration())
//
//        // When
//        var progressCount = 0
//        var finalResponse: MockResponse?
//
//        for try await item in client.executeWithProgress(request) {
//            switch item {
//            case .progress:
//                progressCount += 1
//            case let .response(response):
//                finalResponse = response
//            }
//        }
//
//        // Then
//        #expect(finalResponse != nil)
//        #expect(finalResponse?.id == 7)
//        // Progress updates may or may not be received depending on upload speed
//        // Just verify we got the final response
//    }
//
//    @Test("Execute with progress throws error when fileUpload is not set")
//    func testExecuteWithProgressThrowsErrorWhenFileUploadNotSet() async throws {
//        // Given
//        MockURLProtocol.reset()
//        defer { MockURLProtocol.reset() }
//
//        let request = MockGetRequest()
//        let client = NetworkClient(configuration: createTestConfiguration())
//
//        // When & Then
//        var errorThrown = false
//        do {
//            for try await _ in client.executeWithProgress(request) {
//                // Should not reach here
//            }
//        } catch {
//            errorThrown = true
//            if let ascError = error as? ASCError,
//               case .invalidFormat = ascError {
//                // Expected error
//            } else {
//                Issue.record("Expected ASCError.invalidFormat, got \(error)")
//            }
//        }
//
//        #expect(errorThrown)
//    }

    // MARK: - Edge Cases Tests

    @Test("Upload empty data")
    func testUploadEmptyData() async throws {
        // Given
        MockURLProtocol.reset()
        defer { MockURLProtocol.reset() }

        let emptyData = Data()
        let responseData = try JSONEncoder().encode(MockResponse(id: 8, name: "Empty uploaded"))
        MockURLProtocol.setSuccessResponse(data: responseData)

        let request = MockDataUploadRequest(uploadData: emptyData)
        let client = NetworkClient(configuration: createTestConfiguration())

        // When
        let response = try await client.execute(request)

        // Then
        #expect(response.id == 8)
    }

    @Test("Upload multipart with empty array")
    func testUploadMultipartWithEmptyArray() async throws {
        // Given
        MockURLProtocol.reset()
        defer { MockURLProtocol.reset() }

        let items: [MultipartItem] = []
        let responseData = try JSONEncoder().encode(MockResponse(id: 9, name: "Empty multipart"))
        MockURLProtocol.setSuccessResponse(data: responseData)

        let request = MockMultipartUploadRequest(items: items)
        let client = NetworkClient(configuration: createTestConfiguration())

        // When
        let response = try await client.execute(request)

        // Then
        #expect(response.id == 9)
    }

    // MARK: - Validation Tests

    @Test("Upload request validates response using request.validate")
    func testUploadRequestValidatesResponse() async throws {
        // Given
        MockURLProtocol.reset()
        defer { MockURLProtocol.reset() }

        let uploadData = "test content".data(using: .utf8)!
        let responseData = try JSONEncoder().encode(MockResponse(id: 1, name: "Test"))
        MockURLProtocol.setSuccessResponse(data: responseData)

        struct ValidatedUploadRequest: Endpoint {
            typealias Response = MockResponse
            typealias Request = Empty

            let uploadDataValue: Data
            let shouldFailValidation: Bool

            var path: String { "/upload" }
            var method: HTTPMethod { .post }
            var uploadData: UploadData? {
                .data(uploadDataValue)
            }

            func validate(response: MockResponse) throws {
                if shouldFailValidation {
                    throw ASCError.validationFailed("Custom validation failed")
                }
            }
        }

        // When & Then - успешная валидация
        let request1 = ValidatedUploadRequest(uploadDataValue: uploadData, shouldFailValidation: false)
        let client = NetworkClient(configuration: createTestConfiguration())
        let response1 = try await client.execute(request1)
        #expect(response1.id == 1)

        // When & Then - неудачная валидация
        let request2 = ValidatedUploadRequest(uploadDataValue: uploadData, shouldFailValidation: true)
        await #expect(throws: ASCError.self) {
            try await client.execute(request2)
        }
    }

    @Test("Upload request applies automatic status code validation")
    func testUploadRequestAppliesAutomaticValidation() async throws {
        // Given
        MockURLProtocol.reset()
        defer { MockURLProtocol.reset() }

        let uploadData = "test content".data(using: .utf8)!
        let responseData = try JSONEncoder().encode(MockResponse(id: 1, name: "Test"))

        // Настройка с автоматической валидацией и допустимыми статус-кодами
        let validationOptions = ValidationOptions(
            isEnabled: true,
            acceptableStatusCodes: 200..<300
        )
        let config = NetworkClientConfiguration(
            baseURL: "https://api.example.com",
            sessionType: .custom(createMockURLSessionConfiguration()),
            connectivityCheckEnabled: false,
            validation: validationOptions
        )

        // Когда статус-код валидный (200)
        MockURLProtocol.setSuccessResponse(data: responseData, statusCode: 200)
        let request1 = MockDataUploadRequest(uploadData: uploadData)
        let client1 = NetworkClient(configuration: config)
        let response1 = try await client1.execute(request1)
        #expect(response1.id == 1)

        // Когда статус-код невалидный (400)
        MockURLProtocol.setSuccessResponse(data: responseData, statusCode: 400)
        let request2 = MockDataUploadRequest(uploadData: uploadData)
        let client2 = NetworkClient(configuration: config)
        await #expect(throws: ASCError.self) {
            try await client2.execute(request2)
        }
    }

    // MARK: - Helper Methods

    private func createTestConfiguration() -> NetworkClientConfiguration {
        NetworkClientConfiguration(
            baseURL: "https://api.example.com",
            sessionType: .custom(createMockURLSessionConfiguration()),
            connectivityCheckEnabled: false
        )
    }

    private func createMockURLSessionConfiguration() -> URLSessionConfiguration {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return config
    }

    private func createTempFile(content: String) throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = UUID().uuidString
        let fileURL = tempDir.appendingPathComponent(fileName)

        try content.write(to: fileURL, atomically: true, encoding: .utf8)

        return fileURL
    }
}

