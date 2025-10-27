// NetworkClientConfiguration.swift
// ASC - Alamofire Swift Client

// Configuration for NetworkClient.

import Alamofire
import Foundation

// MARK: - Supporting Types

/// Network constraints configuration.
///
/// Controls network access policies for URLSession.
public struct NetworkConstraints: Sendable {
    /// Wait for connectivity before failing.
    public var waitsForConnectivity: Bool

    /// Allow cellular network access.
    public var allowsCellularAccess: Bool

    /// Allow expensive network access (iOS 13+).
    ///
    /// Expensive networks include cellular data with active roaming or hotspot connections.
    public var allowsExpensiveNetworkAccess: Bool

    /// Allow constrained network access (iOS 13+).
    ///
    /// Constrained networks include Low Data Mode or interfaces with reduced throughput.
    public var allowsConstrainedNetworkAccess: Bool

    /// Default network constraints (all allowed).
    public static let `default` = NetworkConstraints(
        waitsForConnectivity: true,
        allowsCellularAccess: true,
        allowsExpensiveNetworkAccess: true,
        allowsConstrainedNetworkAccess: true
    )

    /// Restrictive constraints (Wi-Fi only, no expensive/constrained networks).
    public static let restrictive = NetworkConstraints(
        waitsForConnectivity: true,
        allowsCellularAccess: false,
        allowsExpensiveNetworkAccess: false,
        allowsConstrainedNetworkAccess: false
    )

    /// Creates network constraints.
    public init(
        waitsForConnectivity: Bool = true,
        allowsCellularAccess: Bool = true,
        allowsExpensiveNetworkAccess: Bool = true,
        allowsConstrainedNetworkAccess: Bool = true
    ) {
        self.waitsForConnectivity = waitsForConnectivity
        self.allowsCellularAccess = allowsCellularAccess
        self.allowsExpensiveNetworkAccess = allowsExpensiveNetworkAccess
        self.allowsConstrainedNetworkAccess = allowsConstrainedNetworkAccess
    }
}

/// HTTP response validation options.
///
/// Controls automatic validation of HTTP status codes.
public struct ValidationOptions: Sendable {
    /// Automatically validate HTTP status codes.
    public var isEnabled: Bool

    /// Acceptable HTTP status codes range.
    public var acceptableStatusCodes: Range<Int>

    /// Default validation (enabled, 200..<300).
    public static let `default` = ValidationOptions(
        isEnabled: true,
        acceptableStatusCodes: 200..<300
    )

    /// Disabled validation.
    public static let disabled = ValidationOptions(
        isEnabled: false,
        acceptableStatusCodes: 200..<300
    )

    /// Creates validation options.
    public init(isEnabled: Bool = true, acceptableStatusCodes: Range<Int> = 200..<300) {
        self.isEnabled = isEnabled
        self.acceptableStatusCodes = acceptableStatusCodes
    }
}

/// Default values for NetworkClientConfiguration.
public enum NetworkClientConfigurationDefaults {
    /// Default JSON decoder with ISO8601 dates and snake_case keys.
    public static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    /// Default JSON encoder with ISO8601 dates and snake_case keys.
    public static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()

    /// Default root dispatch queue for Alamofire session.
    public static let rootQueue = DispatchQueue(label: "com.asc.networkClient.rootQueue")

    /// Default request dispatch queue with user-initiated QoS.
    public static let requestQueue = DispatchQueue(
        label: "com.asc.networkClient.requestQueue",
        qos: .userInitiated
    )

    /// Default serialization dispatch queue with user-initiated QoS.
    public static let serializationQueue = DispatchQueue(
        label: "com.asc.networkClient.serializationQueue",
        qos: .userInitiated
    )
}

/// Type of URLSession to use.
public enum SessionType: Sendable {
    /// Default URLSession with disk-persisted cache
    case `default`
    /// Ephemeral session without disk cache (for private/sensitive data)
    case ephemeral
    /// Background session for downloads/uploads when app is suspended
    case background(identifier: String)
    /// Custom URLSessionConfiguration
    case custom(URLSessionConfiguration)

