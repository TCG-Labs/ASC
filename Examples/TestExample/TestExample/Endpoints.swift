//
//  Endpoints.swift
//  TestExample
//
//  Created by Claude on 25.10.2025.
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

// MARK: - Request Models

/// Login request parameters.
nonisolated struct LoginRequest: Codable, Sendable {
    let email: String
    let password: String
}

/// User creation request model.
nonisolated struct CreateUserRequest: Codable, Sendable {
    let name: String
    let username: String
    let email: String
}

// MARK: - Response Models

/// Login response model.
nonisolated struct LoginResponse: Codable, Sendable {
    // Add response fields as needed based on API response
    // For example: token, user, etc.
}

/// Post model from JSONPlaceholder API.
nonisolated struct PostResponse: Codable, Identifiable, Sendable {
    let id: Int
    let userId: Int
    let title: String
    let body: String
}

/// Comment model from JSONPlaceholder API.
nonisolated struct CommentResponse: Codable, Identifiable, Sendable {
    let id: Int
    let postId: Int
    let name: String
    let email: String
    let body: String
}

/// User model from JSONPlaceholder API.
nonisolated struct UserResponse: Codable, Identifiable, Sendable {
    let id: Int
    let name: String
    let username: String
    let email: String
    let phone: String?
    let website: String?
}

/// User creation response model.
nonisolated struct CreateUserResponse: Codable, Sendable {
    let id: Int
    let name: String
    let username: String
    let email: String
}

// MARK: - API Endpoints

/// Request to get all users.
struct GetUsersEndpoint: Endpoint {
    typealias Response = [UserResponse]
    typealias Request = Empty

    var path: String { "/users" }
    var method: HTTPMethod { .get }
}

/// Request to get a specific user by ID.
struct GetUserEndpoint: Endpoint {
    typealias Response = UserResponse
    typealias Request = Empty

    let userId: Int

    var path: String { "/users/\(userId)" }
    var method: HTTPMethod { .get }
}

/// Request to create a new user.
struct CreateUserEndpoint: Endpoint {
    typealias Response = CreateUserResponse
    typealias Request = CreateUserRequest

    let name: String
    let username: String
    let email: String

    var path: String { "/users" }
    var method: HTTPMethod { .post }
    var parameters: Request? {
        Request(name: name, username: username, email: email)
    }
}

/// Request to get posts for a specific user.
struct GetUserPostsEndpoint: Endpoint {
    typealias Response = [PostResponse]
    typealias Request = Empty

    let userId: Int

    var path: String { "/users/\(userId)/posts" }
    var method: HTTPMethod { .get }
}

/// Request to get all posts.
struct GetPostsEndpoint: Endpoint {
    typealias Response = [PostResponse]
    typealias Request = Empty

    var path: String { "/posts" }
    var method: HTTPMethod { .get }
}

/// Request to get comments for a specific post.
struct GetPostCommentsEndpoint: Endpoint {
    typealias Response = [CommentResponse]
    typealias Request = Empty

    let postId: Int

    var path: String { "/posts/\(postId)/comments" }
    var method: HTTPMethod { .get }
}

/// Request to delete a post.
struct DeletePostEndpoint: Endpoint {
    typealias Response = Empty
    typealias Request = Empty

    let postId: Int

    var path: String { "/posts/\(postId)" }
    var method: HTTPMethod { .delete }
}

/// Response model for file upload.
nonisolated struct UploadResponse: Codable, Sendable {
    let id: Int
    let url: String?
    let filename: String?
}

/// Request to upload a file.
struct UploadFileEndpoint: Endpoint {
    typealias Response = UploadResponse
    typealias Request = Empty

    let fileData: Data
    let fileName: String
    let mimeType: String

    var path: String { "/posts" } // Используем posts endpoint для демо
    var method: HTTPMethod { .post }
    var uploadData: UploadData? {
        .multipart([
            .data(fieldName: "file_name", data: fileData)
        ])
    }
}

/// Request to upload a file from file system.
struct UploadFileFromURLEndpoint: Endpoint {
    typealias Response = UploadResponse
    typealias Request = Empty

    let fileURL: URL
    let fileName: String
    let mimeType: String

    var path: String { "/posts" }
    var method: HTTPMethod { .post }
    var uploadData: UploadData? {
        .file(fileURL)
    }
}

/// Request to login user.
struct LoginEndpoint: Endpoint {
    typealias Response = LoginResponse
    typealias Request = LoginRequest

    let email: String
    let password: String

    var path: String { "/api/v1/auth/login" }
    var method: HTTPMethod { .post }
    var parameters: Request? {
        LoginRequest(email: email, password: password)
    }
}

// MARK: - Download Endpoints

/// Endpoint for downloading an image from Picsum Photos API.
struct DownloadImageEndpoint: Endpoint {
    typealias Response = Empty
    typealias Request = Empty

    let imageId: Int
    let width: Int
    let height: Int

    var baseURL: String? { "https://picsum.photos" }
    var path: String { "/\(width)/\(height)" }
    var method: HTTPMethod { .get }
}
