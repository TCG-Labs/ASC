// NetworkClientConfiguration.swift
// ASC - Alamofire Swift Client

// Configuration for NetworkClient.

import Alamofire
import Foundation

/// Configuration for NetworkClient.
///
/// Provides fine-grained control over networking behavior using Alamofire's
/// advanced features including interceptors, monitors, handlers, and trust managers.
public struct NetworkClientConfiguration: Sendable {
    /// Default base URL for all requests.
    public let baseURL: String

    /// URLSession configuration.
    public let urlSessionConfiguration: URLSessionConfiguration

    /// Default request timeout in seconds.
    public let defaultTimeout: TimeInterval

    /// Default cache policy.
    public let defaultCachePolicy: URLRequest.CachePolicy

    /// Default headers added to all requests.
    public let defaultHeaders: HTTPHeaders

    /// Request interceptors for adapting and retrying requests.
    public let interceptors: [any RequestInterceptor]

    /// Event monitors for observing request lifecycle.
    public let eventMonitors: [any EventMonitor]

    /// Server trust manager for SSL/TLS validation.
    public let serverTrustManager: ServerTrustManager?

    /// Redirect handler for custom redirect logic.
    public let redirectHandler: (any RedirectHandler)?

    /// Cached response handler for custom caching behavior.
    public let cachedResponseHandler: (any CachedResponseHandler)?

    /// Dispatch queue for root operations.
    public let rootQueue: DispatchQueue

    /// Dispatch queue for request operations.
    public let requestQueue: DispatchQueue

    /// Dispatch queue for serialization operations.
    public let serializationQueue: DispatchQueue

    /// Threshold for using file-based multipart encoding (in bytes).
    ///
    /// Files larger than this threshold will use file-based encoding to avoid memory issues.
    /// Default is 10MB (10,000,000 bytes).
    public let multipartFileSizeThreshold: Int

    /// Creates a new network client configuration.
    ///
    /// - Parameters:
    ///   - baseURL: Default base URL for requests
    ///   - urlSessionConfiguration: URLSession configuration (default: .default)
    ///   - defaultTimeout: Default request timeout (default: 60)
    ///   - defaultCachePolicy: Default cache policy (default: .useProtocolCachePolicy)
    ///   - defaultHeaders: Default headers (default: .default)
    ///   - interceptors: Request interceptors (default: [])
    ///   - eventMonitors: Event monitors (default: [])
    ///   - serverTrustManager: Server trust manager (default: nil)
    ///   - redirectHandler: Redirect handler (default: nil)
    ///   - cachedResponseHandler: Cached response handler (default: nil)
    ///   - rootQueue: Root dispatch queue (default: custom queue)
    ///   - requestQueue: Request dispatch queue (default: custom queue)
    ///   - serializationQueue: Serialization dispatch queue (default: custom queue)
    ///   - multipartFileSizeThreshold: Threshold for file-based encoding (default: 10MB)
    public init(
        baseURL: String,
        urlSessionConfiguration: URLSessionConfiguration = .default,
        defaultTimeout: TimeInterval = 60,
        defaultCachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
        defaultHeaders: HTTPHeaders = .default,
        interceptors: [any RequestInterceptor] = [],
        eventMonitors: [any EventMonitor] = [],
        serverTrustManager: ServerTrustManager? = nil,
        redirectHandler: (any RedirectHandler)? = nil,
        cachedResponseHandler: (any CachedResponseHandler)? = nil,
        rootQueue: DispatchQueue = DispatchQueue(label: "com.asc.networkClient.rootQueue"),
        requestQueue: DispatchQueue = DispatchQueue(
            label: "com.asc.networkClient.requestQueue",
            qos: .userInitiated
        ),
        serializationQueue: DispatchQueue = DispatchQueue(
            label: "com.asc.networkClient.serializationQueue",
            qos: .userInitiated
        ),
        multipartFileSizeThreshold: Int = ASCConstants.FileUpload.defaultSizeThreshold
    ) {
        self.baseURL = baseURL
        self.urlSessionConfiguration = urlSessionConfiguration
        self.defaultTimeout = defaultTimeout
        self.defaultCachePolicy = defaultCachePolicy
        self.defaultHeaders = defaultHeaders
        self.interceptors = interceptors
        self.eventMonitors = eventMonitors
        self.serverTrustManager = serverTrustManager
        self.redirectHandler = redirectHandler
        self.cachedResponseHandler = cachedResponseHandler
        self.rootQueue = rootQueue
        self.requestQueue = requestQueue
        self.serializationQueue = serializationQueue
        self.multipartFileSizeThreshold = multipartFileSizeThreshold
    }

    /// Creates a default configuration with the specified base URL.
    ///
    /// - Parameter baseURL: Default base URL for requests
    /// - Returns: A default configuration
    public static func `default`(baseURL: String) -> NetworkClientConfiguration {
        NetworkClientConfiguration(baseURL: baseURL)
    }
}
