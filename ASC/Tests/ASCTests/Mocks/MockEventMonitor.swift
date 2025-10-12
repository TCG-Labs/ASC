// MockEventMonitor.swift
// ASC Tests
//
// Mock event monitor for testing request lifecycle observation.

import Alamofire
@testable import ASC
import Foundation

/// Mock event monitor for testing request lifecycle events.
public final class MockEventMonitor: EventMonitor, @unchecked Sendable {
    // MARK: - Properties

    /// Queue for event monitoring.
    public let queue = DispatchQueue(label: "com.asc.tests.mockEventMonitor")

    /// Events that have been recorded (private for thread safety).
    private var _events: [Event] = []

    /// Thread-safe access to events.
    public var events: [Event] {
        queue.sync { _events }
    }

    /// Event types that can be recorded.
    public enum Event {
        case requestDidResume(URL?)
        case requestDidCreateURLRequest(URL?)
        case requestDidComplete(URL?, String?) // Store error description instead of Error
        case requestDidFinish(URL?)
    }

    // MARK: - EventMonitor
    // Note: These methods are called by Alamofire on the queue, so no need to dispatch again

    public func requestDidResume(_ request: Request) {
        _events.append(.requestDidResume(request.request?.url))
    }

    public func request(_ request: Request, didCreateURLRequest urlRequest: URLRequest) {
        _events.append(.requestDidCreateURLRequest(urlRequest.url))
    }

    public func request(_ request: Request, didCompleteTask task: URLSessionTask, with error: (any Error)?) {
        _events.append(.requestDidComplete(task.currentRequest?.url, error?.localizedDescription))
    }

    public func requestDidFinish(_ request: Request) {
        _events.append(.requestDidFinish(request.request?.url))
    }

    // MARK: - Helper Methods

    /// Resets all recorded events.
    public func reset() {
        queue.sync { _events.removeAll() }
    }

    /// Checks if a specific event type was recorded.
    ///
    /// - Parameter checkEvent: Closure to match event
    /// - Returns: True if the event was recorded
    public func didRecordEvent(matching: (Event) -> Bool) -> Bool {
        queue.sync { _events.contains(where: matching) }
    }
}
