// ErrorMapperTests.swift
// ASC Tests
// Tests for ErrorMapper internal component.

import Alamofire
@testable import ASC
import Foundation
import Testing

// MARK: - ErrorMapper Tests

@Test("ErrorMapper maps URLError.notConnectedToInternet to NetworkError.noConnection")
func testErrorMapperURLErrorNoConnection() {
    let mapper = ErrorMapper(defaultTimeout: 30.0)
    let urlError = URLError(.notConnectedToInternet)
    let afError = AFError.sessionTaskFailed(error: urlError)

    let mappedError = mapper.mapError(afError, data: nil)

    guard let networkError = mappedError as? NetworkError else {
        Issue.record("Expected NetworkError")
        return
    }

    if case .noConnection = networkError {
        // Success
    } else {
        Issue.record("Expected noConnection, got \(networkError)")
    }
}

@Test("ErrorMapper maps URLError.networkConnectionLost to NetworkError.noConnection")
func testErrorMapperURLErrorNetworkConnectionLost() {
    let mapper = ErrorMapper(defaultTimeout: 30.0)
    let urlError = URLError(.networkConnectionLost)
    let afError = AFError.sessionTaskFailed(error: urlError)

    let mappedError = mapper.mapError(afError, data: nil)

    guard let networkError = mappedError as? NetworkError else {
        Issue.record("Expected NetworkError")
        return
    }

    if case .noConnection = networkError {
        // Success
    } else {
        Issue.record("Expected noConnection, got \(networkError)")
    }
}

@Test("ErrorMapper maps URLError.timedOut to NetworkError.timeout")
func testErrorMapperURLErrorTimedOut() {
    let mapper = ErrorMapper(defaultTimeout: 30.0)
    let urlError = URLError(.timedOut)
    let afError = AFError.sessionTaskFailed(error: urlError)

    let mappedError = mapper.mapError(afError, data: nil)

    guard let networkError = mappedError as? NetworkError else {
        Issue.record("Expected NetworkError")
        return
    }

    if case .timeout(let duration) = networkError {
        #expect(duration == 30.0)
    } else {
        Issue.record("Expected timeout, got \(networkError)")
    }
}

@Test("ErrorMapper maps URLError.cannotFindHost to NetworkError.hostUnreachable")
func testErrorMapperURLErrorCannotFindHost() {
    let mapper = ErrorMapper(defaultTimeout: 30.0)
    let urlError = URLError(.cannotFindHost)
    let afError = AFError.sessionTaskFailed(error: urlError)

    let mappedError = mapper.mapError(afError, data: nil)

    guard let networkError = mappedError as? NetworkError else {
        Issue.record("Expected NetworkError")
        return
    }

    if case .hostUnreachable = networkError {
        // Success
    } else {
        Issue.record("Expected hostUnreachable, got \(networkError)")
    }
}

@Test("ErrorMapper maps URLError.cannotConnectToHost to NetworkError.hostUnreachable")
func testErrorMapperURLErrorCannotConnectToHost() {
    let mapper = ErrorMapper(defaultTimeout: 30.0)
    let urlError = URLError(.cannotConnectToHost)
    let afError = AFError.sessionTaskFailed(error: urlError)

    let mappedError = mapper.mapError(afError, data: nil)

    guard let networkError = mappedError as? NetworkError else {
        Issue.record("Expected NetworkError")
        return
    }

    if case .hostUnreachable = networkError {
        // Success
    } else {
        Issue.record("Expected hostUnreachable, got \(networkError)")
    }
}

@Test("ErrorMapper maps URLError.serverCertificateUntrusted to NetworkError.certificateValidationFailed")
func testErrorMapperURLErrorCertificateUntrusted() {
    let mapper = ErrorMapper(defaultTimeout: 30.0)
    let urlError = URLError(.serverCertificateUntrusted)
    let afError = AFError.sessionTaskFailed(error: urlError)

    let mappedError = mapper.mapError(afError, data: nil)

    guard let networkError = mappedError as? NetworkError else {
        Issue.record("Expected NetworkError")
        return
    }

    if case .certificateValidationFailed = networkError {
        // Success
    } else {
        Issue.record("Expected certificateValidationFailed, got \(networkError)")
    }
}

