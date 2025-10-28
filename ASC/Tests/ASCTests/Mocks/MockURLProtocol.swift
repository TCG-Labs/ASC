// MockURLProtocol.swift
// ASC - Alamofire Swift Client

// Mock URLProtocol for testing network requests without actual HTTP calls.

import Foundation
import Synchronization

/// Mock URLProtocol that allows testing network requests without actual HTTP calls.
///
/// Usage:
/// ```swift
/// // Set up mock response
/// MockURLProtocol.mockResponse = (
///     data: mockData,
///     response: mockHTTPResponse,
///     error: nil
/// )
///
/// // Create configuration with mock protocol
/// let config = URLSessionConfiguration.ephemeral
/// config.protocolClasses = [MockURLProtocol.self]
///
/// // Use configuration in your tests
/// ```
final class MockURLProtocol: URLProtocol {
    // MARK: - Types

    /// Mock response data
    struct MockResponse: Sendable {
        let data: Data?
        let response: HTTPURLResponse?
        let error: Error?
    }

    // MARK: - Static Properties

    /// Current mock response to return
    private static let _mockResponse = Mutex<MockResponse?>(nil)
    static var mockResponse: MockResponse? {
        get { _mockResponse.withLock { $0 } }
        set { _mockResponse.withLock { $0 = newValue } }
    }

    /// Request handler closure for more complex scenarios
    private static let _requestHandler = Mutex<(@Sendable (URLRequest) throws -> MockResponse)?>(nil)
    static var requestHandler: (@Sendable (URLRequest) throws -> MockResponse)? {
        get { _requestHandler.withLock { $0 } }
        set { _requestHandler.withLock { $0 = newValue } }
    }

    // MARK: - URLProtocol Overrides

    override class func canInit(with request: URLRequest) -> Bool {
        // Handle all requests
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        // Get mock response
        if let handler = Self.requestHandler {
            do {
                let mock = try handler(request)
                sendMockResponse(mock)
            } catch {
                client?.urlProtocol(self, didFailWithError: error)
            }
        } else if let mock = Self.mockResponse {
            sendMockResponse(mock)
        } else {
            client?.urlProtocol(
                self,
                didFailWithError: NSError(
                    domain: "MockURLProtocol",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "No mock response configured"]
                )
            )
        }
    }

    override func stopLoading() {
        // Nothing to do
    }

    // MARK: - Helper Methods

    private func sendMockResponse(_ mock: MockResponse) {
        // Send error if present
        if let error = mock.error {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }

        // Send response
        if let response = mock.response {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }

        // Send data
        if let data = mock.data {
            client?.urlProtocol(self, didLoad: data)
        }

        // Finish loading
        client?.urlProtocolDidFinishLoading(self)
    }

    // MARK: - Test Helpers

    /// Resets all mock data
    static func reset() {
        mockResponse = nil
        requestHandler = nil
    }

    /// Sets a successful mock response with data
    static func setSuccessResponse(data: Data, statusCode: Int = 200, url: URL? = nil) {
        let url = url ?? URL(string: "https://api.example.com/test")!
        let response = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: nil
        )!

        mockResponse = MockResponse(
            data: data,
            response: response,
            error: nil
        )
    }

    /// Sets an error mock response
    static func setErrorResponse(_ error: Error) {
        mockResponse = MockResponse(
            data: nil,
            response: nil,
            error: error
        )
    }

    /// Sets a custom mock response
    static func setCustomResponse(data: Data?, response: HTTPURLResponse?, error: Error?) {
        mockResponse = MockResponse(
            data: data,
            response: response,
            error: error
        )
    }
}
