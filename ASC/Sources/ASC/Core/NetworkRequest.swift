// NetworkRequest.swift
// ASC - Alamofire Swift Client

// Core protocol defining network request configuration.

@_exported import Alamofire
import Foundation

// MARK: - Type Aliases

/// HTTP method for requests.
public typealias HTTPMethod = Alamofire.HTTPMethod

/// HTTP headers collection.
public typealias HTTPHeaders = Alamofire.HTTPHeaders

/// HTTP header.
public typealias HTTPHeader = Alamofire.HTTPHeader

/// Request parameters dictionary.
public typealias Parameters = Alamofire.Parameters

/// Parameter encoding protocol.
public typealias ParameterEncoding = Alamofire.ParameterEncoding

/// JSON parameter encoding.
public typealias JSONEncoding = Alamofire.JSONEncoding

/// URL parameter encoding.
public typealias URLEncoding = Alamofire.URLEncoding

/// Retry policy for requests.
public typealias RetryPolicy = Alamofire.RetryPolicy

/// Request interceptor for adapting and retrying requests.
public typealias RequestInterceptor = Alamofire.RequestInterceptor

/// Event monitor for observing request lifecycle.
public typealias EventMonitor = Alamofire.EventMonitor

/// Server trust manager for SSL/TLS validation.
public typealias ServerTrustManager = Alamofire.ServerTrustManager

/// Redirect handler for custom redirect logic.
public typealias RedirectHandler = Alamofire.RedirectHandler

/// Cached response handler for custom caching behavior.
public typealias CachedResponseHandler = Alamofire.CachedResponseHandler

/// Interceptor combining adapters and retriers.
public typealias Interceptor = Alamofire.Interceptor

/// Protocol defining a network request configuration.
///
/// Implement this protocol to create type-safe network requests.
/// The protocol uses associated types to ensure compile-time type safety
/// for request and response data.
///
/// Example:
/// ```swift
/// struct GetUserRequest: NetworkRequest {
///     typealias Response = User
///
///     let userId: String
///
///     var path: String { "/users/\(userId)" }
///     var method: HTTPMethod { .get }
/// }
/// ```
public protocol NetworkRequest: Sendable {
    /// The expected response type conforming to Decodable.
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

    /// Request parameters.
    ///
    /// Parameters to be encoded in the request.
    /// The encoding location and format depends on `parameterEncoding`.
    var parameters: Parameters? { get }

    /// Parameter encoding strategy.
    ///
    /// Determines how parameters should be encoded.
    /// Default is JSON encoding.
    var parameterEncoding: any ParameterEncoding { get }

    /// Request timeout interval in seconds.
    ///
    /// If not specified, the client's default timeout will be used.
    var timeout: TimeInterval? { get }

    /// Cache policy for this request.
    ///
    /// If not specified, the client's default cache policy will be used.
    var cachePolicy: URLRequest.CachePolicy? { get }

    var isAuthorized: Bool { get }

    /// Files to upload in a multipart request.
    ///
    /// Dictionary mapping field names to file data.
    /// When specified, the request automatically becomes a multipart/form-data request.
    var files: [String: Data]? { get }

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
    /// struct GetUserRequest: NetworkRequest {
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

public extension NetworkRequest {
    /// Default base URL is nil (use client's default)
    var baseURL: String? { nil }

    /// Default headers are nil (use client's default)
    var headers: HTTPHeaders? { nil }

    /// Default parameters are nil
    var parameters: Parameters? { nil }

    /// Default encoding is JSON
    var parameterEncoding: any ParameterEncoding { JSONEncoding.default }

    /// Default timeout is nil (use client's default)
    var timeout: TimeInterval? { nil }

    /// Default cache policy is nil (use client's default)
    var cachePolicy: URLRequest.CachePolicy? { nil }

    /// Default files are nil
    var files: [String: Data]? { nil }

    /// Default authorization is false
    var isAuthorized: Bool { false }

    /// Default implementation performs no validation.
    ///
    /// Override this method in your request to add custom validation logic.
    func validate(response: Response) throws {
        // No validation by default
    }
}
