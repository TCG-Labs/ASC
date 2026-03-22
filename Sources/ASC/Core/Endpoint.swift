// Endpoint.swift
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

// Core protocol defining network request configuration.

import Alamofire
import Foundation

/// Protocol defining a network request configuration.
///
/// Implement this protocol to create type-safe network requests.
/// The protocol uses associated types to ensure compile-time type safety
/// for request and response data.
///
/// Example:
/// ```swift
/// struct GetUserRequest: Endpoint {
///     typealias Response = User
///     typealias Request = Empty
///
///     let userId: String
///
///     var path: String { "/users/\(userId)" }
///     var method: HTTPMethod { .get }
/// }
/// ```
public protocol Endpoint: Sendable {
    /// The request type conforming to Encodable.
    ///
    /// Use `Empty` for requests without parameters (GET, DELETE, etc.).
    /// For requests with parameters, define a custom Encodable struct.
    ///
    /// Example:
    /// ```swift
    /// struct CreateUserRequest: Endpoint {
    ///     struct UserData: Encodable, Sendable {
    ///         let email: String
    ///         let name: String
    ///     }
    ///     typealias Request = UserData
    /// }
    /// ```
    associatedtype Request: Encodable & Sendable

    /// The expected response type conforming to Decodable.
    ///
    /// Use `Empty` for requests that don't return a response body (204 No Content, etc.).
    /// For requests with response data, define a custom Decodable struct.
    ///
    /// Example:
    /// ```swift
    /// struct DeleteUserRequest: Endpoint {
    ///     typealias Response = Empty
    ///     typealias Request = Empty
    ///
    ///     let userId: String
    ///     var path: String { "/users/\(userId)" }
    ///     var method: HTTPMethod { .delete }
    /// }
    /// ```
    associatedtype Response: Decodable & Sendable

    /// The base URL for the request.
    ///
    /// If not specified, the client's default base URL will be used.
    var baseURL: String? { get }

    /// The path component of the URL.
    ///
    /// This will be appended to the base URL.
    /// Example: "/users/123" or "/api/v1/posts"
    var path: String { get }

    /// HTTP method for the request.
    var method: HTTPMethod { get }

    /// HTTP headers to include in the request.
    ///
    /// These headers will be merged with default headers from interceptors.
    /// Request-specific headers take precedence over defaults.
    var headers: HTTPHeaders? { get }

    /// Request parameters (type-safe Encodable).
    ///
    /// Parameters are automatically encoded based on HTTP method:
    /// - GET/HEAD/DELETE: URL-encoded as query string
    /// - POST/PUT/PATCH: JSON-encoded in request body
    ///
    /// Example:
    /// ```swift
    /// struct SearchRequest: Endpoint {
    ///     struct Query: Encodable, Sendable {
    ///         let q: String
    ///         let limit: Int
    ///     }
    ///     typealias Request = Query
    ///
    ///     var parameters: Query? {
    ///         Query(q: "swift", limit: 10)
    ///     }
    /// }
    /// ```
    var parameters: Request? { get }

    /// Request timeout interval in seconds.
    ///
    /// If not specified, the client's default timeout will be used.
    var timeout: TimeInterval? { get }

    /// Cache policy for this request.
    ///
    /// If not specified, the client's default cache policy will be used.
    var cachePolicy: URLRequest.CachePolicy? { get }

    /// Enables automatic authorization header injection.
    ///
    /// When set to `true`, the request interceptor will add an `Authorization` header
    /// based on the token storage configuration. Default is `false`.
    ///
    /// Example:
    /// ```swift
    /// struct GetProfileRequest: Endpoint {
    ///     typealias Response = UserProfile
    ///
    ///     var enableAuthorization: Bool { true }  // Adds Authorization header
    /// }
    /// ```
    var enableAuthorization: Bool { get }

