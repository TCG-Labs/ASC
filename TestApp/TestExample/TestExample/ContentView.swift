//
//  ContentView.swift
//  TestExample
//
//  Created by Nikita Omelchenko on 25.10.2025.
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
