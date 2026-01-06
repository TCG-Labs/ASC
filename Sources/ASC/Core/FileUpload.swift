// FileUpload.swift
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

// File upload types based on Alamofire's upload API.

import Foundation

/// Represents different types of file uploads supported by Alamofire.
///
/// Based on Alamofire's upload API:
/// - `.data(Data)` - Uploading Data directly from memory
/// - `.file(URL)` - Uploading a File from file system (memory-efficient)
/// - `.multipart([MultipartItem])` - Uploading Multipart Form Data with multiple fields
///
/// For more information, see [Alamofire Documentation - Uploading Data to a Server](https://github.com/Alamofire/Alamofire/blob/master/Documentation/Usage.md#uploading-data-to-a-server).
///
/// Example:
/// ```swift
/// // Upload Data
/// let upload: FileUpload = .data(someData)
///
/// // Upload File
/// let fileURL = URL(fileURLWithPath: "/path/to/file.jpg")
/// let upload: FileUpload = .file(fileURL)
///
/// // Upload Multipart Form Data
/// let upload: FileUpload = .multipart([
///     .data("field1", data: data1, fileName: "file1.jpg", mimeType: "image/jpeg"),
///     .file("field2", fileURL: fileURL, fileName: "file2.pdf", mimeType: "application/pdf"),
///     .parameter("name", value: "John")
/// ])
/// ```
public enum FileUpload: Sendable {
    /// Upload Data directly from memory.
    ///
    /// Use for small data that can be loaded into memory.
    /// Corresponds to `AF.upload(data, to:)` API.
    ///
    /// - Parameter data: The data to upload
    case data(Data)

    /// Upload a file from file system (memory-efficient).
    ///
    /// Use for large files to avoid loading entire file into memory.
    /// Corresponds to `AF.upload(fileURL, to:)` API.
    ///
    /// - Parameter fileURL: The URL of the file to upload
    case file(URL)

    /// Upload multipart form data with multiple fields.
    ///
    /// Use when you need to upload multiple files and/or parameters together.
    /// Corresponds to `AF.upload(multipartFormData:to:)` API.
    ///
    /// - Parameter items: Array of multipart items (data, files, parameters)
    case multipart([MultipartItem])
}

/// Represents a single item in multipart form data.
///
/// Each item can be:
/// - Data field (`.data`) - for small data in memory
/// - File field (`.file`) - for files from file system (memory-efficient)
/// - Parameter field (`.parameter`) - for text parameters
public enum MultipartItem: Sendable {
    /// Data field in multipart form.
    ///
    /// - Parameters:
    ///   - fieldName: The name of the form field
    ///   - data: The data to upload
    ///   - fileName: The name of the file
    ///   - mimeType: The MIME type of the data
    case data(fieldName: String, data: Data, fileName: String? = nil, mimeType: String? = nil)

    /// File field in multipart form (memory-efficient).
    ///
    /// - Parameters:
    ///   - fieldName: The name of the form field
    ///   - fileURL: The URL of the file to upload
    ///   - fileName: The name of the file
    ///   - mimeType: The MIME type of the file
    case file(fieldName: String, fileURL: URL, fileName: String? = nil, mimeType: String? = nil)

    /// Parameter field in multipart form.
    ///
    /// - Parameters:
    ///   - fieldName: The name of the form field
    ///   - value: The string value of the parameter
    case parameter(fieldName: String, value: String)
}

