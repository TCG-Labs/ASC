// AuthInterceptor.swift
// ASC - Alamofire Swift Client
//
//  Copyright (c) 2025 TCG Labs
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

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
        var urlRequest = urlRequest

        guard let authHeader = storage.authToken?.header else {
            completion(.failure(ASCError.invalidToken))
            return
        }

        urlRequest.headers.add(authHeader)

        completion(.success(urlRequest))
    }
}
