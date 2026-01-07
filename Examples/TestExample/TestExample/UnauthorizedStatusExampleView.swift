//
//  UnauthorizedStatusExampleView.swift
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

import SwiftUI
import ASC

// MARK: - Unauthorized Status Example View

/// View demonstrating network response handler functionality.
///
/// This view shows how to:
/// - Set up a NetworkClient with NetworkResponseHandler
/// - Handle all responses globally
/// - React to authentication failures (401 status)
struct UnauthorizedStatusExampleView: View {
    @StateObject private var viewModel = UnauthorizedStatusExampleViewModel()

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Status Section
                statusSection

                // MARK: - Actions Section
                actionsSection

                // MARK: - Last Response Event Section
                if let lastEvent = viewModel.lastResponseEvent {
                    lastEventSection(event: lastEvent)
                }

                // MARK: - Error Section
                if let errorMessage = viewModel.errorMessage {
                    errorSection(message: errorMessage)
                }
            }
            .navigationTitle("401 Status Demo")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Status Section

    private var statusSection: some View {
        Section("Status") {
            HStack {
                Text("Logged In")
                Spacer()
                Image(systemName: viewModel.isLoggedIn ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(viewModel.isLoggedIn ? .green : .red)
            }

            HStack {
                Text("401 Events Count")
                Spacer()
                Text("\(viewModel.unauthorizedEventCount)")
                    .foregroundColor(.secondary)
            }

            if viewModel.isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading...")
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        Section("Actions") {
            Button {
                Task {
                    await viewModel.makeRequestThatTriggers401()
                }
            } label: {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Make Request (401)")
                }
            }
            .disabled(viewModel.isLoading)

            Button {
                Task {
                    await viewModel.makeNormalRequest()
                }
            } label: {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Make Normal Request")
                }
            }
            .disabled(viewModel.isLoading)

            Button(role: .destructive) {
                viewModel.reset()
            } label: {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Reset")
                }
            }
            .disabled(viewModel.isLoading)
        }
    }

    // MARK: - Last Event Section

    private func lastEventSection(event: NetworkResponseInfo) -> some View {
        Section("Last Response Event") {
            if let url = event.request.url {
                LabeledContent("Request URL") {
                    Text(url.absoluteString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.trailing)
                }
            }

            LabeledContent("Status Code") {
                Text("\(event.response.statusCode)")
                    .foregroundColor(.red)
            }

            if let errorMessage = event.errorMessage {
                LabeledContent("Error Message") {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.trailing)
                }
            }

            if let responseData = event.responseData,
               let jsonString = String(data: responseData, encoding: .utf8) {
                LabeledContent("Response Data") {
                    Text(jsonString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.trailing)
                }
            }
        }
    }

    // MARK: - Error Section

    private func errorSection(message: String) -> some View {
        Section("Error") {
            Text(message)
                .foregroundColor(.red)
                .font(.caption)
        }
    }
}

// MARK: - Preview

#Preview {
    UnauthorizedStatusExampleView()
}