    /// Creates URLSessionConfiguration for this session type
    internal var configuration: URLSessionConfiguration {
        switch self {
        case .default:
            return .default

        case .ephemeral:
            return .ephemeral

        case .background(let identifier):
            return .background(withIdentifier: identifier)

        case .custom(let config):
            return config
        }
    }
}

/// Configuration for NetworkClient.
///
/// Provides fine-grained control over networking behavior using Alamofire's
/// advanced features including interceptors, monitors, handlers, and trust managers.
public struct NetworkClientConfiguration: Sendable {
    /// Default base URL for all requests.
    ///
    /// If nil, each request must provide its own baseURL.
    public let baseURL: String?

    /// URLSession configuration.
    public let urlSessionConfiguration: URLSessionConfiguration

    /// Default request timeout in seconds.
    public let defaultTimeout: TimeInterval

    /// Default cache policy.
    public let defaultCachePolicy: URLRequest.CachePolicy

    /// Default headers added to all requests.
    public var defaultHeaders: HTTPHeaders

    /// Request interceptors for adapting and retrying requests.
    public var interceptors: [any RequestInterceptor]

    /// Event monitors for observing request lifecycle.
    public var eventMonitors: [any EventMonitor]

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

    public let tokenStorage: TokenStorage?

    /// Log level for built-in logger.
    ///
    /// When set to anything other than .none, an ASCLogger is automatically added to eventMonitors.
    /// Default is .none (no logging).
    public let logLevel: ASCLogLevel

    /// Enable automatic connectivity checking before requests.
    ///
    /// When enabled, the client will check network connectivity before executing requests.
    /// If no connection is available, `NetworkError.noConnection` will be thrown immediately.
    /// This helps provide faster feedback and better error messages.
    /// Default is true.
    public let connectivityCheckEnabled: Bool

    /// JSON decoder for parsing responses.
    ///
    /// Customize date decoding strategies, key decoding strategies, etc.
    /// Default uses ISO8601 dates and converts from snake_case.
    public let decoder: JSONDecoder

    /// JSON encoder for encoding request bodies.
    ///
    /// Customize date encoding strategies, key encoding strategies, etc.
    /// Default uses ISO8601 dates and converts to snake_case.
    public let encoder: JSONEncoder

    /// Default retry policy for all requests.
    ///
    /// Individual requests can override this via their retryPolicy property.
    /// Default is nil (no automatic retries).
    public let defaultRetryPolicy: Alamofire.RetryPolicy?

    /// Network constraints configuration.
    ///
    /// Controls URLSession network access policies (cellular, expensive, constrained).
    /// Default allows all network types.
    public let networkConstraints: NetworkConstraints

    /// HTTP response validation options.
    ///
    /// Controls automatic validation of HTTP status codes.
    /// Default validates 200..<300 range.
    public let validation: ValidationOptions

    /// Default priority for all requests.
    ///
    /// Values range from 0.0 (lowest) to 1.0 (highest).
    /// Default is 0.5 (URLSessionTask.defaultPriority).
    public let defaultPriority: Float

    // MARK: - Computed Properties (for convenience)

    /// Wait for connectivity before failing.
    ///
    /// Convenience property that reads from networkConstraints.
    public var waitsForConnectivity: Bool {
        networkConstraints.waitsForConnectivity
    }

    /// Allow cellular network access.
    ///
    /// Convenience property that reads from networkConstraints.
    public var allowsCellularAccess: Bool {
        networkConstraints.allowsCellularAccess
    }

    /// Allow expensive network access (iOS 13+).
    ///
    /// Convenience property that reads from networkConstraints.
    public var allowsExpensiveNetworkAccess: Bool {
        networkConstraints.allowsExpensiveNetworkAccess
    }

    /// Allow constrained network access (iOS 13+).
    ///
    /// Convenience property that reads from networkConstraints.
    public var allowsConstrainedNetworkAccess: Bool {
        networkConstraints.allowsConstrainedNetworkAccess
    }

