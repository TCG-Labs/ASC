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

// MARK: - Navigation Destination

private enum NavigationDestination: Hashable {
    case uploadFile
}

// MARK: - Content View

struct ContentView: View {
    @StateObject private var viewModel = UsersViewModel()
    @State private var selectedEnvironment: Env = DIContainer.shared.currentEnvironment
    @State private var showingCreateUser = false
    @State private var networkStatus: NetworkReachability.Status = .unreachable
    @State private var monitoringTask: Task<Void, Never>?
    
    private let reachability = NetworkReachability()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Environment selector
                environmentSelector

                // Main content
                if viewModel.isLoading {
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = viewModel.errorMessage {
                    errorView(error)
                } else if viewModel.users.isEmpty {
                    emptyStateView
                } else {
                    usersListView
                }
            }
            .navigationTitle("ASC Demo")
            .toolbar {
                if #available(iOS 26.0, *) {
                    ToolbarItem(placement: .navigationBarLeading) {
                        NetworkStatusView(status: networkStatus)
                            .fixedSize()
                    }
                    .sharedBackgroundVisibility(.hidden)
                } else {
                    ToolbarItem(placement: .navigationBarLeading) {
                        NetworkStatusView(status: networkStatus)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingCreateUser = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .navigationDestination(for: NavigationDestination.self) { destination in
                switch destination {
                case .uploadFile:
                    FileUploadView(viewModel: viewModel)
                }
            }
            .sheet(isPresented: $showingCreateUser) {
                CreateUserView(viewModel: viewModel)
            }
            .onAppear {
                reachability.startMonitoring()
                networkStatus = reachability.currentStatus
                monitoringTask = Task {
                    for await status in reachability.statusStream {
                        await MainActor.run {
                            networkStatus = status
                        }
                    }
                }
            }
            .onDisappear {
                monitoringTask?.cancel()
                monitoringTask = nil
                reachability.stopMonitoring()
            }
        }
    }

    // MARK: - Environment Selector

    private var environmentSelector: some View {
        Picker("Environment", selection: $selectedEnvironment) {
            ForEach(Env.allCases, id: \.self) { environment in
                Text(environment.rawValue.capitalized).tag(environment)
            }
        }
        .pickerStyle(.segmented)
        .padding()
        .onChange(of: selectedEnvironment) { _, newValue in
            DIContainer.shared.currentEnvironment = newValue
            // Recreate ViewModel with new client
            Task { @MainActor in
                viewModel.clearSelection()
                if let client = DIContainer.shared.client(for: newValue) {
                    // Note: In a real app, you'd want to recreate the ViewModel
                    // For this demo, we'll just reload users
                    await viewModel.loadUsers()
                }
            }
        }
    }

    // MARK: - Error View

