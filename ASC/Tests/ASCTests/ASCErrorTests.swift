// ASCErrorTests.swift
// ASC - Alamofire Swift Client Tests

import Testing
import Foundation
@testable import ASC

struct ASCErrorTests {
    // MARK: - Network Errors

    @Test("No connection error description")
    func testNoConnectionError() {
        let error = ASCError.noConnection

        #expect(error.errorDescription == "No internet connection")
        #expect(error.recoverySuggestion == "Check your internet connection")
        #expect(error.statusCode == nil)
    }

    @Test("Timeout error with interval")
    func testTimeoutError() {
        let error = ASCError.timeout(30.0)

        #expect(error.errorDescription == "Request timed out after 30.0s")
        #expect(error.recoverySuggestion == "Try again or check your connection")
    }

    @Test("Host unreachable error")
    func testHostUnreachableError() {
        let error = ASCError.hostUnreachable("api.example.com")

        #expect(error.errorDescription == "Cannot reach host: api.example.com")
        #expect(error.recoverySuggestion == "Check the server address")
    }

    @Test("Certificate validation failed")
    func testCertificateValidationFailed() {
        let error = ASCError.certificateValidationFailed("Invalid certificate chain")

        #expect(error.errorDescription == "Certificate validation failed: Invalid certificate chain")
        #expect(error.recoverySuggestion == "Verify the server's SSL certificate")
    }

    @Test("Request cancelled error")
    func testCancelledError() {
        let error = ASCError.cancelled

        #expect(error.errorDescription == "Request cancelled")
        #expect(error.recoverySuggestion == nil)
    }

    @Test("Network failure with underlying error")
    func testNetworkFailureError() {
        struct TestError: Error {}
        let underlyingError = TestError()
        let error = ASCError.networkFailure(underlyingError)

        #expect(error.errorDescription?.contains("Network error") == true)
        #expect(error.recoverySuggestion == "Try again later")
        #expect(error.underlyingError != nil)
    }

    // MARK: - Response Errors

    @Test("Invalid status code error")
    func testInvalidStatusCodeError() {
        let data = Data("error".utf8)
        let error = ASCError.invalidStatusCode(404, data)

        #expect(error.errorDescription == "Invalid HTTP status code: 404")
        #expect(error.statusCode == 404)
        #expect(error.responseData == data)
    }

    @Test("Server error with status code and message")
    func testServerError() {
        let error = ASCError.serverError(500, "Internal server error")

        #expect(error.errorDescription == "Server error (500): Internal server error")
        #expect(error.recoverySuggestion == "Server error, try again later")
        #expect(error.statusCode == 500)
    }

    @Test("Client error with status code")
    func testClientErrorWithMessage() {
        let error = ASCError.clientError(400, "Bad request")

        #expect(error.errorDescription == "Client error (400): Bad request")
        #expect(error.statusCode == 400)
    }

    @Test("Client error without message")
    func testClientErrorWithoutMessage() {
        let error = ASCError.clientError(404, nil)

        #expect(error.errorDescription == "Client error (404)")
    }

    @Test("Decoding failed error")
    func testDecodingFailedError() {
        struct TestError: Error {}
        let data = Data("invalid json".utf8)
        let error = ASCError.decodingFailed(TestError(), data)

        #expect(error.errorDescription?.contains("Failed to decode response") == true)
        #expect(error.recoverySuggestion == "Unexpected server response format")
        #expect(error.responseData == data)
        #expect(error.underlyingError != nil)
    }

    @Test("Missing data error")
    func testMissingDataError() {
        let error = ASCError.missingData

        #expect(error.errorDescription == "Response data is missing")
        #expect(error.recoverySuggestion == "Expected data from server")
    }

    @Test("Invalid format error")
    func testInvalidFormatError() {
        let error = ASCError.invalidFormat("Expected JSON array")

        #expect(error.errorDescription == "Invalid response format: Expected JSON array")
        #expect(error.recoverySuggestion == "Invalid server response format")
    }