    /// Automatically validate HTTP status codes.
    ///
    /// Convenience property that reads from validation.
    public var automaticValidation: Bool {
        validation.isEnabled
    }

    /// Acceptable HTTP status codes range.
    ///
    /// Convenience property that reads from validation.
    public var acceptableStatusCodes: Range<Int> {
        validation.acceptableStatusCodes
    }

    /// Creates a new network client configuration.
    ///
    /// - Parameters:
    ///   - baseURL: Default base URL for requests (optional - can be specified per request)
    ///   - sessionType: Type of URLSession to use (default: .default)
    ///   - defaultTimeout: Default request timeout (default: 60)
    ///   - defaultCachePolicy: Default cache policy (default: .useProtocolCachePolicy)
    ///   - defaultHeaders: Default headers (default: .default)
    ///   - interceptors: Request interceptors (default: [])
    ///   - eventMonitors: Event monitors (default: [])
    ///   - serverTrustManager: Server trust manager (default: nil)
    ///   - redirectHandler: Redirect handler (default: nil)
    ///   - cachedResponseHandler: Cached response handler (default: nil)
    ///   - rootQueue: Root dispatch queue (default: from NetworkClientConfigurationDefaults)
    ///   - requestQueue: Request dispatch queue (default: from NetworkClientConfigurationDefaults)
    ///   - serializationQueue: Serialization dispatch queue (default: from NetworkClientConfigurationDefaults)
    ///   - logLevel: Log level for built-in logger (default: .none)
    ///   - connectivityCheckEnabled: Enable automatic connectivity checking (default: true)
    ///   - decoder: Custom JSON decoder (default: from NetworkClientConfigurationDefaults)
    ///   - encoder: Custom JSON encoder (default: from NetworkClientConfigurationDefaults)
    ///   - defaultRetryPolicy: Default retry policy for all requests (default: nil)
    ///   - networkConstraints: Network access constraints (default: .default)
    ///   - validation: HTTP response validation options (default: .default)
    ///   - defaultPriority: Default priority for all requests (default: 0.5)
    public init(
        baseURL: String? = nil,
        sessionType: SessionType = .default,
        defaultTimeout: TimeInterval = 60,
        defaultCachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
        defaultHeaders: HTTPHeaders = .default,
        interceptors: [any RequestInterceptor] = [],
        eventMonitors: [any EventMonitor] = [],
        serverTrustManager: ServerTrustManager? = nil,
        redirectHandler: (any RedirectHandler)? = nil,
        cachedResponseHandler: (any CachedResponseHandler)? = nil,
        rootQueue: DispatchQueue = NetworkClientConfigurationDefaults.rootQueue,
        requestQueue: DispatchQueue = NetworkClientConfigurationDefaults.requestQueue,
        serializationQueue: DispatchQueue = NetworkClientConfigurationDefaults.serializationQueue,
        tokenStorage: TokenStorage? = nil,
        logLevel: ASCLogLevel = .none,
        connectivityCheckEnabled: Bool = true,
        decoder: JSONDecoder = NetworkClientConfigurationDefaults.decoder,
        encoder: JSONEncoder = NetworkClientConfigurationDefaults.encoder,
        defaultRetryPolicy: Alamofire.RetryPolicy? = nil,
        networkConstraints: NetworkConstraints = .default,
        validation: ValidationOptions = .default,
        defaultPriority: Float = 0.5
    ) {
        self.baseURL = baseURL

        // Create URLSessionConfiguration from SessionType
        let urlConfig = sessionType.configuration

        // Apply network constraints to URLSession
        urlConfig.waitsForConnectivity = networkConstraints.waitsForConnectivity
        urlConfig.allowsCellularAccess = networkConstraints.allowsCellularAccess
        urlConfig.allowsExpensiveNetworkAccess = networkConstraints.allowsExpensiveNetworkAccess
        urlConfig.allowsConstrainedNetworkAccess = networkConstraints.allowsConstrainedNetworkAccess

        self.urlSessionConfiguration = urlConfig
        self.defaultTimeout = defaultTimeout
        self.defaultCachePolicy = defaultCachePolicy
        self.defaultHeaders = defaultHeaders
        self.interceptors = interceptors
        self.tokenStorage = tokenStorage
        self.logLevel = logLevel
        self.decoder = decoder
        self.encoder = encoder
        self.defaultRetryPolicy = defaultRetryPolicy
        self.networkConstraints = networkConstraints
        self.validation = validation
        self.defaultPriority = defaultPriority

        if let tokenStorage {
            let authInterceptor = AuthInterceptor(storage: tokenStorage)
            self.interceptors.append(authInterceptor)
        }

        // Automatically add ASCLogger if logging is enabled
        if logLevel != .none {
            var monitors = eventMonitors
            monitors.append(ASCLogger(logLevel: logLevel))
            self.eventMonitors = monitors
        } else {
            self.eventMonitors = eventMonitors
        }

        self.serverTrustManager = serverTrustManager
        self.redirectHandler = redirectHandler
        self.cachedResponseHandler = cachedResponseHandler
        self.rootQueue = rootQueue
        self.requestQueue = requestQueue
        self.serializationQueue = serializationQueue
        self.connectivityCheckEnabled = connectivityCheckEnabled
    }

