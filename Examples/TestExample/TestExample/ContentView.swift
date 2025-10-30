//
//  ContentView.swift
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

// MARK: - Content View

struct ContentView: View {
    @State private var users: [User] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let networkClient: NetworkClient = .init(
        configuration: .init(
            baseURL: "https://jsonplaceholder.typicode.com",
            logLevel: .verbose,
            connectivityCheckEnabled: true
        )
    )

    var body: some View {
        NavigationStack {
            VStack {
                if isLoading {
                    ProgressView("Загрузка...")
                        .padding()
                } else if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                } else if users.isEmpty {
                    Text("Нажмите кнопку для загрузки пользователей")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    List(users) { user in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(user.name)
                                .font(.headline)
                            Text(user.email)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }

                Spacer()

                Button {
                    fetchUsers()
                } label: {
                    Label("Загрузить пользователей", systemImage: "arrow.down.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading)
                .padding()
            }
            .navigationTitle("ASC Test")
        }
    }

    private func fetchUsers() {
        Task {
            isLoading = true
            errorMessage = nil

            do {
                users = try await networkClient.execute(GetUsersRequest())
                debugPrint("✅ Загружено \(users.count) пользователей")
            } catch {
                errorMessage = "Ошибка: \(error.localizedDescription)"
                debugPrint("❌ Ошибка загрузки: \(error)")
            }

            isLoading = false
        }
    }
}

#Preview {
    ContentView()
}