@Test("ErrorMapper maps URLError.serverCertificateHasUnknownRoot to NetworkError.certificateValidationFailed")
func testErrorMapperURLErrorCertificateUnknownRoot() {
    let mapper = ErrorMapper(defaultTimeout: 30.0)
    let urlError = URLError(.serverCertificateHasUnknownRoot)
    let afError = AFError.sessionTaskFailed(error: urlError)

    let mappedError = mapper.mapError(afError, data: nil)

    guard let networkError = mappedError as? NetworkError else {
        Issue.record("Expected NetworkError")
        return
    }

    if case .certificateValidationFailed = networkError {
        // Success
    } else {
        Issue.record("Expected certificateValidationFailed, got \(networkError)")
    }
}

@Test("ErrorMapper maps URLError.cancelled to NetworkError.cancelled")
func testErrorMapperURLErrorCancelled() {
    let mapper = ErrorMapper(defaultTimeout: 30.0)
    let urlError = URLError(.cancelled)
    let afError = AFError.sessionTaskFailed(error: urlError)

    let mappedError = mapper.mapError(afError, data: nil)

    guard let networkError = mappedError as? NetworkError else {
        Issue.record("Expected NetworkError")
        return
    }

    if case .cancelled = networkError {
        // Success
    } else {
        Issue.record("Expected cancelled, got \(networkError)")
    }
}

@Test("ErrorMapper maps unknown URLError to NetworkError.networkFailure")
func testErrorMapperURLErrorUnknown() {
    let mapper = ErrorMapper(defaultTimeout: 30.0)
    let urlError = URLError(.badURL)  // Not in the switch cases
    let afError = AFError.sessionTaskFailed(error: urlError)

    let mappedError = mapper.mapError(afError, data: nil)

    guard let networkError = mappedError as? NetworkError else {
        Issue.record("Expected NetworkError")
        return
    }

    if case .networkFailure = networkError {
        // Success
    } else {
        Issue.record("Expected networkFailure, got \(networkError)")
    }
}

@Test("ErrorMapper maps validation failure 401 to ResponseError.clientError")
func testErrorMapperValidationFailure401() {
    let mapper = ErrorMapper(defaultTimeout: 30.0)
    let afError = AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 401))

    let mappedError = mapper.mapError(afError, data: nil)

    guard let responseError = mappedError as? ResponseError else {
        Issue.record("Expected ResponseError")
        return
    }

    if case .clientError(let code, let message) = responseError {
        #expect(code == 401)
        #expect(message == "Unauthorized")
    } else {
        Issue.record("Expected clientError, got \(responseError)")
    }
}

@Test("ErrorMapper maps validation failure 500 to ResponseError.serverError")
func testErrorMapperValidationFailure500() {
    let mapper = ErrorMapper(defaultTimeout: 30.0)
    let afError = AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 500))

    let mappedError = mapper.mapError(afError, data: nil)

    guard let responseError = mappedError as? ResponseError else {
        Issue.record("Expected ResponseError")
        return
    }

    if case .serverError(let code, _) = responseError {
        #expect(code == 500)
    } else {
        Issue.record("Expected serverError, got \(responseError)")
    }
}

@Test("ErrorMapper maps validation failure 503 to ResponseError.serverError")
func testErrorMapperValidationFailure503() {
    let mapper = ErrorMapper(defaultTimeout: 30.0)
    let afError = AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 503))

    let mappedError = mapper.mapError(afError, data: nil)

    guard let responseError = mappedError as? ResponseError else {
        Issue.record("Expected ResponseError")
        return
    }

    if case .serverError(let code, _) = responseError {
        #expect(code == 503)
    } else {
        Issue.record("Expected serverError, got \(responseError)")
    }
}

@Test("ErrorMapper maps validation failure 400 to ResponseError.clientError")
func testErrorMapperValidationFailure400() {
    let mapper = ErrorMapper(defaultTimeout: 30.0)
    let afError = AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 400))

    let mappedError = mapper.mapError(afError, data: nil)

    guard let responseError = mappedError as? ResponseError else {
        Issue.record("Expected ResponseError")
        return
    }

    if case .clientError(let code, let message) = responseError {
        #expect(code == 400)
        #expect(message == nil)
    } else {
        Issue.record("Expected clientError, got \(responseError)")
    }
}

