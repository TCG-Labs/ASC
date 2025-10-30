// ErrorMapperTests.swift
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

// Tests for ErrorMapper functionality.

import Foundation
import Testing
@testable import ASC

@Suite("ErrorMapper Tests")
struct ErrorMapperTests {
    let mapper = ErrorMapper(defaultTimeout: 60)

    // MARK: - AFError Mapping

    @Test("Map explicitly cancelled error")
    func testMapExplicitlyCancelledError() {
        let error = AFError.explicitlyCancelled
        let mappedError = mapper.mapError(error, data: nil)

        #expect(mappedError is CancellationError)
    }

    @Test("Map network failure error")
    func testMapNetworkFailureError() {
        let underlyingError = NSError(domain: "test", code: 123)
        let afError = AFError.sessionTaskFailed(error: underlyingError)
        let mappedError = mapper.mapError(afError, data: nil)

        guard let ascError = mappedError as? ASCError else {
            Issue.record("Expected ASCError")
            return
        }

        if case .networkFailure(let wrappedError) = ascError {
            // Verify it's an AFError wrapping our original error
            #expect(wrappedError is AFError)
        } else {
            Issue.record("Expected ASCError.networkFailure, got \(ascError)")
        }
    }

    // MARK: - URLError Mapping

    @Test("Map not connected to internet error")
    func testMapNotConnectedToInternetError() {
        let urlError = TestHelpers.createURLError(.notConnectedToInternet)
        let afError = TestHelpers.createAFErrorWithURLError(urlError)
        let mappedError = mapper.mapError(afError, data: nil)

        guard let ascError = mappedError as? ASCError else {
            Issue.record("Expected ASCError")
            return
        }

        if case .noConnection = ascError {
            // Success
        } else {
            Issue.record("Expected ASCError.noConnection, got \(ascError)")
        }
    }

    @Test("Map network connection lost error")
    func testMapNetworkConnectionLostError() {
        let urlError = TestHelpers.createURLError(.networkConnectionLost)
        let afError = TestHelpers.createAFErrorWithURLError(urlError)
        let mappedError = mapper.mapError(afError, data: nil)

        guard let ascError = mappedError as? ASCError else {
            Issue.record("Expected ASCError")
            return
        }

        if case .noConnection = ascError {
            // Success
        } else {
            Issue.record("Expected ASCError.noConnection, got \(ascError)")
        }
    }

    @Test("Map timed out error")
    func testMapTimedOutError() {
        let urlError = TestHelpers.createURLError(.timedOut)
        let afError = TestHelpers.createAFErrorWithURLError(urlError)
        let mappedError = mapper.mapError(afError, data: nil)

        guard let ascError = mappedError as? ASCError else {
            Issue.record("Expected ASCError")
            return
        }

        if case .timeout(let timeout) = ascError {
            #expect(timeout == 60)
        } else {
            Issue.record("Expected ASCError.timeout, got \(ascError)")
        }
    }

    @Test("Map cannot find host error")
    func testMapCannotFindHostError() {
        let urlError = TestHelpers.createURLError(.cannotFindHost)
        let afError = TestHelpers.createAFErrorWithURLError(urlError)
        let mappedError = mapper.mapError(afError, data: nil)

        guard let ascError = mappedError as? ASCError else {
            Issue.record("Expected ASCError")
            return
        }

        if case .hostUnreachable = ascError {
            // Success
        } else {
            Issue.record("Expected ASCError.hostUnreachable, got \(ascError)")
        }
    }

    @Test("Map cannot connect to host error")
    func testMapCannotConnectToHostError() {
        let urlError = TestHelpers.createURLError(.cannotConnectToHost)
        let afError = TestHelpers.createAFErrorWithURLError(urlError)
        let mappedError = mapper.mapError(afError, data: nil)

        guard let ascError = mappedError as? ASCError else {
            Issue.record("Expected ASCError")
            return
        }

        if case .hostUnreachable = ascError {
            // Success
        } else {
            Issue.record("Expected ASCError.hostUnreachable, got \(ascError)")
        }
    }

