// UploadDataTests.swift
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

import Testing
import Foundation
@testable import ASC

@Suite("UploadData Tests")
struct UploadDataTests {
    @Test("UploadData.data case initialization")
    func testDataCaseInitialization() {
        // Given
        let testData = "test content".data(using: .utf8)!

        // When
        let upload = UploadData.data(testData)

        // Then
        if case let .data(data) = upload {
            #expect(data == testData)
        } else {
            Issue.record("Expected .data case")
        }
    }

    @Test("UploadData.file case initialization")
    func testFileCaseInitialization() throws {
        // Given
        let tempFile = try createTempFile(content: "test file content")

        // When
        let upload = UploadData.file(tempFile)

        // Then
        if case let .file(fileURL) = upload {
            #expect(fileURL == tempFile)
        } else {
            Issue.record("Expected .file case")
        }
    }

    @Test("UploadData.multipart case initialization")
    func testMultipartCaseInitialization() {
        // Given
        let items: [MultipartItem] = [
            .data(fieldName: "field1", data: Data(), fileName: "file1.jpg", mimeType: "image/jpeg"),
            .parameter(fieldName: "name", value: "test")
        ]

        // When
        let upload = UploadData.multipart(items)

        // Then
        if case let .multipart(uploadItems) = upload {
            #expect(uploadItems.count == 2)
        } else {
            Issue.record("Expected .multipart case")
        }
    }

    @Test("MultipartItem.data case initialization")
    func testMultipartItemDataCase() {
        // Given
        let data = "test data".data(using: .utf8)!
        let fieldName = "file"
        let fileName = "test.jpg"
        let mimeType = "image/jpeg"

        // When
        let item = MultipartItem.data(fieldName: fieldName, data: data, fileName: fileName, mimeType: mimeType)

        // Then
        if case let .data(name, itemData, file, mime) = item {
            #expect(name == fieldName)
            #expect(itemData == data)
            #expect(file == fileName)
            #expect(mime == mimeType)
        } else {
            Issue.record("Expected .data case")
        }
    }

    @Test("MultipartItem.file case initialization")
    func testMultipartItemFileCase() throws {
        // Given
        let fileURL = try createTempFile(content: "test")
        let fieldName = "document"
        let fileName = "doc.pdf"
        let mimeType = "application/pdf"

        // When
        let item = MultipartItem.file(fieldName: fieldName, fileURL: fileURL, fileName: fileName, mimeType: mimeType)

        // Then
        if case let .file(name, url, file, mime) = item {
            #expect(name == fieldName)
            #expect(url == fileURL)
            #expect(file == fileName)
            #expect(mime == mimeType)
        } else {
            Issue.record("Expected .file case")
        }
    }

    @Test("MultipartItem.parameter case initialization")
    func testMultipartItemParameterCase() {
        // Given
        let fieldName = "description"
        let value = "test description"

        // When
        let item = MultipartItem.parameter(fieldName: fieldName, value: value)

        // Then
        if case let .parameter(name, paramValue) = item {
            #expect(name == fieldName)
            #expect(paramValue == value)
        } else {
            Issue.record("Expected .parameter case")
        }
    }

    // MARK: - Helper Methods

    private func createTempFile(content: String) throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = UUID().uuidString
        let fileURL = tempDir.appendingPathComponent(fileName)

        try content.write(to: fileURL, atomically: true, encoding: .utf8)

        return fileURL
    }
}

