// AuthInterceptor.swift
// ASC - Alamofire Swift Client

// Simple request interceptor that adds authentication token to requests.

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
        guard urlRequest.headers.contains(.authenticationRequired) else {
            completion(.success(urlRequest))
            return
        }

        var urlRequest = urlRequest
        urlRequest.headers.remove(name: HTTPHeader.authenticationRequired.name)

        guard let authHeader = storage.authToken?.header else {
            completion(.failure(ASCError.invalidToken))
            return
        }

        urlRequest.headers.add(authHeader)

        completion(.success(urlRequest))
    }
}
