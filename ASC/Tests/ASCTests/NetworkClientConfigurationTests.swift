// NetworkClientConfigurationTests.swift
// ASC Tests
// Tests for NetworkClientConfiguration.

@testable import ASC
import Foundation
import Testing

// MARK: - NetworkClientConfiguration Tests

@Test("NetworkClientConfiguration.default creates configuration with baseURL")
func testNetworkClientConfigurationDefault() {
    let config = NetworkClientConfiguration.default(baseURL: "https://api.example.com")

    #expect(config.baseURL == "https://api.example.com")
    #expect(config.defaultTimeout == 60.0)
    // defaultHeaders uses HTTPHeaders.default which includes Accept-Encoding, Accept-Language, User-Agent
    #expect(!config.defaultHeaders.isEmpty)
}

@Test("NetworkClientConfiguration can be created with custom parameters")
func testNetworkClientConfigurationFull() {
    let headers: HTTPHeaders = ["X-Custom": "Value"]
    let urlConfig = URLSessionConfiguration.default
    let rootQueue = DispatchQueue(label: "test.root")
    let requestQueue = DispatchQueue(label: "test.request")
    let serializationQueue = DispatchQueue(label: "test.serialization")

    let config = NetworkClientConfiguration(
        baseURL: "https://api.example.com",
        urlSessionConfiguration: urlConfig,
        defaultTimeout: 45.0,
        defaultCachePolicy: .reloadIgnoringLocalCacheData,
        defaultHeaders: headers,
        interceptors: [],
        eventMonitors: [],
        serverTrustManager: nil,
        redirectHandler: nil,
        cachedResponseHandler: nil,
        rootQueue: rootQueue,
        requestQueue: requestQueue,
        serializationQueue: serializationQueue
    )

    #expect(config.baseURL == "https://api.example.com")
    #expect(config.defaultTimeout == 45.0)
    #expect(config.defaultHeaders.count == 1)
    #expect(config.defaultCachePolicy == .reloadIgnoringLocalCacheData)
}

@Test("NetworkClientConfiguration has correct default values")
func testNetworkClientConfigurationDefaults() {
    let config = NetworkClientConfiguration(baseURL: "https://api.example.com")

    #expect(config.baseURL == "https://api.example.com")
    #expect(config.defaultTimeout == 60.0)  // Default is 60
    // defaultHeaders uses HTTPHeaders.default which is not empty
    #expect(!config.defaultHeaders.isEmpty)
    #expect(config.defaultCachePolicy == .useProtocolCachePolicy)
    #expect(config.interceptors.isEmpty)
    #expect(config.eventMonitors.isEmpty)
    #expect(config.serverTrustManager == nil)
    #expect(config.redirectHandler == nil)
    #expect(config.cachedResponseHandler == nil)
    // rootQueue, requestQueue, serializationQueue are not nil - they have default values
}
