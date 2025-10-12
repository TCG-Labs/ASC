// AlamofireReExports.swift
// ASC - Alamofire Swift Client
// Re-exports of Alamofire types for convenience and consistency.

import Alamofire
import Foundation

// MARK: - HTTP Types

/// Re-export Alamofire's HTTPHeaders for convenience.
///
/// An order-preserving and case-insensitive representation of HTTP headers.
/// See Alamofire documentation for full details.
public typealias HTTPHeaders = Alamofire.HTTPHeaders

/// Re-export Alamofire's HTTPHeader for convenience.
///
/// A single HTTP header field.
public typealias HTTPHeader = Alamofire.HTTPHeader

/// Re-export Alamofire's HTTPMethod for convenience.
///
/// HTTP method type with standard methods and support for custom methods.
public typealias HTTPMethod = Alamofire.HTTPMethod

// MARK: - Parameter Encoding

/// Re-export Alamofire's Parameters typealias.
///
/// Type alias for parameter dictionaries.
public typealias Parameters = Alamofire.Parameters

/// Re-export Alamofire's ParameterEncoding protocol.
///
/// Protocol for encoding parameters into URLRequests.
public typealias ParameterEncoding = Alamofire.ParameterEncoding

/// Re-export Alamofire's JSONEncoding.
///
/// Encodes parameters as JSON in the request body.
public typealias JSONEncoding = Alamofire.JSONEncoding

/// Re-export Alamofire's URLEncoding.
///
/// Encodes parameters as URL-encoded query string or HTTP body.
public typealias URLEncoding = Alamofire.URLEncoding

// MARK: - URL Conversion

/// Re-export Alamofire's URLConvertible protocol.
///
/// A type that can be converted to a URL.
public typealias URLConvertible = Alamofire.URLConvertible

/// Re-export Alamofire's URLRequestConvertible protocol.
///
/// A type that can be converted to a URLRequest.
public typealias URLRequestConvertible = Alamofire.URLRequestConvertible

// MARK: - Interceptors (for future use)

/// Re-export Alamofire's RequestAdapter protocol.
///
/// A type that can adapt URLRequests before they are sent.
public typealias RequestAdapter = Alamofire.RequestAdapter

/// Re-export Alamofire's RequestRetrier protocol.
///
/// A type that can determine whether a failed request should be retried.
public typealias RequestRetrier = Alamofire.RequestRetrier

/// Re-export Alamofire's RequestInterceptor protocol.
///
/// A type that combines RequestAdapter and RequestRetrier.
public typealias RequestInterceptor = Alamofire.RequestInterceptor

// MARK: - Monitoring (for future use)

/// Re-export Alamofire's EventMonitor protocol.
///
/// A type that observes Alamofire request lifecycle events.
public typealias EventMonitor = Alamofire.EventMonitor

// MARK: - Handlers (for future use)

/// Re-export Alamofire's CachedResponseHandler protocol.
///
/// A type that handles cached URL responses.
public typealias CachedResponseHandler = Alamofire.CachedResponseHandler

/// Re-export Alamofire's RedirectHandler protocol.
///
/// A type that handles HTTP redirects.
public typealias RedirectHandler = Alamofire.RedirectHandler

/// Re-export Alamofire's ServerTrustManager.
///
/// Manages server trust policies for SSL/TLS validation.
public typealias ServerTrustManager = Alamofire.ServerTrustManager

/// Re-export Alamofire's Interceptor.
///
/// Combines multiple RequestInterceptors into a single interceptor.
public typealias Interceptor = Alamofire.Interceptor
