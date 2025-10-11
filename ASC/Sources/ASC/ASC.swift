// ASC.swift
// Alamofire Swift Client
//
// A protocol-oriented Swift networking library built on top of Alamofire.
// Provides type-safe, modern async/await API for network requests.

import Foundation

/// ASC - Alamofire Swift Client
///
/// A convenient wrapper around Alamofire providing:
/// - Type-safe protocol-oriented API
/// - Automatic Codable serialization
/// - Request/response interceptors
/// - Comprehensive error handling
/// - Built-in retry logic
/// - Request/response logging
/// - Authentication support
/// - Progress tracking for uploads/downloads
///
/// Example usage:
/// ```swift
/// struct GetUserRequest: NetworkRequest {
///     typealias Response = User
///     let userId: String
///     var path: String { "/users/\(userId)" }
///     var method: HTTPMethod { .get }
/// }
///
/// let client = NetworkClient(baseURL: "https://api.example.com")
/// let user = try await client.execute(GetUserRequest(userId: "123"))
/// ```
public enum ASC {
    /// Current version of the library
    public static let version = "1.0.0"

    /// Library name
    public static let name = "ASC - Alamofire Swift Client"
}
