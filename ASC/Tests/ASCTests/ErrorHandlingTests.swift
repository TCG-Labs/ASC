// ErrorHandlingTests.swift
// ASC Tests
//
// Tests for error handling system.

import Testing
import Foundation
@testable import ASC

// MARK: - NetworkError Tests

@Test("NetworkError.noConnection has correct description")
func testNetworkErrorNoConnection() {
    let error = NetworkError.noConnection

    #expect(error.errorDescription == "No internet connection available")
    #expect(error.recoverySuggestion == "Please check your internet connection and try again")
    #expect(error.underlyingError == nil)
}

@Test("NetworkError.timeout has correct description")
func testNetworkErrorTimeout() {
    let error = NetworkError.timeout(30.0)

    #expect(error.errorDescription == "Request timed out after 30.0 seconds")
    #expect(error.recoverySuggestion == "Please try again or check your internet connection")
}

@Test("NetworkError.hostUnreachable has correct description")
func testNetworkErrorHostUnreachable() {
    let error = NetworkError.hostUnreachable("api.example.com")

    #expect(error.errorDescription == "Cannot reach host: api.example.com")
    #expect(error.recoverySuggestion == "Please check the server address and try again")
}

@Test("NetworkError.certificateValidationFailed has correct description")
func testNetworkErrorCertificateValidationFailed() {
    let error = NetworkError.certificateValidationFailed("Self-signed certificate")

    #expect(error.errorDescription == "Certificate validation failed: Self-signed certificate")
    #expect(error.recoverySuggestion == "Please verify the server's SSL certificate")
}

@Test("NetworkError.cancelled has correct description")
func testNetworkErrorCancelled() {
    let error = NetworkError.cancelled

    #expect(error.errorDescription == "Request was cancelled")
    #expect(error.recoverySuggestion == nil)
}

@Test("NetworkError.networkFailure wraps underlying error")
func testNetworkErrorNetworkFailure() {
    let underlyingError = NSError(
        domain: NSURLErrorDomain,
        code: NSURLErrorNetworkConnectionLost,
        userInfo: [NSLocalizedDescriptionKey: "Connection lost"]
    )
    let error = NetworkError.networkFailure(underlyingError)

    #expect(error.errorDescription?.contains("Connection lost") == true)
    #expect(error.underlyingError != nil)
}

// MARK: - ResponseError Tests

@Test("ResponseError.invalidStatusCode provides status code")
func testResponseErrorInvalidStatusCode() {
    let data = "Error data".data(using: .utf8)
    let error = ResponseError.invalidStatusCode(404, data)

    #expect(error.errorDescription == "Invalid HTTP status code: 404")
    #expect(error.statusCode == 404)
    #expect(error.responseData == data)
}

@Test("ResponseError.decodingFailed wraps decoding error")
func testResponseErrorDecodingFailed() {
    let data = "Invalid JSON".data(using: .utf8)!
    let decodingError = NSError(
        domain: "DecodingError",
        code: 1,
        userInfo: [NSLocalizedDescriptionKey: "Type mismatch"]
    )
    let error = ResponseError.decodingFailed(decodingError, data)

    #expect(error.errorDescription?.contains("Type mismatch") == true)
    #expect(error.underlyingError != nil)
    #expect(error.responseData == data)
}

@Test("ResponseError.missingData has correct description")
func testResponseErrorMissingData() {
    let error = ResponseError.missingData

    #expect(error.errorDescription == "Response data is missing")
    #expect(error.recoverySuggestion == "Expected data from server but received none")
}

@Test("ResponseError.invalidFormat has correct description")
func testResponseErrorInvalidFormat() {
    let error = ResponseError.invalidFormat("Expected JSON, got XML")

    #expect(error.errorDescription == "Invalid response format: Expected JSON, got XML")
    #expect(error.recoverySuggestion == "The server response format is invalid")
}

@Test("ResponseError.serverError provides status code and message")
func testResponseErrorServerError() {
    let error = ResponseError.serverError(500, "Internal server error")

    #expect(error.errorDescription == "Server error (500): Internal server error")
    #expect(error.statusCode == 500)
    #expect(error.recoverySuggestion == "The server encountered an error. Please try again later")
}

@Test("ResponseError.clientError provides status code")
func testResponseErrorClientError() {
    let error = ResponseError.clientError(400, "Bad request")

    #expect(error.errorDescription == "Client error (400): Bad request")
    #expect(error.statusCode == 400)
}

@Test("ResponseError.clientError handles nil message")
func testResponseErrorClientErrorNoMessage() {
    let error = ResponseError.clientError(403, nil)

    #expect(error.errorDescription == "Client error (403)")
}

@Test("ResponseError.validationFailed has correct description")
func testResponseErrorValidationFailed() {
    let error = ResponseError.validationFailed("Content-Type mismatch")

    #expect(error.errorDescription == "Response validation failed: Content-Type mismatch")
    #expect(error.recoverySuggestion == "Please verify the response data")
}

// MARK: - AuthenticationError Tests

@Test("AuthenticationError.notAuthenticated has correct description")
func testAuthenticationErrorNotAuthenticated() {
    let error = AuthenticationError.notAuthenticated

    #expect(error.errorDescription == "Not authenticated")
    #expect(error.recoverySuggestion == "Please log in to continue")
}

@Test("AuthenticationError.tokenExpired has correct description")
func testAuthenticationErrorTokenExpired() {
    let error = AuthenticationError.tokenExpired

    #expect(error.errorDescription == "Authentication token has expired")
    #expect(error.recoverySuggestion == "Your session has expired. Please log in again")
}