    /// Creates a default configuration with optional customizations.
    ///
    /// - Parameters:
    ///   - baseURL: Default base URL for requests
    ///   - logLevel: Log level for built-in logger (default: .none)
    ///   - timeout: Default request timeout (default: 60)
    ///   - retryPolicy: Default retry policy (default: nil)
    /// - Returns: A default configuration
    public static func `default`(
        baseURL: String? = nil,
        logLevel: ASCLogLevel = .none,
        timeout: TimeInterval = 60,
        retryPolicy: Alamofire.RetryPolicy? = nil
    ) -> NetworkClientConfiguration {
        NetworkClientConfiguration(
            baseURL: baseURL,
            defaultTimeout: timeout,
            logLevel: logLevel,
            defaultRetryPolicy: retryPolicy
        )
    }

    /// Development configuration with verbose logging and relaxed timeouts.
    ///
    /// Features:
    /// - Verbose logging enabled
    /// - Extended timeout (120s) for debugging
    /// - Connectivity checking enabled
    /// - No automatic retries (to see errors immediately)
    ///
    /// - Parameter baseURL: Default base URL for requests
    /// - Returns: Development-optimized configuration
    public static func development(baseURL: String? = nil) -> NetworkClientConfiguration {
        NetworkClientConfiguration(
            baseURL: baseURL,
            defaultTimeout: 120,
            logLevel: .verbose,
            connectivityCheckEnabled: true,
            defaultRetryPolicy: nil
        )
    }

    /// Production configuration optimized for performance and reliability.
    ///
    /// Features:
    /// - Error-only logging
    /// - Fast timeout (30s)
    /// - Connectivity checking enabled
    /// - Conservative retry policy (2 retries)
    ///
    /// - Parameter baseURL: Default base URL for requests
    /// - Returns: Production-optimized configuration
    public static func production(baseURL: String? = nil) -> NetworkClientConfiguration {
        NetworkClientConfiguration(
            baseURL: baseURL,
            defaultTimeout: 30,
            logLevel: .error,
            connectivityCheckEnabled: true,
            defaultRetryPolicy: .conservative
        )
    }

    /// Testing configuration for unit/integration tests.
    ///
    /// Features:
    /// - No logging
    /// - Short timeout (10s)
    /// - Connectivity checking disabled (for mocks)
    /// - No automatic retries
    ///
    /// - Parameter baseURL: Default base URL for requests
    /// - Returns: Testing-optimized configuration
    public static func testing(baseURL: String? = nil) -> NetworkClientConfiguration {
        NetworkClientConfiguration(
            baseURL: baseURL,
            defaultTimeout: 10,
            logLevel: .none,
            connectivityCheckEnabled: false,
            defaultRetryPolicy: nil
        )
    }
}