    @Test("Validation failed error")
    func testValidationFailedError() {
        let error = ASCError.validationFailed("Email is required")

        #expect(error.errorDescription == "Response validation failed: Email is required")
        #expect(error.recoverySuggestion == "Verify the response data")
    }

    // MARK: - Authentication Errors

    @Test("Not authenticated error")
    func testNotAuthenticatedError() {
        let error = ASCError.notAuthenticated

        #expect(error.errorDescription == "Not authenticated")
        #expect(error.recoverySuggestion == "Please log in")
    }

    @Test("Token expired error")
    func testTokenExpiredError() {
        let error = ASCError.tokenExpired

        #expect(error.errorDescription == "Authentication token expired")
        #expect(error.recoverySuggestion == "Session expired, log in again")
    }

    @Test("Invalid token error")
    func testInvalidTokenError() {
        let error = ASCError.invalidToken

        #expect(error.errorDescription == "Authentication token is invalid")
        #expect(error.recoverySuggestion == "Session invalid, log in again")
    }

    @Test("Token refresh failed error")
    func testTokenRefreshFailedError() {
        struct TestError: Error {}
        let error = ASCError.tokenRefreshFailed(TestError())

        #expect(error.errorDescription?.contains("Failed to refresh token") == true)
        #expect(error.recoverySuggestion == "Unable to refresh session, log in again")
        #expect(error.underlyingError != nil)
    }

    @Test("Unauthorized error with resource")
    func testUnauthorizedWithResource() {
        let error = ASCError.unauthorized("/admin/users")

        #expect(error.errorDescription == "Unauthorized access to: /admin/users")
        #expect(error.recoverySuggestion == "You don't have permission")
    }

    @Test("Unauthorized error without resource")
    func testUnauthorizedWithoutResource() {
        let error = ASCError.unauthorized(nil)

        #expect(error.errorDescription == "Unauthorized access")
    }

    @Test("Forbidden error with reason")
    func testForbiddenWithReason() {
        let error = ASCError.forbidden("Insufficient privileges")

        #expect(error.errorDescription == "Access forbidden: Insufficient privileges")
        #expect(error.recoverySuggestion == "Action not allowed")
    }

    @Test("Forbidden error without reason")
    func testForbiddenWithoutReason() {
        let error = ASCError.forbidden(nil)

        #expect(error.errorDescription == "Access forbidden")
    }

    @Test("Invalid credentials with reason")
    func testInvalidCredentialsWithReason() {
        let error = ASCError.invalidCredentials("Wrong password")

        #expect(error.errorDescription == "Invalid credentials: Wrong password")
        #expect(error.recoverySuggestion == "Check your credentials")
    }

    @Test("Invalid credentials without reason")
    func testInvalidCredentialsWithoutReason() {
        let error = ASCError.invalidCredentials(nil)

        #expect(error.errorDescription == "Invalid credentials")
    }

    // MARK: - Helper Properties

    @Test("Failure reason matches error description")
    func testFailureReasonMatchesDescription() {
        let error = ASCError.noConnection

        #expect(error.failureReason == error.errorDescription)
    }

    @Test("Status code extraction from various errors")
    func testStatusCodeExtraction() {
        let error1 = ASCError.invalidStatusCode(404, nil)
        let error2 = ASCError.serverError(500, "Error")
        let error3 = ASCError.clientError(400, nil)
        let error4 = ASCError.noConnection

        #expect(error1.statusCode == 404)
        #expect(error2.statusCode == 500)
        #expect(error3.statusCode == 400)
        #expect(error4.statusCode == nil)
    }

    @Test("Response data extraction")
    func testResponseDataExtraction() {
        let data = Data("test".utf8)
        let error1 = ASCError.invalidStatusCode(404, data)
        let error2 = ASCError.decodingFailed(NSError(domain: "test", code: 0), data)
        let error3 = ASCError.noConnection

        #expect(error1.responseData == data)
        #expect(error2.responseData == data)
        #expect(error3.responseData == nil)
    }
}