@Test("AuthenticationError.invalidToken has correct description")
func testAuthenticationErrorInvalidToken() {
    let error = AuthenticationError.invalidToken

    #expect(error.errorDescription == "Authentication token is invalid")
    #expect(error.recoverySuggestion == "Your session is invalid. Please log in again")
}

@Test("AuthenticationError.tokenRefreshFailed wraps underlying error")
func testAuthenticationErrorTokenRefreshFailed() {
    let underlyingError = NSError(
        domain: "TokenError",
        code: 1,
        userInfo: [NSLocalizedDescriptionKey: "Refresh token expired"]
    )
    let error = AuthenticationError.tokenRefreshFailed(underlyingError)

    #expect(error.errorDescription?.contains("Refresh token expired") == true)
    #expect(error.underlyingError != nil)
}

@Test("AuthenticationError.unauthorized with resource")
func testAuthenticationErrorUnauthorizedWithResource() {
    let error = AuthenticationError.unauthorized("/admin")

    #expect(error.errorDescription == "Unauthorized access to: /admin")
    #expect(error.recoverySuggestion == "You don't have permission to access this resource")
}

@Test("AuthenticationError.unauthorized without resource")
func testAuthenticationErrorUnauthorizedNoResource() {
    let error = AuthenticationError.unauthorized(nil)

    #expect(error.errorDescription == "Unauthorized access")
}

@Test("AuthenticationError.forbidden with reason")
func testAuthenticationErrorForbiddenWithReason() {
    let error = AuthenticationError.forbidden("Insufficient privileges")

    #expect(error.errorDescription == "Access forbidden: Insufficient privileges")
    #expect(error.recoverySuggestion == "You don't have permission to perform this action")
}

@Test("AuthenticationError.forbidden without reason")
func testAuthenticationErrorForbiddenNoReason() {
    let error = AuthenticationError.forbidden(nil)

    #expect(error.errorDescription == "Access forbidden")
}

@Test("AuthenticationError.invalidCredentials with reason")
func testAuthenticationErrorInvalidCredentialsWithReason() {
    let error = AuthenticationError.invalidCredentials("Wrong password")

    #expect(error.errorDescription == "Invalid credentials: Wrong password")
    #expect(error.recoverySuggestion == "Please check your credentials and try again")
}

@Test("AuthenticationError.invalidCredentials without reason")
func testAuthenticationErrorInvalidCredentialsNoReason() {
    let error = AuthenticationError.invalidCredentials(nil)

    #expect(error.errorDescription == "Invalid credentials")
}

@Test("AuthenticationError.maxRetryAttemptsExceeded has correct description")
func testAuthenticationErrorMaxRetryAttemptsExceeded() {
    let error = AuthenticationError.maxRetryAttemptsExceeded

    #expect(error.errorDescription == "Maximum authentication retry attempts exceeded")
    #expect(error.recoverySuggestion == "Please log in again")
}

// MARK: - HTTPStatus Tests

@Test("HTTPStatus.isSuccess identifies success codes")
func testHTTPStatusIsSuccess() {
    #expect(HTTPStatus.isSuccess(200) == true)
    #expect(HTTPStatus.isSuccess(201) == true)
    #expect(HTTPStatus.isSuccess(204) == true)
    #expect(HTTPStatus.isSuccess(299) == true)

    #expect(HTTPStatus.isSuccess(199) == false)
    #expect(HTTPStatus.isSuccess(300) == false)
    #expect(HTTPStatus.isSuccess(400) == false)
    #expect(HTTPStatus.isSuccess(500) == false)
}

@Test("HTTPStatus.isClientError identifies client error codes")
func testHTTPStatusIsClientError() {
    #expect(HTTPStatus.isClientError(400) == true)
    #expect(HTTPStatus.isClientError(401) == true)
    #expect(HTTPStatus.isClientError(404) == true)
    #expect(HTTPStatus.isClientError(429) == true)
    #expect(HTTPStatus.isClientError(499) == true)

    #expect(HTTPStatus.isClientError(200) == false)
    #expect(HTTPStatus.isClientError(300) == false)
    #expect(HTTPStatus.isClientError(500) == false)
}

@Test("HTTPStatus.isServerError identifies server error codes")
func testHTTPStatusIsServerError() {
    #expect(HTTPStatus.isServerError(500) == true)
    #expect(HTTPStatus.isServerError(502) == true)
    #expect(HTTPStatus.isServerError(503) == true)
    #expect(HTTPStatus.isServerError(504) == true)
    #expect(HTTPStatus.isServerError(599) == true)

    #expect(HTTPStatus.isServerError(200) == false)
    #expect(HTTPStatus.isServerError(400) == false)
    #expect(HTTPStatus.isServerError(600) == false)
}

@Test("HTTPStatus constants have correct values")
func testHTTPStatusConstants() {
    #expect(HTTPStatus.ok == 200)
    #expect(HTTPStatus.created == 201)
    #expect(HTTPStatus.noContent == 204)
    #expect(HTTPStatus.notModified == 304)
    #expect(HTTPStatus.badRequest == 400)
    #expect(HTTPStatus.unauthorized == 401)
    #expect(HTTPStatus.forbidden == 403)
    #expect(HTTPStatus.notFound == 404)
    #expect(HTTPStatus.tooManyRequests == 429)
    #expect(HTTPStatus.internalServerError == 500)
    #expect(HTTPStatus.badGateway == 502)
    #expect(HTTPStatus.serviceUnavailable == 503)
}
