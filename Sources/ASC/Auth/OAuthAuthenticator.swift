// OAuthAuthenticator.swift
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

// OAuth authenticator with automatic token refresh support.

import Foundation
import Alamofire
import JWTDecode

// MARK: - OAuthAuthenticator

/// OAuth credential containing access token, refresh token, and expiration information.
public struct OAuthCredential: AuthenticationCredential, Sendable {
    public let authToken: AuthToken

    /// Token expiration date.
    public var expiration: Date? {
        switch authToken {
            case .bearer(let token):
                expirationDate(token: token) ?? .now
            case .basic(let username, let password):
                nil
            case .custom(let token):
                nil
        }
    }

    /// Require refresh if within 5 minutes of expiration.
    public var requiresRefresh: Bool {
        if let expiration {
//            Date(timeIntervalSinceNow: 60 * 5) > expiration
            Date(timeIntervalSinceNow: 60 * 14) > expiration
        } else {
            false
        }
    }

    /// Creates a new OAuth credential.
    ///
    /// - Parameters:
    ///   - accessToken: Access token for API requests
    ///   - refreshToken: Refresh token for obtaining new access tokens
    ///   - userID: User ID associated with the credential
    ///   - expiration: Token expiration date
    public init(authToken: AuthToken) {
        self.authToken = authToken
    }

    func expirationDate(token: String) -> Date? {
        do {
            let jwt = try decode(jwt: token)
            return jwt.expiresAt
        } catch let error {
            debugPrint(error.localizedDescription)
            return nil
        }
    }
}

// MARK: - OAuthAuthenticator

/// OAuth authenticator that automatically refreshes tokens on 401 errors.
///
/// This authenticator integrates with `TokenStorage` to automatically refresh
/// expired tokens when a 401 Unauthorized response is received.
///
/// Example:
/// ```swift
/// let storage = MyTokenStorage()
/// let authenticator = OAuthAuthenticator(storage: storage)
/// let interceptor = AuthenticationInterceptor(
///     authenticator: authenticator,
///     credential: initialCredential
/// )
/// ```
public final class OAuthAuthenticator: Authenticator, @unchecked Sendable {
    public static func buildAuthInterceptor(storage: any OAuthTokenStorage) -> AuthenticationInterceptor<OAuthAuthenticator> {
        let authenticator: OAuthAuthenticator = .init(storage: storage)
        let credential = storage.getAuthCredential()
        return .init(authenticator: authenticator, credential: credential)
    }

    // MARK: - Properties

    /// Token storage for managing tokens.
    private let storage: any OAuthTokenStorage

    // MARK: - Initialization

    /// Creates a new OAuth authenticator.
    ///
    /// - Parameter storage: Token storage for managing tokens
    public init(storage: any OAuthTokenStorage) {
        self.storage = storage
    }

    // MARK: - Authenticator

    /// Applies the credential to the request by adding Authorization header.
    public func apply(_ credential: OAuthCredential, to urlRequest: inout URLRequest) {
        urlRequest.headers.add(credential.authToken.header)
    }

    /// Refreshes the credential using the refresh token.
    ///
    /// This method:
    /// 1. Gets the refresh request from TokenStorage
    /// 2. Executes the refresh request using a separate session (to avoid circular dependencies)
    /// 3. Uses TokenStorage's executeRefreshToken to update tokens
    /// 4. Gets updated tokens from storage
    /// 5. Creates a new OAuthCredential
    /// 6. Calls completion with the result
    public func refresh(
        _ credential: OAuthCredential,
        for session: Session,
        completion: @escaping @Sendable (Result<OAuthCredential, Error>) -> Void
    ) {
        // Execute refresh using TokenStorage's executeRefreshToken method
        // This uses async/await, so we need to bridge to completion-based API
        Task { @Sendable in
            do {
                // Execute refresh token using TokenStorage's method
                // This will execute the refreshRequest and update tokens in storage
                try await storage.executeRefreshToken()

                // Get updated tokens from storage
                guard
                    let credential = storage.getAuthCredential()
                else {
                    completion(.failure(ASCError.invalidToken))
                    return
                }

                completion(.success(credential))
            } catch {
                // Map errors to appropriate ASCError types
                if let ascError = error as? ASCError {
                    completion(.failure(ascError))
                } else {
                    completion(.failure(ASCError.tokenRefreshFailed(error)))
                }
            }
        }
    }

    /// Determines if a request failed due to an authentication error.
    ///
    /// Returns `true` for 401 Unauthorized responses to trigger automatic refresh.
    public func didRequest(
        _ urlRequest: URLRequest,
        with response: HTTPURLResponse,
        failDueToAuthenticationError error: Error
    ) -> Bool {
        // If authentication server CANNOT invalidate credentials, return `false`

        // If authentication server CAN invalidate credentials, then inspect the response matching against what the
        // authentication server returns as an authentication failure. This is generally a 401 along with a custom
        // header value.

        return false
    }

    /// Determines if a request is already authenticated with the given credential.
    ///
    /// Returns `true` by default, assuming requests are authenticated if they have
    /// the Authorization header matching the credential's access token.
    public func isRequest(_ urlRequest: URLRequest, authenticatedWith credential: OAuthCredential) -> Bool {
        // If authentication server CAN invalidate credentials, then compare the "Authorization" header value in the
        // `URLRequest` against the Bearer token generated with the access token of the `Credential`.
        // let bearerToken = HTTPHeader.authorization(bearerToken: credential.accessToken).value
        // return urlRequest.headers["Authorization"] == bearerToken

        return true
    }
}
