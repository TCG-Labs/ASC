// TestHelpers.swift
// ASC - Alamofire Swift Client
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

// Test helpers and utilities for ASC tests.

import Foundation
@testable import ASC

/// Test helpers for creating mock data and responses.
enum TestHelpers {
    // MARK: - Constants

    /// Default test URL used across test helpers.
    private static let testURL: URL = {
        guard let url = URL(string: "https://api.example.com/test") else {
            fatalError("Failed to create test URL: invalid URL string")
        }
        return url
    }()

    // MARK: - Mock Response Creation

    /// Creates a mock HTTPURLResponse.
    ///
    /// - Parameters:
    ///   - statusCode: HTTP status code (default: 200)
    ///   - headers: HTTP headers (default: nil)
    ///   - url: URL for the response (default: example.com)
    /// - Returns: HTTPURLResponse instance
    static func createMockResponse(
        statusCode: Int = 200,
        headers: [String: String]? = nil,
        url: URL = testURL
    ) -> HTTPURLResponse {
        guard let response = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: headers
        ) else {
            fatalError("Failed to create HTTPURLResponse: invalid parameters")
        }
        return response
    }

    // MARK: - Mock Data Creation

    /// Creates mock JSON data from a dictionary.
    ///
    /// - Parameter json: Dictionary to encode as JSON
    /// - Returns: JSON data
    static func createJSONData(_ json: [String: Any]) -> Data {
        do {
            return try JSONSerialization.data(withJSONObject: json)
        } catch {
            fatalError("Failed to serialize JSON data: \(error)")
        }
    }

    /// Creates mock JSON data from a string.
    ///
    /// - Parameter jsonString: JSON string
    /// - Returns: JSON data
    static func createJSONData(from jsonString: String) -> Data {
        guard let data = jsonString.data(using: .utf8) else {
            fatalError("Failed to convert JSON string to data: invalid UTF-8 encoding")
        }
        return data
    }

    // MARK: - Mock Error Creation

    /// Creates a mock URLError.
    ///
    /// - Parameters:
    ///   - code: URLError code
    ///   - url: URL for the error (default: example.com)
    /// - Returns: URLError instance
    static func createURLError(
        _ code: URLError.Code,
        url: URL = testURL
    ) -> URLError {
        URLError(code, userInfo: [NSURLErrorFailingURLStringErrorKey: url.absoluteString])
    }

    /// Creates a mock AFError with underlying URLError.
    ///
    /// - Parameter urlError: URLError to wrap
    /// - Returns: AFError instance
    static func createAFErrorWithURLError(_ urlError: URLError) -> AFError {
        .sessionTaskFailed(error: urlError)
    }

    /// Creates a mock AFError for validation failure.
    ///
    /// - Parameter statusCode: HTTP status code
    /// - Returns: AFError instance
    static func createValidationError(statusCode: Int) -> AFError {
        .responseValidationFailed(reason: .unacceptableStatusCode(code: statusCode))
    }

    /// Creates a mock AFError for decoding failure.
    ///
    /// - Parameter error: Underlying decoding error
    /// - Returns: AFError instance
    static func createDecodingError(_ error: Error) -> AFError {
        .responseSerializationFailed(reason: .decodingFailed(error: error))
    }

    // MARK: - Mock Codable Types

    /// Simple mock Codable type for testing.
    struct MockCodable: Codable, Equatable {
        let id: Int
        let name: String
    }

    /// Creates mock Codable instance.
    static func createMockCodable() -> MockCodable {
        MockCodable(id: 1, name: "Test")
    }

    /// Creates mock Codable JSON data.
    static func createMockCodableData() -> Data {
        let mockObject = createMockCodable()
        do {
            return try JSONEncoder().encode(mockObject)
        } catch {
            fatalError("Failed to encode mock object: \(error)")
        }
    }
}
