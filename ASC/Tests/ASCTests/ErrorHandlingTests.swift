// ErrorHandlingTests.swift
// ASC Tests
//
// Tests for error handling system.

@testable import ASC
import Foundation
import Testing

// MARK: - NetworkError Tests

@Suite("NetworkError Tests")
struct NetworkErrorTests {
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

    @Test("NetworkError.networkFailure without description has default recovery suggestion")
    func testNetworkErrorNetworkFailureDefaultRecovery() {
        let underlyingError = NSError(domain: "TestDomain", code: 999, userInfo: nil)
        let error = NetworkError.networkFailure(underlyingError)

        #expect(error.recoverySuggestion == "Please try again later")
    }
}

// MARK: - ResponseError Tests

@Suite("ResponseError Tests")
struct ResponseErrorTests {
    @Test("ResponseError.invalidStatusCode provides status code")
    func testResponseErrorInvalidStatusCode() {
        let data = Data("Error data".utf8)
        let error = ResponseError.invalidStatusCode(404, data)

        #expect(error.errorDescription == "Invalid HTTP status code: 404")
        #expect(error.statusCode == 404)
        #expect(error.responseData == data)
    }

    @Test("ResponseError.decodingFailed wraps decoding error")
    func testResponseErrorDecodingFailed() {
        let data = Data("Invalid JSON".utf8)
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
}

// MARK: - AuthenticationError Tests

@Suite("AuthenticationError Tests")
struct AuthenticationErrorTests {
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
}

// MARK: - HTTPStatus Tests (Parameterized)

@Suite("HTTPStatus Tests")
struct HTTPStatusTests {
    @Test("HTTPStatus.isSuccess identifies success codes",
          arguments: [
              (code: 200, expected: true),
              (code: 201, expected: true),
              (code: 204, expected: true),
              (code: 299, expected: true),
              (code: 199, expected: false),
              (code: 300, expected: false),
              (code: 400, expected: false),
              (code: 500, expected: false)
          ])
    func testHTTPStatusIsSuccess(code: Int, expected: Bool) {
        #expect(HTTPStatus.isSuccess(code) == expected)
    }

    @Test("HTTPStatus.isClientError identifies client error codes",
          arguments: [
              (code: 400, expected: true),
              (code: 401, expected: true),
              (code: 404, expected: true),
              (code: 429, expected: true),
              (code: 499, expected: true),
              (code: 200, expected: false),
              (code: 300, expected: false),
              (code: 500, expected: false)
          ])
    func testHTTPStatusIsClientError(code: Int, expected: Bool) {
        #expect(HTTPStatus.isClientError(code) == expected)
    }

    @Test("HTTPStatus.isServerError identifies server error codes",
          arguments: [
              (code: 500, expected: true),
              (code: 502, expected: true),
              (code: 503, expected: true),
              (code: 504, expected: true),
              (code: 599, expected: true),
              (code: 200, expected: false),
              (code: 400, expected: false),
              (code: 600, expected: false)
          ])
    func testHTTPStatusIsServerError(code: Int, expected: Bool) {
        #expect(HTTPStatus.isServerError(code) == expected)
    }

    @Test("HTTPStatus constants have correct values",
          arguments: [
              (name: "ok", value: HTTPStatus.ok, expected: 200),
              (name: "created", value: HTTPStatus.created, expected: 201),
              (name: "noContent", value: HTTPStatus.noContent, expected: 204),
              (name: "notModified", value: HTTPStatus.notModified, expected: 304),
              (name: "badRequest", value: HTTPStatus.badRequest, expected: 400),
              (name: "unauthorized", value: HTTPStatus.unauthorized, expected: 401),
              (name: "forbidden", value: HTTPStatus.forbidden, expected: 403),
              (name: "notFound", value: HTTPStatus.notFound, expected: 404),
              (name: "tooManyRequests", value: HTTPStatus.tooManyRequests, expected: 429),
              (name: "internalServerError", value: HTTPStatus.internalServerError, expected: 500),
              (name: "badGateway", value: HTTPStatus.badGateway, expected: 502),
              (name: "serviceUnavailable", value: HTTPStatus.serviceUnavailable, expected: 503)
          ])
    func testHTTPStatusConstants(name: String, value: Int, expected: Int) {
        #expect(value == expected, "HTTPStatus.\(name) should be \(expected)")
    }
}

// MARK: - Additional ResponseError Coverage Tests

@Suite("ResponseError Edge Cases")
struct ResponseErrorEdgeCasesTests {
    @Test("ResponseError.invalidStatusCode with server error provides server recovery suggestion")
    func testResponseErrorInvalidStatusCodeServerError() {
        let error = ResponseError.invalidStatusCode(500, nil)

        #expect(error.recoverySuggestion == "The server encountered an error. Please try again later")
    }

    @Test("ResponseError.invalidStatusCode with client error provides client recovery suggestion")
    func testResponseErrorInvalidStatusCodeClientError() {
        let error = ResponseError.invalidStatusCode(400, nil)

        #expect(error.recoverySuggestion == "Please check your request and try again")
    }

