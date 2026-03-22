// NetworkResponseMonitor.swift
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

// EventMonitor for intercepting all HTTP responses.

import Alamofire
import Foundation

// MARK: - NetworkResponseInfo

/// Information about an HTTP request and response.
///
/// Contains details about the request and response for any HTTP status code.
public struct NetworkResponseInfo: Sendable {
    /// The original URL request.
    public let request: URLRequest

    /// The HTTP response.
    public let response: HTTPURLResponse

    /// Optional response data from the server.
    public let responseData: Data?

    /// Optional error message extracted from response data.
    public let errorMessage: String?

    /// Creates network response information.
    ///
    /// - Parameters:
    ///   - request: The original URL request
    ///   - response: The HTTP response
    ///   - responseData: Optional response data
    ///   - errorMessage: Optional error message extracted from response
    public init(
        request: URLRequest,
        response: HTTPURLResponse,
        responseData: Data? = nil,
        errorMessage: String? = nil
    ) {
        self.request = request
        self.response = response
        self.responseData = responseData
        self.errorMessage = errorMessage
    }
}

// MARK: - NetworkResponseHandler

/// Protocol for handling HTTP responses.
///
/// Implement this protocol to receive notifications about all network responses.
/// This is useful for implementing global response handling, such as logging,
/// analytics, or custom response processing.
///
/// Example:
/// ```swift
/// class ResponseLogger: NetworkResponseHandler {
///     func onResponseReceived(_ info: NetworkResponseInfo) {
///         if info.response.statusCode == 401 {
///             // Handle 401
///             UserSession.shared.logout()
///         }
///         // Log all responses
///         print("Response: \(info.response.statusCode)")
///     }
/// }
///
/// let handler = ResponseLogger()
/// let config = NetworkClientConfiguration(
///     baseURL: "https://api.example.com",
///     networkResponseHandler: handler
/// )
/// let client = NetworkClient(configuration: config)
/// ```
public protocol NetworkResponseHandler: Sendable {
    /// Called when an HTTP response is received.
    ///
    /// This method is called asynchronously on a background queue and should
    /// not block the main thread. Use `Task { @MainActor in ... }` if you
    /// need to update UI.
    ///
    /// - Parameter info: Information about the request and response
    func onResponseReceived(_ info: NetworkResponseInfo)
}

// MARK: - NetworkResponseMonitor

/// EventMonitor that intercepts all HTTP responses and notifies handler.
///
/// This monitor observes all network responses and notifies the registered handler
/// for every response, regardless of status code. The handler can then perform
/// actions such as logging, analytics, or custom response processing.
///
/// The monitor is thread-safe and uses a serial dispatch queue for handler management.
///
/// Example:
/// ```swift
/// let handler = MyResponseHandler()
/// let monitor = NetworkResponseMonitor(handler: handler)
///
/// let config = NetworkClientConfiguration(
///     baseURL: "https://api.example.com",
///     eventMonitors: [monitor]
/// )
/// ```
public final class NetworkResponseMonitor: EventMonitor, @unchecked Sendable {
    // MARK: - Properties

    /// Dispatch queue for thread-safe handler management.
    public let queue: DispatchQueue

    /// Registered handler for network response events.
    private var handler: (any NetworkResponseHandler)?

    // MARK: - Initialization

    /// Creates a new network response monitor.
    ///
    /// - Parameter handler: Handler to notify when responses are received
    public init(handler: (any NetworkResponseHandler)? = nil) {
        self.handler = handler
        self.queue = DispatchQueue(
            label: "com.asc.networkResponseMonitor",
            qos: .utility
        )
    }

    // MARK: - EventMonitor

    /// Called when a DataRequest has parsed a response.
    ///
    /// This method intercepts all responses and notifies the registered handler
    /// for every response, regardless of status code.
    ///
    /// - Parameters:
    ///   - request: The DataRequest that received the response
    ///   - response: The parsed response containing status code and data
    public func request<Value>(
        _ request: DataRequest,
        didParseResponse response: DataResponse<Value, AFError>
    ) {
        guard
            let request = request.request,
            let httpResponse = response.response
        else {
            return
        }

        // Extract error message from response data if available
        let errorMessage = extractErrorMessage(from: response.data)

        // Create info object
        let info = NetworkResponseInfo(
            request: request,
            response: httpResponse,
            responseData: response.data,
            errorMessage: errorMessage
        )

        // Notify handler on the monitor's queue
        queue.async { [weak self] in
            guard let self = self else { return }
            self.handler?.onResponseReceived(info)
        }
    }

    // MARK: - Private Methods

    /// Extracts error message from response data.
    ///
    /// Delegates to `JSONMessageExtractor` which handles common server error formats.
    ///
    /// - Parameter data: Response data to parse
    /// - Returns: Extracted error message, or nil if parsing fails
    private func extractErrorMessage(from data: Data?) -> String? {
        JSONMessageExtractor.message(from: data)
    }
}
