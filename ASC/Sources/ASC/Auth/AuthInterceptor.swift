// AuthInterceptor.swift
// ASC - Alamofire Swift Client

// Simple request interceptor that adds authentication token to requests.

import Alamofire
import Foundation

/// Simple request interceptor that adds authentication token to requests.
///
/// **Use this when**:
/// - You don't need automatic refresh on 401
/// - You handle token refresh manually
/// - You want explicit control over auth
///
/// **Use `OAuthAuthenticator` when**:
/// - You want automatic refresh on 401
/// - You have refresh token support
///
/// Example:
/// ```swift
/// let interceptor = AuthInterceptor(storage: storage)
///
/// let config = NetworkClientConfiguration(
///     baseURL: "https://api.example.com",
///     interceptors: [interceptor]
/// )
/// ```
public final class AuthInterceptor: RequestInterceptor, @unchecked Sendable {
    // MARK: - Properties

    private let storage: any TokenStorage

    // MARK: - Initialization

    /// Creates a new auth interceptor.
    ///
    /// - Parameters:
    ///   - storage: Token storage
    ///   - tokenType: Token type (default: .bearer)
    public init(storage: any TokenStorage) {
        self.storage = storage
    }

    // MARK: - RequestInterceptor

    /// Adds Authorization header to request if token is available.
    public func adapt(
        _ urlRequest: URLRequest,
        for session: Session,
        completion: @escaping (Result<URLRequest, any Error>) -> Void
    ) {
        guard urlRequest.headers.contains(HeaderKeys.authorization) else {
            completion(.success(urlRequest))
            return
        }

        var urlRequest = urlRequest
        urlRequest.headers.remove(name: HeaderKeys.authorization.name)

        guard let accessToken = storage.accessToken else {
            completion(.failure(ASCError.invalidToken))
            return
        }

        let authValue = "\(storage.tokenType.rawValue) \(accessToken)"
        urlRequest.headers.add(name: "Authorization", value: authValue)

        completion(.success(urlRequest))
    }
}
