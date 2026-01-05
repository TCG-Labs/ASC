//
//  DIContainer.swift
//  TestExample
//
//  Created on 05.01.2026.
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

import Foundation
import ASC

// MARK: - Env

/// Application environment for network client configuration.
enum Env: String, CaseIterable {
    case production
    case staging
    case development
}

// MARK: - DIContainer

/// Simple dependency injection container for managing NetworkClient instances.
///
/// Provides registration and retrieval of NetworkClient instances for different environments.
/// This allows easy switching between production, staging, and development configurations.
final class DIContainer {
    // MARK: - Properties

    /// Shared singleton instance.
    static let shared = DIContainer()

    /// Current environment (defaults to development).
    var currentEnvironment: Env = .development

    /// Registered clients by environment.
    private var clients: [Env: NetworkClient] = [:]

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// Registers a NetworkClient for a specific environment.
    ///
    /// - Parameters:
    ///   - environment: The environment to register the client for
    ///   - configuration: The configuration to use for creating the client
    func registerClient(
        for environment: Env,
        configuration: NetworkClientConfiguration
    ) {
        clients[environment] = NetworkClient(configuration: configuration)
    }

    /// Retrieves a NetworkClient for a specific environment.
    ///
    /// - Parameter environment: The environment to get the client for
    /// - Returns: The registered NetworkClient for the environment, or nil if not registered
    func client(for environment: Env) -> NetworkClient? {
        clients[environment]
    }

    /// Retrieves the default NetworkClient for the current environment.
    ///
    /// - Returns: The NetworkClient for the current environment
    /// - Throws: Fatal error if no client is registered for the current environment
    func defaultClient() -> NetworkClient {
        guard let client = clients[currentEnvironment] else {
            fatalError("No NetworkClient registered for environment: \(currentEnvironment.rawValue)")
        }
        return client
    }
}

