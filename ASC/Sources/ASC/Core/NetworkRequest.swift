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

/// Parameter encoder for encoding Encodable parameters.
public typealias ParameterEncoder = Alamofire.ParameterEncoder

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
///     typealias Parameters = EmptyParameters
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

    /// The parameters type conforming to Encodable.
    ///
    /// Use `EmptyParameters` for requests without parameters (GET, DELETE, etc.).
    /// For requests with parameters, define a custom Encodable struct.
    ///
    /// Example:
    /// ```swift
    /// struct CreateUserRequest: NetworkRequest {
    ///     struct UserData: Encodable, Sendable {
    ///         let email: String
    ///         let name: String
    ///     }
    ///     typealias Parameters = UserData
    /// }
    /// ```
    associatedtype Parameters: Encodable & Sendable

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
    /// struct SearchRequest: NetworkRequest {
    ///     struct Query: Encodable, Sendable {
    ///         let q: String
    ///         let limit: Int
    ///     }
    ///     typealias Parameters = Query
    ///
    ///     var parameters: Query? {
    ///         Query(q: "swift", limit: 10)
    ///     }
    /// }
    /// ```
    var parameters: Parameters? { get }

    /// Custom parameter encoder for this request.
    ///
    /// If specified, this encoder will be used instead of the automatic encoder selection.
    /// This allows fine-grained control over parameter encoding when needed.
    ///
    /// Common use cases:
    /// - Custom array encoding (brackets, no brackets, indexed)
    /// - Custom boolean encoding (0/1 vs true/false)
    /// - Custom date formatting in query strings
    /// - Custom nested object encoding
    ///
    /// Example:
    /// ```swift
    /// struct CreateUserRequest: NetworkRequest {
    ///     struct UserData: Encodable, Sendable {
    ///         let name: String
    ///         let email: String
    ///     }
    ///     typealias Parameters = UserData
    ///
    ///     var path: String { "/users" }
    ///     var method: HTTPMethod { .post }
    ///
    ///     var parameters: UserData? {
    ///         UserData(name: "John", email: "john@example.com")
    ///     }
    ///
    ///     // Custom encoder - use URL encoding in POST body instead of JSON
    ///     var parameterEncoder: ParameterEncoder? {
    ///         URLEncodedFormParameterEncoder.default
    ///     }
    /// }
    /// // POST body will be: name=John&email=john@example.com (URL-encoded)
    /// // Instead of default: {"name":"John","email":"john@example.com"} (JSON)
    /// ```
    var parameterEncoder: ParameterEncoder? { get }

    /// Request timeout interval in seconds.
    ///
    /// If not specified, the client's default timeout will be used.
    var timeout: TimeInterval? { get }

    /// Cache policy for this request.
    ///
    /// If not specified, the client's default cache policy will be used.
    var cachePolicy: URLRequest.CachePolicy? { get }

    var isAuthorized: Bool { get }

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

    /// Default parameter encoder is nil (automatic selection based on HTTP method)
    var parameterEncoder: ParameterEncoder? { nil }

    /// Default timeout is nil (use client's default)
    var timeout: TimeInterval? { nil }

    /// Default cache policy is nil (use client's default)
    var cachePolicy: URLRequest.CachePolicy? { nil }

    /// Default authorization is false
    var isAuthorized: Bool { false }

    /// Default implementation performs no validation.
    ///
    /// Override this method in your request to add custom validation logic.
    func validate(response: Response) throws {
        // No validation by default
    }
}

// MARK: - EmptyParameters Extension

/// Extension for requests without parameters.
///
/// Provides default nil implementation for parameters property when using EmptyParameters.
public extension NetworkRequest where Parameters == EmptyParameters {
    /// Default implementation returns nil for empty parameters.
    var parameters: EmptyParameters? { nil }
}
