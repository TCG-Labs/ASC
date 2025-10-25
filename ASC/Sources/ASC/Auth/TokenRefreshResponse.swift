// TokenRefreshResponse.swift
// ASC - Alamofire Swift Client

// Protocol for token refresh response.

import Foundation

/// Protocol for token refresh response.
///
/// Your refresh request response should conform to this protocol.
///
/// Example:
/// ```swift
/// struct MyTokenResponse: Decodable, TokenRefreshResponse {
///     let accessToken: String
///     let refreshToken: String?
///
///     enum CodingKeys: String, CodingKey {
///         case accessToken = "access_token"
///         case refreshToken = "refresh_token"
///     }
/// }
///
/// struct RefreshRequest: NetworkRequest {
///     typealias Response = MyTokenResponse
///     // ...
/// }
/// ```
public protocol TokenRefreshResponse {
    /// New access token from refresh response
    var accessToken: String { get }

    /// New refresh token (optional)
    ///
    /// If provided, will replace the old refresh token.
    /// If `nil`, the old refresh token is kept.
    var refreshToken: String? { get }
}
