//
//  TestExampleApp.swift
//  TestExample
//
//  Created by Nikita Omelchenko on 25.10.2025.
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

import SwiftUI
import ASC

@main
struct TestExampleApp: App {
    init() {
        setupDIContainer()
    }

    var body: some Scene {
        WindowGroup {
            TabView {
                // Tab 1: Users
                ContentView()
                    .tabItem {
                        Label("Users", systemImage: "person.2")
                    }

                // Tab 2: 401 Demo
                UnauthorizedStatusExampleView()
                    .tabItem {
                        Label("401 Demo", systemImage: "lock.shield")
                    }
            }
        }
    }

    // MARK: - Private Methods

    /// Configures the DI container with NetworkClient instances for different environments.
    private func setupDIContainer() {
        let container = DIContainer.shared

        // Production environment - minimal logging, optimized for performance
        container.registerClient(
            for: .production,
            configuration: NetworkClientConfiguration(
                baseURL: "https://jsonplaceholder.typicode.com",
                defaultTimeout: 30.0,
                logLevel: .error,
                connectivityCheckEnabled: true
            )
        )

        // Staging environment - info level logging for debugging
        container.registerClient(
            for: .staging,
            configuration: NetworkClientConfiguration(
                baseURL: "https://jsonplaceholder.typicode.com",
                defaultTimeout: 30.0,
                logLevel: .info,
                connectivityCheckEnabled: true
            )
        )

        // Development environment - verbose logging for detailed debugging
        // Also includes NetworkResponseHandler example
        let logoutHandler = LogoutHandler()
        container.registerClient(
            for: .development,
            configuration: NetworkClientConfiguration(
                baseURL: "https://jsonplaceholder.typicode.com",
                defaultTimeout: 30.0,
                eventMonitors: [NetworkResponseMonitor(handler: logoutHandler)],
                logLevel: .verbose,
                connectivityCheckEnabled: true
            )
        )

        // Set default environment
        container.currentEnvironment = .development
    }
}