    /// File upload configuration for this request.
    ///
    /// Supports three types of uploads based on Alamofire's API:
    /// - `.data(Data)` - Upload Data directly from memory
    /// - `.file(URL)` - Upload a File from file system (memory-efficient)
    /// - `.multipart([MultipartItem])` - Upload Multipart Form Data with multiple fields
    ///
    /// When this property is set, the request will automatically use the appropriate
    /// Alamofire upload method (`AF.upload(data:to:)`, `AF.upload(fileURL:to:)`, or `AF.upload(multipartFormData:to:)`).
    ///
    /// For more information, see [Alamofire Documentation - Uploading Data to a Server](https://github.com/Alamofire/Alamofire/blob/master/Documentation/Usage.md#uploading-data-to-a-server).
    ///
    /// Example:
    /// ```swift
    /// struct UploadImageRequest: Endpoint {
    ///     typealias Response = UploadResponse
    ///     typealias Request = Empty
    ///
    ///     let imageData: Data
    ///
    ///     var path: String { "/upload" }
    ///     var method: HTTPMethod { .post }
    ///     var uploadData: UploadData? {
    ///         .data(imageData)
    ///     }
    /// }
    ///
    /// struct UploadLargeFileRequest: Endpoint {
    ///     typealias Response = UploadResponse
    ///     typealias Request = Empty
    ///
    ///     let fileURL: URL
    ///
    ///     var path: String { "/upload" }
    ///     var method: HTTPMethod { .post }
    ///     var uploadData: UploadData? {
    ///         .file(fileURL)
    ///     }
    /// }
    ///
    /// struct UploadMultipleFilesRequest: Endpoint {
    ///     typealias Response = UploadResponse
    ///     typealias Request = Empty
    ///
    ///     let imageData: Data
    ///     let documentURL: URL
    ///     let description: String
    ///
    ///     var path: String { "/upload" }
    ///     var method: HTTPMethod { .post }
    ///     var uploadData: UploadData? {
    ///         .multipart([
    ///             .data("image", data: imageData, fileName: "image.jpg", mimeType: "image/jpeg"),
    ///             .file("document", fileURL: documentURL, fileName: "doc.pdf", mimeType: "application/pdf"),
    ///             .parameter("description", value: description)
    ///         ])
    ///     }
    /// }
    /// ```
    var uploadData: UploadData? { get }

    /// Validates the response after successful decoding.
    ///
    /// Override this method to implement custom business logic validation.
    /// This is called after the response is successfully decoded but before
    /// it's returned to the caller.
    ///
    /// Common use cases:
    /// - Check for "success": false in API response
    /// - Validate business rules (e.g., user is active)
    /// - Check for required fields
    /// - Verify checksums or signatures
    ///
    /// Example:
    /// ```swift
    /// struct GetUserRequest: Endpoint {
    ///     typealias Response = UserResponse
    ///
    ///     func validate(response: UserResponse) throws {
    ///         guard response.success else {
    ///             throw ResponseError.validationFailed(response.errorMessage)
    ///         }
    ///         guard response.user.isActive else {
    ///             throw AuthenticationError.unauthorized(resource: "User is inactive")
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// - Parameter response: The decoded response to validate
    /// - Throws: Any error if validation fails
    func validate(response: Response) throws
}

// MARK: - Default Implementations

public extension Endpoint {
    /// Default base URL is nil (use client's default)
    var baseURL: String? { nil }

    /// Default headers are nil (use client's default)
    var headers: HTTPHeaders? { nil }

    /// Default parameters are nil
    var parameters: Request? { nil }

    /// Default parameter encoder is nil (automatic selection based on HTTP method)
    var parameterEncoder: ParameterEncoder? { nil }

    /// Default timeout is nil (use client's default)
    var timeout: TimeInterval? { nil }

    /// Default cache policy is nil (use client's default)
    var cachePolicy: URLRequest.CachePolicy? { nil }

    /// Default authorization is disabled
    var enableAuthorization: Bool { false }

    /// Default file upload is nil (no file upload).
    var uploadData: UploadData? { nil }

    /// Default implementation performs no validation.
    ///
    /// Override this method in your request to add custom validation logic.
    func validate(response: Response) throws {
        // No validation by default
    }
}

// MARK: - Endpoint+RetryPolicy Extension

/// Extension to add retry policy to Endpoint.
public extension Endpoint {
    /// Retry policy for this request.
    ///
    /// Override this to customize retry behavior for specific requests.
    /// Default is `nil` (no retries) to avoid unexpected behavior in tests.
    ///
    /// Example:
    /// ```swift
    /// struct MyRequest: Endpoint {
    ///     var retryPolicy: Alamofire.RetryPolicy? { .default }
    /// }
    /// ```
    var retryPolicy: Alamofire.RetryPolicy? { nil }
}

// MARK: - Empty Extension

/// Extension for requests without parameters.
///
/// Provides default nil implementation for parameters property when using Empty.
public extension Endpoint where Request == Empty {
    /// Default implementation returns nil for empty parameters.
    var parameters: Empty? { nil }
}