@Test("ErrorMapper maps validation failure 404 to ResponseError.clientError")
func testErrorMapperValidationFailure404() {
    let mapper = ErrorMapper(defaultTimeout: 30.0)
    let afError = AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 404))

    let mappedError = mapper.mapError(afError, data: nil)

    guard let responseError = mappedError as? ResponseError else {
        Issue.record("Expected ResponseError")
        return
    }

    if case .clientError(let code, let message) = responseError {
        #expect(code == 404)
        #expect(message == nil)
    } else {
        Issue.record("Expected clientError, got \(responseError)")
    }
}

@Test("ErrorMapper maps validation failure 300 to ResponseError.invalidStatusCode")
func testErrorMapperValidationFailure300() {
    let mapper = ErrorMapper(defaultTimeout: 30.0)
    let testData = Data("test".utf8)
    let afError = AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 300))

    let mappedError = mapper.mapError(afError, data: testData)

    guard let responseError = mappedError as? ResponseError else {
        Issue.record("Expected ResponseError")
        return
    }

    if case .invalidStatusCode(let code, let data) = responseError {
        #expect(code == 300)
        #expect(data == testData)
    } else {
        Issue.record("Expected invalidStatusCode, got \(responseError)")
    }
}

@Test("ErrorMapper maps serialization decodingFailed to ResponseError.decodingFailed")
func testErrorMapperSerializationDecodingFailed() {
    let mapper = ErrorMapper(defaultTimeout: 30.0)
    let testData = Data("invalid json".utf8)
    let decodingError = NSError(domain: "DecodingError", code: 1)
    let afError = AFError.responseSerializationFailed(reason: .decodingFailed(error: decodingError))

    let mappedError = mapper.mapError(afError, data: testData)

    guard let responseError = mappedError as? ResponseError else {
        Issue.record("Expected ResponseError")
        return
    }

    if case .decodingFailed(_, let data) = responseError {
        #expect(data == testData)
    } else {
        Issue.record("Expected decodingFailed, got \(responseError)")
    }
}

@Test("ErrorMapper maps serialization inputDataNilOrZeroLength to ResponseError.missingData")
func testErrorMapperSerializationNoData() {
    let mapper = ErrorMapper(defaultTimeout: 30.0)
    let afError = AFError.responseSerializationFailed(reason: .inputDataNilOrZeroLength)

    let mappedError = mapper.mapError(afError, data: nil)

    guard let responseError = mappedError as? ResponseError else {
        Issue.record("Expected ResponseError")
        return
    }

    if case .missingData = responseError {
        // Success
    } else {
        Issue.record("Expected missingData, got \(responseError)")
    }
}

@Test("ErrorMapper maps serialization invalidEmptyResponse to ResponseError.invalidFormat")
func testErrorMapperSerializationInvalidEmptyResponse() {
    let mapper = ErrorMapper(defaultTimeout: 30.0)
    let afError = AFError.responseSerializationFailed(reason: .invalidEmptyResponse(type: "application/json"))

    let mappedError = mapper.mapError(afError, data: nil)

    guard let responseError = mappedError as? ResponseError else {
        Issue.record("Expected ResponseError")
        return
    }

    if case .invalidFormat = responseError {
        // Success
    } else {
        Issue.record("Expected invalidFormat, got \(responseError)")
    }
}

@Test("ErrorMapper maps non-URLError without special cases to NetworkError.networkFailure")
func testErrorMapperGenericAFError() {
    let mapper = ErrorMapper(defaultTimeout: 30.0)
    let afError = AFError.explicitlyCancelled

    let mappedError = mapper.mapError(afError, data: nil)

    guard let networkError = mappedError as? NetworkError else {
        Issue.record("Expected NetworkError")
        return
    }

    if case .networkFailure = networkError {
        // Success
    } else {
        Issue.record("Expected networkFailure, got \(networkError)")
    }
}