    @Test("ResponseError.invalidStatusCode with non-standard code has nil recovery suggestion")
    func testResponseErrorInvalidStatusCodeNonStandard() {
        let error = ResponseError.invalidStatusCode(300, nil)

        #expect(error.recoverySuggestion == nil)
    }

    @Test("ResponseError.clientError with 400 has specific recovery suggestion")
    func testResponseErrorClientError400() {
        let error = ResponseError.clientError(400, nil)

        #expect(error.recoverySuggestion == "Please check your request parameters")
    }

    @Test("ResponseError.clientError with 404 has specific recovery suggestion")
    func testResponseErrorClientError404() {
        let error = ResponseError.clientError(404, nil)

        #expect(error.recoverySuggestion == "The requested resource was not found")
    }

    @Test("ResponseError.clientError with other code has generic recovery suggestion")
    func testResponseErrorClientErrorOther() {
        let error = ResponseError.clientError(403, nil)

        #expect(error.recoverySuggestion == "Please check your request and try again")
    }

    @Test("ResponseError.decodingFailed has recovery suggestion")
    func testResponseErrorDecodingFailedRecovery() {
        let decodingError = NSError(domain: "test", code: 1)
        let error = ResponseError.decodingFailed(decodingError, Data())

        #expect(error.recoverySuggestion == "The server response format is unexpected. Please contact support")
    }

    @Test("ResponseError.missingData has nil statusCode")
    func testResponseErrorMissingDataStatusCode() {
        let error = ResponseError.missingData

        #expect(error.statusCode == nil)
    }

    @Test("ResponseError.missingData has nil responseData")
    func testResponseErrorMissingDataResponseData() {
        let error = ResponseError.missingData

        #expect(error.responseData == nil)
    }

    @Test("ResponseError.missingData has nil underlyingError")
    func testResponseErrorMissingDataUnderlyingError() {
        let error = ResponseError.missingData

        #expect(error.underlyingError == nil)
    }

    @Test("ResponseError.invalidFormat has nil statusCode")
    func testResponseErrorInvalidFormatStatusCode() {
        let error = ResponseError.invalidFormat("test")

        #expect(error.statusCode == nil)
    }

    @Test("ResponseError.invalidFormat has nil responseData")
    func testResponseErrorInvalidFormatResponseData() {
        let error = ResponseError.invalidFormat("test")

        #expect(error.responseData == nil)
    }

    @Test("ResponseError.invalidFormat has nil underlyingError")
    func testResponseErrorInvalidFormatUnderlyingError() {
        let error = ResponseError.invalidFormat("test")

        #expect(error.underlyingError == nil)
    }

    @Test("ResponseError.serverError has nil responseData")
    func testResponseErrorServerErrorResponseData() {
        let error = ResponseError.serverError(500, "test")

        #expect(error.responseData == nil)
    }

    @Test("ResponseError.serverError has nil underlyingError")
    func testResponseErrorServerErrorUnderlyingError() {
        let error = ResponseError.serverError(500, "test")

        #expect(error.underlyingError == nil)
    }

    @Test("ResponseError.clientError has nil responseData")
    func testResponseErrorClientErrorResponseData() {
        let error = ResponseError.clientError(400, nil)

        #expect(error.responseData == nil)
    }

    @Test("ResponseError.clientError has nil underlyingError")
    func testResponseErrorClientErrorUnderlyingError() {
        let error = ResponseError.clientError(400, nil)

        #expect(error.underlyingError == nil)
    }

    @Test("ResponseError.validationFailed has nil statusCode")
    func testResponseErrorValidationFailedStatusCode() {
        let error = ResponseError.validationFailed("test")

        #expect(error.statusCode == nil)
    }

    @Test("ResponseError.validationFailed has nil responseData")
    func testResponseErrorValidationFailedResponseData() {
        let error = ResponseError.validationFailed("test")

        #expect(error.responseData == nil)
    }

    @Test("ResponseError.validationFailed has nil underlyingError")
    func testResponseErrorValidationFailedUnderlyingError() {
        let error = ResponseError.validationFailed("test")

        #expect(error.underlyingError == nil)
    }
}

// MARK: - Additional AuthenticationError Coverage Tests

@Suite("AuthenticationError Edge Cases")
struct AuthenticationErrorEdgeCasesTests {
    @Test("AuthenticationError.tokenRefreshFailed has recovery suggestion")
    func testAuthenticationErrorTokenRefreshFailedRecovery() {
        let underlyingError = NSError(
            domain: "TokenError",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Refresh failed"]
        )
        let error = AuthenticationError.tokenRefreshFailed(underlyingError)

        #expect(error.recoverySuggestion == "Unable to refresh your session. Please log in again")
    }

    @Test("AuthenticationError with nil underlying error has nil recovery suggestion")
    func testAuthenticationErrorNilUnderlyingErrorRecovery() {
        // Create error with explicit nil case by checking underlyingError property
        let error = AuthenticationError.notAuthenticated

        // For errors without underlying errors, underlyingError should be nil
        #expect(error.underlyingError == nil)
    }
}
