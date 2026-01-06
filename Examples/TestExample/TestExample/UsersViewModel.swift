//
//  UsersViewModel.swift
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
import SwiftUI
import Combine
import ASC

// MARK: - UsersViewModel

/// ViewModel demonstrating ASC capabilities through JSONPlaceholder API.
///
/// This ViewModel showcases:
/// - GET requests (list and single item)
/// - POST requests (create user)
/// - DELETE requests (delete post)
/// - File uploads (upload file from Data or URL)
/// - Error handling
/// - Different client configurations via DI
@MainActor
final class UsersViewModel: ObservableObject {
    // MARK: - Published Properties

    /// List of users loaded from API.
    @Published var users: [User] = []

    /// Currently selected user.
    @Published var selectedUser: User?

    /// Posts for the selected user.
    @Published var userPosts: [Post] = []

    /// Comments for the selected post.
    @Published var postComments: [Comment] = []

    /// Upload result.
    @Published var uploadResult: UploadResponse?

    /// Loading state indicator.
    @Published var isLoading = false

    /// Error message to display.
    @Published var errorMessage: String?

    // MARK: - Private Properties

    /// Network client for making requests.
    private let client: NetworkClient

    // MARK: - Initialization

    /// Creates a new ViewModel with the specified network client.
    ///
    /// - Parameter client: Network client to use (defaults to DI container's default client)
    init(client: NetworkClient = DIContainer.shared.defaultClient()) {
        self.client = client
    }

    // MARK: - Public Methods

    /// Loads all users from the API.
    func loadUsers() async {
        let refreshTask = Task { [weak self] in
            guard let self else { return }

            isLoading = true
            errorMessage = nil

            do {
                users = try await client.execute(GetUsersRequest())
                debugPrint("✅ Loaded \(users.count) users")
            } catch {
                errorMessage = "Failed to load users: \(error.localizedDescription)"
                debugPrint("❌ Error loading users: \(error)")
            }

            isLoading = false
        }

        _ = await refreshTask.result
    }

    /// Loads a specific user by ID.
    ///
    /// - Parameter id: User ID to load
    func loadUser(id: Int) async {
        isLoading = true
        errorMessage = nil

        do {
            selectedUser = try await client.execute(GetUserRequest(userId: id))
            debugPrint("✅ Loaded user: \(selectedUser?.name ?? "Unknown")")
        } catch {
            errorMessage = "Failed to load user: \(error.localizedDescription)"
            debugPrint("❌ Error loading user: \(error)")
        }

        isLoading = false
    }

    /// Loads posts for the selected user.
    func loadUserPosts() async {
        guard let userId = selectedUser?.id else {
            errorMessage = "No user selected"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            userPosts = try await client.execute(GetUserPostsRequest(userId: userId))
            debugPrint("✅ Loaded \(userPosts.count) posts for user \(userId)")
        } catch {
            errorMessage = "Failed to load posts: \(error.localizedDescription)"
            debugPrint("❌ Error loading posts: \(error)")
        }

        isLoading = false
    }

    /// Loads comments for a specific post.
    ///
    /// - Parameter postId: Post ID to load comments for
    func loadPostComments(postId: Int) async {
        isLoading = true
        errorMessage = nil

        do {
            postComments = try await client.execute(GetPostCommentsRequest(postId: postId))
            debugPrint("✅ Loaded \(postComments.count) comments for post \(postId)")
        } catch {
            errorMessage = "Failed to load comments: \(error.localizedDescription)"
            debugPrint("❌ Error loading comments: \(error)")
        }

        isLoading = false
    }

    /// Creates a new user.
    ///
    /// - Parameters:
    ///   - name: User's name
    ///   - username: User's username
    ///   - email: User's email
    func createUser(name: String, username: String, email: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await client.execute(
                CreateUserRequest(name: name, username: username, email: email)
            )
            debugPrint("✅ Created user with ID: \(response.id)")
            // Reload users to include the new one
            await loadUsers()
        } catch {
            errorMessage = "Failed to create user: \(error.localizedDescription)"
            debugPrint("❌ Error creating user: \(error)")
        }

        isLoading = false
    }

    /// Deletes a post by ID.
    ///
    /// - Parameter postId: Post ID to delete
    func deletePost(postId: Int) async {
        isLoading = true
        errorMessage = nil

        do {
            try await client.execute(DeletePostRequest(postId: postId))
            debugPrint("✅ Deleted post with ID: \(postId)")

            // Remove deleted post from the list
            userPosts.removeAll { $0.id == postId }

            // Also clear comments if they were for this post
            if !postComments.isEmpty {
                postComments = []
            }
        } catch {
            errorMessage = "Failed to delete post: \(error.localizedDescription)"
            debugPrint("❌ Error deleting post: \(error)")
        }

        isLoading = false
    }

    /// Uploads a file from Data.
    ///
    /// - Parameters:
    ///   - data: File data to upload
    ///   - fileName: Name of the file
    ///   - mimeType: MIME type of the file
    func uploadFile(data: Data, fileName: String, mimeType: String) async {
        isLoading = true
        errorMessage = nil
        uploadResult = nil

        do {
            let response = try await client.execute(
                UploadFileRequest(fileData: data, fileName: fileName, mimeType: mimeType)
            )
            uploadResult = response
            debugPrint("✅ File uploaded successfully: \(fileName)")
        } catch {
            errorMessage = "Failed to upload file: \(error.localizedDescription)"
            debugPrint("❌ Error uploading file: \(error)")
        }

        isLoading = false
    }

    /// Uploads a file from file system URL.
    ///
    /// - Parameters:
    ///   - fileURL: URL of the file to upload
    ///   - fileName: Name of the file
    ///   - mimeType: MIME type of the file
    func uploadFile(from fileURL: URL, fileName: String, mimeType: String) async {
        isLoading = true
        errorMessage = nil
        uploadResult = nil

        do {
            let response = try await client.execute(
                UploadFileFromURLRequest(fileURL: fileURL, fileName: fileName, mimeType: mimeType)
            )
            uploadResult = response
            debugPrint("✅ File uploaded successfully from URL: \(fileName)")
        } catch {
            errorMessage = "Failed to upload file: \(error.localizedDescription)"
            debugPrint("❌ Error uploading file: \(error)")
        }

        isLoading = false
    }

    /// Clears the selected user and related data.
    func clearSelection() {
        selectedUser = nil
        userPosts = []
        postComments = []
    }
}

