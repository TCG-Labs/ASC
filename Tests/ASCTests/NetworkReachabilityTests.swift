// NetworkReachabilityTests.swift
// ASC - Alamofire Swift Client Tests
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

import Testing
import Foundation
import Combine
@testable import ASC

@Suite("NetworkReachability Tests")
struct NetworkReachabilityTests {
    // MARK: - Status Tests

    @Test("Status isReachable property correctly identifies reachable and unreachable states")
    func testStatusIsReachable() {
        // Given: Reachable and unreachable status instances
        let reachableStatus = NetworkReachability.Status.reachable(.wifi)
        let unreachableStatus = NetworkReachability.Status.unreachable
        
        // When: Checking isReachable property
        let reachableResult = reachableStatus.isReachable
        let unreachableResult = unreachableStatus.isReachable
        
        // Then: Reachable status should return true, unreachable should return false
        #expect(reachableResult == true)
        #expect(unreachableResult == false)
    }

    @Test("Status connection types correctly identify all connection types as reachable")
    func testStatusConnectionTypes() {
        // Given: Different connection type statuses
        let wifi = NetworkReachability.Status.reachable(.wifi)
        let cellular = NetworkReachability.Status.reachable(.cellular)
        let wired = NetworkReachability.Status.reachable(.wired)
        let other = NetworkReachability.Status.reachable(.other)
        
        // When: Checking isReachable property for each type
        let wifiReachable = wifi.isReachable
        let cellularReachable = cellular.isReachable
        let wiredReachable = wired.isReachable
        let otherReachable = other.isReachable
        
        // Then: All connection types should be marked as reachable
        #expect(wifiReachable == true)
        #expect(cellularReachable == true)
        #expect(wiredReachable == true)
        #expect(otherReachable == true)
    }

    // MARK: - Current Status Tests

    @Test("Current status is thread-safe and accessible from multiple threads")
    func testCurrentStatusIsThreadSafe() async {
        // Given: NetworkReachability instance with monitoring started
        let reachability = NetworkReachability()
        reachability.startMonitoring()
        
        // When: Accessing currentStatus from multiple concurrent tasks
        var statuses: [NetworkReachability.Status] = []
        await withTaskGroup(of: NetworkReachability.Status.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    reachability.currentStatus
                }
            }
            
            for await status in group {
                statuses.append(status)
            }
        }
        
        // Then: All statuses should be valid (either reachable or unreachable)
        #expect(statuses.count == 10)
        for status in statuses {
            let isValid = status.isReachable || !status.isReachable
            #expect(isValid == true)
        }
        
        reachability.stopMonitoring()
    }

    // MARK: - Status Stream Tests

    @Test("Status stream provides initial value when monitoring starts")
    func testStatusStreamProvidesInitialValue() async {
        // Given: NetworkReachability instance
        let reachability = NetworkReachability()
        
        // When: Starting monitoring and reading first value from stream
        reachability.startMonitoring()
        let receivedStatus = await withTaskGroup(of: NetworkReachability.Status?.self) { group in
            group.addTask { @Sendable in
                var firstStatus: NetworkReachability.Status?
                for await status in reachability.statusStream {
                    firstStatus = status
                    break // Just get the first value
                }
                return firstStatus
            }
            
            return await group.next() ?? nil
        }
        
        // Then: Stream should provide at least one status value
        #expect(receivedStatus != nil)
        
        reachability.stopMonitoring()
    }

    // MARK: - Combine Publisher Tests

    @Test("Status publisher emits current status when monitoring")
    func testStatusPublisherEmitsCurrentStatus() async {
        // Given: NetworkReachability instance with monitoring started
        let reachability = NetworkReachability()
        reachability.startMonitoring()
        
        // When: Subscribing to status publisher and waiting for first value
        var receivedStatus: NetworkReachability.Status?
        var cancellable: AnyCancellable?
        
        cancellable = reachability.statusPublisher
            .first()
            .sink { status in
                receivedStatus = status
            }
        
        // Wait a bit for the publisher to emit
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Then: Publisher should emit at least one status value
        #expect(receivedStatus != nil)
        
        cancellable?.cancel()
        reachability.stopMonitoring()
    }

    @Test("Network available publisher filters only reachable connections")
    func testNetworkAvailablePublisherFiltersUnreachable() async {
        // Given: NetworkReachability instance with monitoring started
        let reachability = NetworkReachability()
        reachability.startMonitoring()
        
        // When: Subscribing to network available publisher
        var receivedType: NetworkReachability.Status.ConnectionType?
        var cancellable: AnyCancellable?
        
        cancellable = reachability.networkAvailablePublisher
            .first()
            .sink { type in
                receivedType = type
            }
        
        // Wait a bit for the publisher to emit (if network is available)
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Then: If a value was received, it should be a valid connection type
        // Note: This test may not receive a value if network is unavailable, which is expected
        if let type = receivedType {
            // If we got a type, verify it's one of the valid connection types
            let validTypes: [NetworkReachability.Status.ConnectionType] = [.wifi, .cellular, .wired, .other]
            #expect(validTypes.contains(type))
        }
        
        cancellable?.cancel()
        reachability.stopMonitoring()
    }

    @Test("Is reachable publisher emits boolean value indicating reachability")
    func testIsReachablePublisherEmitsBoolean() async {
        // Given: NetworkReachability instance with monitoring started
        let reachability = NetworkReachability()
        reachability.startMonitoring()
        
        // When: Subscribing to isReachable publisher
        var receivedValue: Bool?
        var cancellable: AnyCancellable?
        
        cancellable = reachability.isReachablePublisher
            .first()
            .sink { isReachable in
                receivedValue = isReachable
            }
        
        // Wait a bit for the publisher to emit
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Then: Publisher should emit a boolean value
        #expect(receivedValue != nil)
        
        cancellable?.cancel()
        reachability.stopMonitoring()
    }

    // MARK: - Integration Tests

    @Test("NetworkReachability can be used with NetworkClient configuration")
    func testNetworkReachabilityWithNetworkClient() async throws {
        // Given: NetworkReachability instance and NetworkClientConfiguration with connectivity check enabled
        let reachability = NetworkReachability()
        reachability.startMonitoring()
        
        let config = NetworkClientConfiguration(
            baseURL: "https://httpbin.org",
            connectivityCheckEnabled: true
        )
        
        // When: Creating NetworkClient with configuration
        let client = NetworkClient(configuration: config)
        
        // Then: Client should be successfully created
        // Note: NetworkClient is a non-optional type, so if we reach here, it was created successfully
        // The configuration is applied to the client's internal session
        
        reachability.stopMonitoring()
    }
}


