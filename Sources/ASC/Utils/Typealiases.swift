//
//  Typealiases.swift
//  ASC
//
//  Created by Vyacheslav Razumeenko on 05.01.2026.
//

@_exported import Alamofire

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

/// Empty type for requests without parameters or empty responses.
public typealias Empty = Alamofire.Empty