    @Test("Map server certificate untrusted error")
    func testMapServerCertificateUntrustedError() {
        let urlError = TestHelpers.createURLError(.serverCertificateUntrusted)
        let afError = TestHelpers.createAFErrorWithURLError(urlError)
        let mappedError = mapper.mapError(afError, data: nil)

        guard let ascError = mappedError as? ASCError else {
            Issue.record("Expected ASCError")
            return
        }

        if case .certificateValidationFailed = ascError {
            // Success
        } else {
            Issue.record("Expected ASCError.certificateValidationFailed, got \(ascError)")
        }
    }

    @Test("Map server certificate has unknown root error")
    func testMapServerCertificateHasUnknownRootError() {
        let urlError = TestHelpers.createURLError(.serverCertificateHasUnknownRoot)
        let afError = TestHelpers.createAFErrorWithURLError(urlError)
        let mappedError = mapper.mapError(afError, data: nil)

        guard let ascError = mappedError as? ASCError else {
            Issue.record("Expected ASCError")
            return
        }

        if case .certificateValidationFailed = ascError {
            // Success
        } else {
            Issue.record("Expected ASCError.certificateValidationFailed, got \(ascError)")
        }
    }

    @Test("Map cancelled URLError")
    func testMapCancelledURLError() {
        let urlError = TestHelpers.createURLError(.cancelled)
        let afError = TestHelpers.createAFErrorWithURLError(urlError)
        let mappedError = mapper.mapError(afError, data: nil)

        guard let ascError = mappedError as? ASCError else {
            Issue.record("Expected ASCError")
            return
        }

        if case .cancelled = ascError {
            // Success
        } else {
            Issue.record("Expected ASCError.cancelled, got \(ascError)")
        }
    }

    @Test("Map generic URLError")
    func testMapGenericURLError() {
        let urlError = TestHelpers.createURLError(.badURL)
        let afError = TestHelpers.createAFErrorWithURLError(urlError)
        let mappedError = mapper.mapError(afError, data: nil)

        guard let ascError = mappedError as? ASCError else {
            Issue.record("Expected ASCError")
            return
        }

        if case .networkFailure = ascError {
            // Success
        } else {
            Issue.record("Expected ASCError.networkFailure, got \(ascError)")
        }
    }

    // MARK: - Validation Errors

    @Test("Map validation failure with unacceptable status code - client error")
    func testMapValidationFailureForClientError() {
        let afError = TestHelpers.createValidationError(statusCode: 400)
        let errorData = TestHelpers.createJSONData(["error": "Bad request"])
        let mappedError = mapper.mapError(afError, data: errorData)

        guard let ascError = mappedError as? ASCError else {
            Issue.record("Expected ASCError")
            return
        }

        if case .clientError(let code, let message) = ascError {
            #expect(code == 400)
            #expect(message == "Bad request")
        } else {
            Issue.record("Expected ASCError.clientError, got \(ascError)")
        }
    }

    @Test("Map validation failure with unacceptable status code - unauthorized")
    func testMapValidationFailureForUnauthorized() {
        let afError = TestHelpers.createValidationError(statusCode: 401)
        let mappedError = mapper.mapError(afError, data: nil)

        guard let ascError = mappedError as? ASCError else {
            Issue.record("Expected ASCError")
            return
        }

        if case .clientError(let code, let message) = ascError {
            #expect(code == 401)
            #expect(message == "Unauthorized")
        } else {
            Issue.record("Expected ASCError.clientError, got \(ascError)")
        }
    }

    @Test("Map validation failure with unacceptable status code - server error")
    func testMapValidationFailureForServerError() {
        let afError = TestHelpers.createValidationError(statusCode: 500)
        let errorData = TestHelpers.createJSONData(["error": "Internal server error"])
        let mappedError = mapper.mapError(afError, data: errorData)

        guard let ascError = mappedError as? ASCError else {
            Issue.record("Expected ASCError")
            return
        }

        if case .serverError(let code, let message) = ascError {
            #expect(code == 500)
            #expect(message == "Internal server error")
        } else {
            Issue.record("Expected ASCError.serverError, got \(ascError)")
        }
    }

