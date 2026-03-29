//
//  UnauthorizedStatusExampleViewModel.swift
//  TestExample
//
//  Created on 06.01.2026.
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
import SwiftUI
import Combine
import ASC

// MARK: - Response Handler

/// Example handler that performs logout when 401 is received.
///
/// This demonstrates how to implement `NetworkResponseHandler` to handle
/// all network responses, with special handling for 401 status codes.
final class LogoutHandler: NetworkResponseHandler, @unchecked Sendable {
    /// Closure to call when response is received (for UI updates).
    var onResponseReceived: ((NetworkResponseInfo) -> Void)?

    /// Called when an HTTP response is received.
    ///
    /// In a real app, this would:
    /// - Check status code and handle 401 specifically
    /// - Clear user session on 401
    /// - Remove authentication tokens
    /// - Navigate to login screen
    /// - Show appropriate message to user
    func onResponseReceived(_ info: NetworkResponseInfo) {
        // Check if it's a 401 status
        if info.response.statusCode == HTTPStatus.unauthorized {
            // Extract error message if available
            let errorMessage = info.errorMessage ?? "Session expired"

            // Perform logout actions
            print("🔒 [LogoutHandler] Received 401 Unauthorized")
            print("   Request URL: \(info.request.url?.absoluteString ?? "unknown")")
            print("   Error message: \(errorMessage)")

            // In a real app, you would:
            // 1. Clear user session
            // UserSession.shared.logout()
            //
            // 2. Remove tokens
            // TokenStorage.shared.clear()
            //
            // 3. Navigate to login (on main thread)
            // Task { @MainActor in
            //     AppRouter.shared.navigateToLogin()
            // }
            //
            // 4. Show notification to user
            // NotificationCenter.default.post(
            //     name: .userLoggedOut,
            //     object: nil,
            //     userInfo: ["reason": "Session expired"]
            // )
        }

        // Notify ViewModel on main thread for all responses
        Task { @MainActor in
            onResponseReceived?(info)
        }
    }
}

// MARK: - Unauthorized Status Example ViewModel

/// ViewModel demonstrating 401 Unauthorized status listener functionality.
///
/// This ViewModel shows how to:
/// - Set up a NetworkClient with UnauthorizedStatusListener
/// - Handle 401 responses globally
/// - React to authentication failures
@MainActor
final class UnauthorizedStatusExampleViewModel: ObservableObject {
    // MARK: - Published Properties

    /// Whether user is logged in (for demo purposes).
    @Published var isLoggedIn = true

    /// Last response event information.
    @Published var lastResponseEvent: NetworkResponseInfo?

    /// Count of 401 events received.
    @Published var unauthorizedEventCount = 0

    /// Loading state.
    @Published var isLoading = false

    /// Error message.
    @Published var errorMessage: String?

    // MARK: - Private Properties

    /// Network client configured with logout handler (for JSONPlaceholder API).
    private let client: NetworkClient

    /// Network client for authentication API (for testing 401 status).
    private let authClient: NetworkClient

    /// Logout handler instance.
    private let logoutHandler: LogoutHandler

    // MARK: - Initialization

    /// Creates a new ViewModel with a NetworkClient configured for 401 handling.
    init() {
        // Create logout handler
        self.logoutHandler = LogoutHandler()

        // Create configuration for JSONPlaceholder API
        let config = NetworkClientConfiguration(
            baseURL: "https://jsonplaceholder.typicode.com",
            defaultTimeout: 30.0,
            eventMonitors: [NetworkResponseMonitor(handler: logoutHandler)],
            logLevel: .verbose,
            connectivityCheckEnabled: true
        )
        self.client = NetworkClient(configuration: config)

        // Create configuration for authentication API (for testing 401)
        let authConfig = NetworkClientConfiguration(
            baseURL: "https://dev.tidymind.my",
            defaultTimeout: 30.0,
            eventMonitors: [NetworkResponseMonitor(handler: logoutHandler)],
            logLevel: .verbose,
            connectivityCheckEnabled: true
        )
        self.authClient = NetworkClient(configuration: authConfig)

        // Set up handler to update ViewModel state when responses are received
        logoutHandler.onResponseReceived = { [weak self] info in
            guard let self = self else { return }
            self.lastResponseEvent = info

            // Check if it's a 401 status
            if info.response.statusCode == HTTPStatus.unauthorized {
                self.unauthorizedEventCount += 1
                self.isLoggedIn = false
            }
        }
    }

    // MARK: - Public Methods

    /// Makes a request that will trigger 401 (for demonstration).
    ///
    /// Uses real authentication API endpoint to test 401 status handling.
    /// The request will return 401 if credentials are invalid or expired.
    func makeRequestThatTriggers401() async {
        isLoading = true
        errorMessage = nil

        do {
            // Use real login endpoint - will return 401 if credentials are invalid
            let response = try await authClient.execute(LoginEndpoint(
                email: "example@mail.com",
                password: "Qwerty123"
            ))
            // If login succeeds, we got a valid response
            print("✅ [ViewModel] Login successful")
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            print("❌ [ViewModel] Unexpected error: \(error.localizedDescription)")
        }

        isLoading = false
    }

    /// Makes a normal request (should succeed).
    func makeNormalRequest() async {
        isLoading = true
        errorMessage = nil

        do {
            let users = try await client.execute(GetUsersEndpoint())
            print("✅ [ViewModel] Loaded \(users.count) users")
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    /// Resets the demo state.
    func reset() {
        isLoggedIn = true
        lastResponseEvent = nil
        unauthorizedEventCount = 0
        errorMessage = nil
    }

}
