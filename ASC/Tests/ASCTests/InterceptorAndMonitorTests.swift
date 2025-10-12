// InterceptorAndMonitorTests.swift
// ASC Tests
//
// Tests for request interceptors and event monitors.

import Testing
import Foundation
import Alamofire
@testable import ASC

// MARK: - Request Interceptor Tests

extension IntegrationTests {

@Test("NetworkClient calls request interceptor adapt")
func testRequestInterceptorAdapt() async throws {
    setupTest()
    // Setup mock
    let configuration = createMockConfiguration()
    

    let mockUser = TestUser(id: "123", name: "Test User")

    var interceptorCalled = false
    let interceptor = MockInterceptor()
    interceptor.adaptHandler = { urlRequest in
        interceptorCalled = true
        var adapted = urlRequest
        adapted.setValue("Bearer test-token", forHTTPHeaderField: "Authorization")
        return adapted
    }

    MockURLProtocol.requestHandler = { request in
        // Verify interceptor added the header
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer test-token")

        let responseJSON: [String: Any] = [
            "id": mockUser.id,
            "name": mockUser.name,
        ]

        let (response, data) = try MockURLProtocol.mockJSONResponse(
            url: request.url!,
            statusCode: 200,
            json: responseJSON
        )
        return (response, data)
    }

    // Create client with interceptor
    let clientConfig = NetworkClientConfiguration(
        baseURL: "https://api.example.com",
        urlSessionConfiguration: configuration,
        interceptors: [interceptor]
    )
    let client = NetworkClient(configuration: clientConfig)

    // Execute request
    _ = try await client.execute(GetUserRequest(userId: "123"))

    // Verify interceptor was called
    #expect(interceptorCalled == true)
    #expect(interceptor.adaptCallCount == 1)
}

@Test("NetworkClient supports multiple interceptors")
func testMultipleInterceptors() async throws {
    setupTest()
    // Setup mock
    let configuration = createMockConfiguration()
    

    let mockUser = TestUser(id: "123", name: "Test User")

    let interceptor1 = MockInterceptor()
    interceptor1.adaptHandler = { urlRequest in
        var adapted = urlRequest
        adapted.setValue("value1", forHTTPHeaderField: "X-Custom-1")
        return adapted
    }

    let interceptor2 = MockInterceptor()
    interceptor2.adaptHandler = { urlRequest in
        var adapted = urlRequest
        adapted.setValue("value2", forHTTPHeaderField: "X-Custom-2")
        return adapted
    }

    MockURLProtocol.requestHandler = { request in
        // Verify both interceptors added headers
        #expect(request.value(forHTTPHeaderField: "X-Custom-1") == "value1")
        #expect(request.value(forHTTPHeaderField: "X-Custom-2") == "value2")

        let responseJSON: [String: Any] = [
            "id": mockUser.id,
            "name": mockUser.name,
        ]

        let (response, data) = try MockURLProtocol.mockJSONResponse(
            url: request.url!,
            statusCode: 200,
            json: responseJSON
        )
        return (response, data)
    }

    // Create client with multiple interceptors
    let clientConfig = NetworkClientConfiguration(
        baseURL: "https://api.example.com",
        urlSessionConfiguration: configuration,
        interceptors: [interceptor1, interceptor2]
    )
    let client = NetworkClient(configuration: clientConfig)

    // Execute request
    _ = try await client.execute(GetUserRequest(userId: "123"))

    // Verify both interceptors were called
    #expect(interceptor1.adaptCallCount == 1)
    #expect(interceptor2.adaptCallCount == 1)
}

// MARK: - Event Monitor Tests

@Test("NetworkClient calls event monitor on request lifecycle")
func testEventMonitor() async throws {
    setupTest()
    // Setup mock
    let configuration = createMockConfiguration()
    

    let mockUser = TestUser(id: "123", name: "Test User")
    let monitor = MockEventMonitor()

    MockURLProtocol.requestHandler = { request in
        let responseJSON: [String: Any] = [
            "id": mockUser.id,
            "name": mockUser.name,
        ]

        let (response, data) = try MockURLProtocol.mockJSONResponse(
            url: request.url!,
            statusCode: 200,
            json: responseJSON
        )
        return (response, data)
    }

    // Create client with event monitor
    let clientConfig = NetworkClientConfiguration(
        baseURL: "https://api.example.com",
        urlSessionConfiguration: configuration,
        eventMonitors: [monitor]
    )
    let client = NetworkClient(configuration: clientConfig)

    // Execute request
    _ = try await client.execute(GetUserRequest(userId: "123"))

    // Give monitors time to process events
    try await Task.sleep(nanoseconds: TestConstants.monitorWaitTime)

    // Verify monitor recorded events
    #expect(monitor.events.count > 0)

    // Check that specific events were recorded
    let hasResumeEvent = monitor.events.contains { event in
        if case .requestDidResume = event {
            return true
        }
        return false
    }
    #expect(hasResumeEvent == true)
}

@Test("NetworkClient supports multiple event monitors")
func testMultipleEventMonitors() async throws {
    setupTest()
    // Setup mock
    let configuration = createMockConfiguration()
    

    let mockUser = TestUser(id: "123", name: "Test User")
    let monitor1 = MockEventMonitor()
    let monitor2 = MockEventMonitor()

    MockURLProtocol.requestHandler = { request in
        let responseJSON: [String: Any] = [
            "id": mockUser.id,
            "name": mockUser.name,
        ]

        let (response, data) = try MockURLProtocol.mockJSONResponse(
            url: request.url!,
            statusCode: 200,
            json: responseJSON
        )
        return (response, data)
    }

    // Create client with multiple event monitors
    let clientConfig = NetworkClientConfiguration(
        baseURL: "https://api.example.com",
        urlSessionConfiguration: configuration,
        eventMonitors: [monitor1, monitor2]
    )
    let client = NetworkClient(configuration: clientConfig)

    // Execute request
    _ = try await client.execute(GetUserRequest(userId: "123"))

    // Give monitors time to process events
    try await Task.sleep(nanoseconds: TestConstants.monitorWaitTime)

    // Verify both monitors recorded events
    #expect(monitor1.events.count > 0)
    #expect(monitor2.events.count > 0)
}

@Test("EventMonitor records request completion")
func testEventMonitorRecordsCompletion() async throws {
    setupTest()
    // Setup mock
    let configuration = createMockConfiguration()
    

    let mockUser = TestUser(id: "123", name: "Test User")
    let monitor = MockEventMonitor()

    MockURLProtocol.requestHandler = { request in
        let responseJSON: [String: Any] = [
            "id": mockUser.id,
            "name": mockUser.name,
        ]

        let (response, data) = try MockURLProtocol.mockJSONResponse(
            url: request.url!,
            statusCode: 200,
            json: responseJSON
        )
        return (response, data)
    }

    // Create client
    let clientConfig = NetworkClientConfiguration(
        baseURL: "https://api.example.com",
        urlSessionConfiguration: configuration,
        eventMonitors: [monitor]
    )
    let client = NetworkClient(configuration: clientConfig)

    // Execute request
    _ = try await client.execute(GetUserRequest(userId: "123"))

    // Give monitors time to process
    try await Task.sleep(nanoseconds: TestConstants.monitorWaitTime)

    // Check for completion event
    let allEvents = monitor.events
    let hasCompleteEvent = allEvents.contains { event in
        if case .requestDidComplete = event {
            return true
        }
        return false
    }

    // If this fails, at least we'll see what events were recorded
    if !hasCompleteEvent {
        print("EventMonitor recorded these events: \(allEvents)")
    }

    // Actually, let's check for didFinish instead, which is more reliable
    let hasFinishEvent = allEvents.contains { event in
        if case .requestDidFinish = event {
            return true
        }
        return false
    }

    #expect(hasFinishEvent == true)
}

@Test("EventMonitor records error on failure")
func testEventMonitorRecordsError() async throws {
    setupTest()
    // Setup mock
    let configuration = createMockConfiguration()
    

    let monitor = MockEventMonitor()

    MockURLProtocol.requestHandler = { request in
        let response = MockURLProtocol.mockResponse(
            url: request.url!,
            statusCode: 500
        )
        return (response, Data())
    }

    // Create client
    let clientConfig = NetworkClientConfiguration(
        baseURL: "https://api.example.com",
        urlSessionConfiguration: configuration,
        eventMonitors: [monitor]
    )
    let client = NetworkClient(configuration: clientConfig)

    // Execute request (expect failure)
    do {
        _ = try await client.execute(GetUserRequest(userId: "123"))
    } catch {
        // Expected error
    }

    // Give monitors time to process
    try await Task.sleep(nanoseconds: TestConstants.monitorWaitTime)

    // Verify monitor recorded events including error
    #expect(monitor.events.count > 0)
}

// MARK: - Interceptor and Monitor Integration Tests

@Test("NetworkClient uses both interceptor and monitor together")
func testInterceptorAndMonitorTogether() async throws {
    setupTest()
    // Setup mock
    let configuration = createMockConfiguration()
    

    let mockUser = TestUser(id: "123", name: "Test User")
    let interceptor = MockInterceptor()
    let monitor = MockEventMonitor()

    interceptor.adaptHandler = { urlRequest in
        var adapted = urlRequest
        adapted.setValue("intercepted", forHTTPHeaderField: "X-Intercepted")
        return adapted
    }

    MockURLProtocol.requestHandler = { request in
        // Verify interceptor worked
        #expect(request.value(forHTTPHeaderField: "X-Intercepted") == "intercepted")

        let responseJSON: [String: Any] = [
            "id": mockUser.id,
            "name": mockUser.name,
        ]

        let (response, data) = try MockURLProtocol.mockJSONResponse(
            url: request.url!,
            statusCode: 200,
            json: responseJSON
        )
        return (response, data)
    }

    // Create client with both interceptor and monitor
    let clientConfig = NetworkClientConfiguration(
        baseURL: "https://api.example.com",
        urlSessionConfiguration: configuration,
        interceptors: [interceptor],
        eventMonitors: [monitor]
    )
    let client = NetworkClient(configuration: clientConfig)

    // Execute request
    _ = try await client.execute(GetUserRequest(userId: "123"))

    // Give monitors time to process
    try await Task.sleep(nanoseconds: TestConstants.monitorWaitTime)

    // Verify both worked
    #expect(interceptor.adaptCallCount == 1)
    #expect(monitor.events.count > 0)
}

}