    @Test("Map validation failure for success code")
    func testMapValidationFailureForSuccessCode() {
        let afError = TestHelpers.createValidationError(statusCode: 200)
        let mappedError = mapper.mapError(afError, data: nil)

        guard let ascError = mappedError as? ASCError else {
            Issue.record("Expected ASCError")
            return
        }

        if case .invalidStatusCode(let code, _) = ascError {
            #expect(code == 200)
        } else {
            Issue.record("Expected ASCError.invalidStatusCode, got \(ascError)")
        }
    }

    @Test("Map validation failure without status code")
    func testMapValidationFailureWithoutStatusCode() {
        let afError = AFError.responseValidationFailed(reason: .customValidationFailed(error: NSError(domain: "test", code: 1)))
        let mappedError = mapper.mapError(afError, data: nil)

        guard let ascError = mappedError as? ASCError else {
            Issue.record("Expected ASCError")
            return
        }

        if case .validationFailed = ascError {
            // Success
        } else {
            Issue.record("Expected ASCError.validationFailed, got \(ascError)")
        }
    }

    // MARK: - Serialization Errors

    @Test("Map decoding failed error")
    func testMapDecodingFailedError() {
        struct TestError: Error {}
        let decodingError = TestError()
        let afError = TestHelpers.createDecodingError(decodingError)
        let data = TestHelpers.createJSONData(["id": 1])
        let mappedError = mapper.mapError(afError, data: data)

        guard let ascError = mappedError as? ASCError else {
            Issue.record("Expected ASCError")
            return
        }

        if case .decodingFailed(_, let responseData) = ascError {
            #expect(responseData == data)
        } else {
            Issue.record("Expected ASCError.decodingFailed, got \(ascError)")
        }
    }

    @Test("Map input data nil error")
    func testMapInputDataNilError() {
        let afError = AFError.responseSerializationFailed(reason: .inputDataNilOrZeroLength)
        let mappedError = mapper.mapError(afError, data: nil)

        guard let ascError = mappedError as? ASCError else {
            Issue.record("Expected ASCError")
            return
        }

        if case .missingData = ascError {
            // Success
        } else {
            Issue.record("Expected ASCError.missingData, got \(ascError)")
        }
    }

    @Test("Map generic serialization error")
    func testMapGenericSerializationError() {
        let afError = AFError.responseSerializationFailed(reason: .inputFileReadFailed(at: URL(fileURLWithPath: "/test")))
        let mappedError = mapper.mapError(afError, data: nil)

        guard let ascError = mappedError as? ASCError else {
            Issue.record("Expected ASCError")
            return
        }

        if case .invalidFormat = ascError {
            // Success
        } else {
            Issue.record("Expected ASCError.invalidFormat, got \(ascError)")
        }
    }

    // MARK: - Error Message Extraction

    @Test("Extract error message from simple JSON")
    func testExtractErrorMessageFromSimpleJSON() {
        let afError = TestHelpers.createValidationError(statusCode: 400)
        let errorData = TestHelpers.createJSONData(["message": "Invalid request"])
        let mappedError = mapper.mapError(afError, data: errorData)

        guard let ascError = mappedError as? ASCError else {
            Issue.record("Expected ASCError")
            return
        }

        if case .clientError(_, let message) = ascError {
            #expect(message == "Invalid request")
        } else {
            Issue.record("Expected ASCError.clientError, got \(ascError)")
        }
    }

    @Test("Extract error message from error key")
    func testExtractErrorMessageFromErrorKey() {
        let afError = TestHelpers.createValidationError(statusCode: 400)
        let errorData = TestHelpers.createJSONData(["error": "Something went wrong"])
        let mappedError = mapper.mapError(afError, data: errorData)

        guard let ascError = mappedError as? ASCError else {
            Issue.record("Expected ASCError")
            return
        }

        if case .clientError(_, let message) = ascError {
            #expect(message == "Something went wrong")
        } else {
            Issue.record("Expected ASCError.clientError, got \(ascError)")
        }
    }