    private func errorView(_ error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.red)
            Text(error)
                .foregroundColor(.red)
                .multilineTextAlignment(.center)
                .padding()
            Button("Retry") {
                Task {
                    await viewModel.loadUsers()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.3")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            Text("No users loaded")
                .foregroundColor(.gray)
            Button("Load Users") {
                Task {
                    await viewModel.loadUsers()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Users List View

    private var usersListView: some View {
        List {
            NavigationLink(value: NavigationDestination.uploadFile) {
                HStack {
                    Image(systemName: "arrow.up.doc")
                    Text("Upload File")
                }
            }
            
            ForEach(viewModel.users) { user in
                NavigationLink {
                    UserDetailView(user: user, viewModel: viewModel)
                } label: {
                    UserRowView(user: user)
                }
            }
        }
        .refreshable {
            await viewModel.loadUsers()
        }
    }
}

// MARK: - Network Status View

private struct NetworkStatusView: View {
    let status: NetworkReachability.Status

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .foregroundColor(iconColor)
            Text(statusText)
                .font(.caption)
                .foregroundColor(textColor)
        }
    }

    private var iconName: String {
        switch status {
        case .reachable(.wifi):
            return "wifi"
        case .reachable(.cellular):
            return "antenna.radiowaves.left.and.right"
        case .reachable(.wired):
            return "cable.connector"
        case .reachable(.other):
            return "network"
        case .unreachable:
            return "wifi.slash"
        }
    }

    private var statusText: String {
        switch status {
        case .reachable(.wifi):
            return "WiFi"
        case .reachable(.cellular):
            return "Cellular"
        case .reachable(.wired):
            return "Wired"
        case .reachable(.other):
            return "Online"
        case .unreachable:
            return "Offline"
        }
    }

    private var iconColor: Color {
        switch status {
        case .unreachable:
            return .red
        default:
            return .primary
        }
    }

    private var textColor: Color {
        switch status {
        case .unreachable:
            return .red
        default:
            return .secondary
        }
    }
}

// MARK: - User Row View

private struct UserRowView: View {
    let user: User

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(user.name)
                .font(.headline)
            Text(user.email)
                .font(.subheadline)
                .foregroundColor(.secondary)
            if let website = user.website {
                Text(website)
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - User Detail View

private struct UserDetailView: View {
    let user: User
    @ObservedObject var viewModel: UsersViewModel

    var body: some View {
        List {
            Section("User Info") {
                LabeledContent("Name", value: user.name)
                LabeledContent("Username", value: user.username)
                LabeledContent("Email", value: user.email)
                if let phone = user.phone {
                    LabeledContent("Phone", value: phone)
                }
                if let website = user.website {
                    LabeledContent("Website", value: website)
                }
            }

            Section("Posts") {
                if viewModel.userPosts.isEmpty {
                    Button("Load Posts") {
                        Task {
                            await viewModel.loadUserPosts()
                        }
                    }
                } else {
                    ForEach(viewModel.userPosts) { post in
                        NavigationLink {
                            PostDetailView(post: post, viewModel: viewModel)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(post.title)
                                    .font(.headline)
                                Text(post.body)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(user.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if viewModel.selectedUser?.id != user.id {
                Task {
                    await viewModel.loadUser(id: user.id)
                    await viewModel.loadUserPosts()
                }
            }
        }
    }
}

// MARK: - Post Detail View

private struct PostDetailView: View {
    let post: Post
    @ObservedObject var viewModel: UsersViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteConfirmation = false

    var body: some View {
        List {
            Section("Post") {
                Text(post.title)
                    .font(.headline)
                Text(post.body)
                    .padding(.top, 4)
            }

            Section("Comments") {
                if viewModel.postComments.isEmpty {
                    Button("Load Comments") {
                        Task {
                            await viewModel.loadPostComments(postId: post.id)
                        }
                    }
                } else {
                    ForEach(viewModel.postComments) { comment in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(comment.name)
                                .font(.headline)
                            Text(comment.email)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(comment.body)
                                .padding(.top, 4)
                        }
                    }
                }
            }
        }
        .navigationTitle("Post")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .confirmationDialog(
            "Delete Post",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deletePost(postId: post.id)
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this post? This action cannot be undone.")
        }
        .onAppear {
            Task {
                await viewModel.loadPostComments(postId: post.id)
            }
        }
    }
}

// MARK: - File Upload View

private struct FileUploadView: View {
    @ObservedObject var viewModel: UsersViewModel
    @State private var selectedFileData: Data?
    @State private var selectedFileName: String?

    var body: some View {
        Form {
            Section("Upload File") {
                Button("Select File") {
                    // Создаем тестовый файл для демонстрации
                    createTestFile()
                }

                if let fileName = selectedFileName {
                    Text("Selected: \(fileName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Button("Upload File") {
                    guard let data = selectedFileData,
                          let fileName = selectedFileName else {
                        return
                    }
                    Task {
                        await viewModel.uploadFile(
                            data: data,
                            fileName: fileName,
                            mimeType: "text/plain"
                        )
                    }
                }
                .disabled(selectedFileData == nil || viewModel.isLoading)
            }

            if let result = viewModel.uploadResult {
                Section("Upload Result") {
                    Text("ID: \(result.id)")
                    if let url = result.url {
                        Text("URL: \(url)")
                            .font(.caption)
                    }
                    if let filename = result.filename {
                        Text("Filename: \(filename)")
                            .font(.caption)
                    }
                }
            }

            if let error = viewModel.errorMessage {
                Section("Error") {
                    Text(error)
                        .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("Upload File")
    }

    private func createTestFile() {
        let content = "Test file content\nCreated at \(Date())"
        selectedFileData = content.data(using: .utf8)
        selectedFileName = "test_\(UUID().uuidString.prefix(8)).txt"
    }
}

// MARK: - Create User View

private struct CreateUserView: View {
    @ObservedObject var viewModel: UsersViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var username = ""
    @State private var email = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("User Information") {
                    TextField("Name", text: $name)
                    TextField("Username", text: $username)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
            }
            .navigationTitle("Create User")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task {
                            await viewModel.createUser(name: name, username: username, email: email)
                            dismiss()
                        }
                    }
                    .disabled(name.isEmpty || username.isEmpty || email.isEmpty)
                }
            }
        }
    }
}

struct NewView: View {
    var body: some View {
        Text("hello")
    }
}

#Preview {
    ContentView()
}
