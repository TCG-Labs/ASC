// MockInterceptor.swift
// ASC Tests
//
// Mock request interceptor for testing.

import Alamofire
@testable import ASC
import Foundation

/// Mock request interceptor for testing adapter and retry behavior.
public final class MockInterceptor: RequestInterceptor, @unchecked Sendable {
    // MARK: - Properties

    /// Closure called when adapt is invoked.
    public var adaptHandler: ((URLRequest) -> URLRequest)?

    /// Number of times adapt was called.
    public var adaptCallCount = 0

    /// Closure called when retry is invoked.
    public var retryHandler: ((Request, Error) -> Bool)?

    /// Number of times retry was called.
    public var retryCallCount = 0

    // MARK: - RequestAdapter

    public func adapt(
        _ urlRequest: URLRequest,
        for session: Session,
        completion: @escaping (Result<URLRequest, any Error>) -> Void
    ) {
        adaptCallCount += 1

        if let handler = adaptHandler {
            let adapted = handler(urlRequest)
            completion(.success(adapted))
        } else {
            completion(.success(urlRequest))
        }
    }

    // MARK: - RequestRetrier

    public func retry(
        _ request: Request,
        for session: Session,
        dueTo error: any Error,
        completion: @escaping (RetryResult) -> Void
    ) {
        retryCallCount += 1

        if let handler = retryHandler {
            let shouldRetry = handler(request, error)
            completion(shouldRetry ? .retry : .doNotRetry)
        } else {
            completion(.doNotRetry)
        }
    }

    // MARK: - Helper Methods

    /// Resets all counters and handlers.
    public func reset() {
        adaptHandler = nil
        retryHandler = nil
        adaptCallCount = 0
        retryCallCount = 0
    }
}