    @Test("Extract error message from nested JSON")
    func testExtractErrorMessageFromNestedJSON() {
        let afError = TestHelpers.createValidationError(statusCode: 400)
        let errorData = TestHelpers.createJSONData([
            "error": ["message": "Nested error message"]
        ])
        let mappedError = mapper.mapError(afError, data: errorData)

        guard let ascError = mappedError as? ASCError else {
            Issue.record("Expected ASCError")
            return
        }

        if case .clientError(_, let message) = ascError {
            #expect(message == "Nested error message")
        } else {
            Issue.record("Expected ASCError.clientError, got \(ascError)")
        }
    }

    @Test("Extract error message from array JSON")
    func testExtractErrorMessageFromArrayJSON() {
        let afError = TestHelpers.createValidationError(statusCode: 400)
        let errorData = TestHelpers.createJSONData([
            "errors": ["First error", "Second error"]
        ])
        let mappedError = mapper.mapError(afError, data: errorData)

        guard let ascError = mappedError as? ASCError else {
            Issue.record("Expected ASCError")
            return
        }

        if case .clientError(_, let message) = ascError {
            #expect(message == "First error")
        } else {
            Issue.record("Expected ASCError.clientError, got \(ascError)")
        }
    }

    @Test("Extract error message from error_description key")
    func testExtractErrorMessageFromErrorDescriptionKey() {
        let afError = TestHelpers.createValidationError(statusCode: 400)
        let errorData = TestHelpers.createJSONData(["error_description": "Detailed error"])
        let mappedError = mapper.mapError(afError, data: errorData)

        guard let ascError = mappedError as? ASCError else {
            Issue.record("Expected ASCError")
            return
        }

        if case .clientError(_, let message) = ascError {
            #expect(message == "Detailed error")
        } else {
            Issue.record("Expected ASCError.clientError, got \(ascError)")
        }
    }

    @Test("Extract error message from detail key (Django REST Framework)")
    func testExtractErrorMessageFromDetailKey() {
        let afError = TestHelpers.createValidationError(statusCode: 400)
        let errorData = TestHelpers.createJSONData(["detail": "Not found"])
        let mappedError = mapper.mapError(afError, data: errorData)

        guard let ascError = mappedError as? ASCError else {
            Issue.record("Expected ASCError")
            return
        }

        if case .clientError(_, let message) = ascError {
            #expect(message == "Not found")
        } else {
            Issue.record("Expected ASCError.clientError, got \(ascError)")
        }
    }

    @Test("Handle no data when extracting error message")
    func testExtractErrorMessageWhenNoData() {
        let afError = TestHelpers.createValidationError(statusCode: 400)
        let mappedError = mapper.mapError(afError, data: nil)

        guard let ascError = mappedError as? ASCError else {
            Issue.record("Expected ASCError")
            return
        }

        if case .clientError(_, let message) = ascError {
            #expect(message == nil)
        } else {
            Issue.record("Expected ASCError.clientError, got \(ascError)")
        }
    }

    @Test("Handle invalid JSON when extracting error message")
    func testExtractErrorMessageWhenInvalidJSON() {
        let afError = TestHelpers.createValidationError(statusCode: 400)
        let invalidData = "Invalid JSON".data(using: .utf8)!
        let mappedError = mapper.mapError(afError, data: invalidData)

        guard let ascError = mappedError as? ASCError else {
            Issue.record("Expected ASCError")
            return
        }

        if case .clientError(_, let message) = ascError {
            #expect(message == nil)
        } else {
            Issue.record("Expected ASCError.clientError, got \(ascError)")
        }
    }

    @Test("Handle empty data when extracting error message")
    func testExtractErrorMessageWhenEmptyData() {
        let afError = TestHelpers.createValidationError(statusCode: 400)
        let emptyData = Data()
        let mappedError = mapper.mapError(afError, data: emptyData)

        guard let ascError = mappedError as? ASCError else {
            Issue.record("Expected ASCError")
            return
        }

        if case .clientError(_, let message) = ascError {
            #expect(message == nil)
        } else {
            Issue.record("Expected ASCError.clientError, got \(ascError)")
        }
    }
}
