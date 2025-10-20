// MockURLProtocol.swift
// ASC Tests
//
// Mock URL protocol for intercepting network requests in tests.

import Foundation

/// Mock URL protocol that intercepts network requests for testing.
///
/// This protocol allows tests to simulate various server responses
/// without making actual network calls.
public final class MockURLProtocol: URLProtocol {
    // MARK: - Mock Response Configuration

    /// Handler for incoming requests.
    nonisolated(unsafe) public static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data?))?

    /// Tracks all requests made during testing.
    nonisolated(unsafe) public static var requestHistory: [URLRequest] = []

    /// Returns the last request made, or nil if no requests have been made.
    public static var lastRequest: URLRequest? {
        requestHistory.last
    }

    /// Delay to simulate network latency.
    nonisolated(unsafe) public static var responseDelay: TimeInterval = 0.0

    // MARK: - URLProtocol Override

    override public class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override public class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override public func startLoading() {
        // Record the request
        Self.requestHistory.append(request)

        // Simulate network delay if configured
        if Self.responseDelay > 0 {
            Thread.sleep(forTimeInterval: Self.responseDelay)
        }

        guard let handler = Self.requestHandler else {
            let error = NSError(
                domain: "MockURLProtocol",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "No request handler configured"]
            )
            client?.urlProtocol(self, didFailWithError: error)
            return
        }

        do {
            let (response, data) = try handler(request)

            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)

            if let data = data {
                client?.urlProtocol(self, didLoad: data)
            }

            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override public func stopLoading() {
        // Nothing to stop in mock
    }

    // MARK: - Helper Methods

    /// Resets all mock state.
    public static func reset() {
        requestHandler = nil
        requestHistory.removeAll()
        responseDelay = 0.0
    }

    /// Creates a mock HTTP response.
    ///
    /// - Parameters:
    ///   - url: The URL for the response
    ///   - statusCode: HTTP status code
    ///   - headers: HTTP headers
    /// - Returns: HTTPURLResponse
    public static func mockResponse(
        url: URL,
        statusCode: Int,
        headers: [String: String]? = nil
    ) -> HTTPURLResponse {
        HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: headers
        )! // swiftlint:disable:this force_unwrapping
    }

    /// Creates a mock JSON response.
    ///
    /// - Parameters:
    ///   - url: The URL for the response
    ///   - statusCode: HTTP status code
    ///   - json: JSON dictionary
    /// - Returns: Tuple of (HTTPURLResponse, Data)
    public static func mockJSONResponse(
        url: URL,
        statusCode: Int,
        json: [String: Any]
    ) throws -> (HTTPURLResponse, Data) {
        let data = try JSONSerialization.data(withJSONObject: json)
        let response = mockResponse(
            url: url,
            statusCode: statusCode,
            headers: ["Content-Type": "application/json"]
        )
        return (response, data)
    }

    /// Creates a mock error response.
    ///
    /// - Parameter error: The error to return
    public static func mockError(_ error: Error) {
        requestHandler = { _ in
            throw error
        }
    }
}
