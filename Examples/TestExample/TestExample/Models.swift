//
//  Models.swift
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

// MARK: - Models

/// User model from JSONPlaceholder API.
nonisolated struct User: Codable, Identifiable, Sendable {
    let id: Int
    let name: String
    let username: String
    let email: String
    let phone: String?
    let website: String?
}

/// Post model from JSONPlaceholder API.
nonisolated struct Post: Codable, Identifiable, Sendable {
    let id: Int
    let userId: Int
    let title: String
    let body: String
}

/// Comment model from JSONPlaceholder API.
nonisolated struct Comment: Codable, Identifiable, Sendable {
    let id: Int
    let postId: Int
    let name: String
    let email: String
    let body: String
}

/// User creation request model.
nonisolated struct CreateUserParams: Codable, Sendable {
    let name: String
    let username: String
    let email: String
}

/// User creation response model.
nonisolated struct CreateUserRes: Codable, Sendable {
    let id: Int
    let name: String
    let username: String
    let email: String
}

// MARK: - API Requests

/// Request to get all users.
struct GetUsersRequest: NetworkRequest {
    typealias Response = [User]
    typealias Parameters = Empty

    var path: String { "/users" }
    var method: HTTPMethod { .get }
}

/// Request to get a specific user by ID.
struct GetUserRequest: NetworkRequest {
    typealias Response = User
    typealias Parameters = Empty

    let userId: Int

    var path: String { "/users/\(userId)" }
    var method: HTTPMethod { .get }
}

/// Request to create a new user.
struct CreateUserRequest: NetworkRequest {
    typealias Response = CreateUserRes
    typealias Parameters = CreateUserParams

    let name: String
    let username: String
    let email: String

    var path: String { "/users" }
    var method: HTTPMethod { .post }
    var parameters: Parameters? {
        Parameters(name: name, username: username, email: email)
    }
}

/// Request to get posts for a specific user.
struct GetUserPostsRequest: NetworkRequest {
    typealias Response = [Post]
    typealias Parameters = Empty

    let userId: Int

    var path: String { "/users/\(userId)/posts" }
    var method: HTTPMethod { .get }
}

/// Request to get all posts.
struct GetPostsRequest: NetworkRequest {
    typealias Response = [Post]
    typealias Parameters = Empty

    var path: String { "/posts" }
    var method: HTTPMethod { .get }
}

/// Request to get comments for a specific post.
struct GetPostCommentsRequest: NetworkRequest {
    typealias Response = [Comment]
    typealias Parameters = Empty

    let postId: Int

    var path: String { "/posts/\(postId)/comments" }
    var method: HTTPMethod { .get }
}

/// Request to delete a post.
struct DeletePostRequest: NetworkRequest {
    typealias Response = Empty
    typealias Parameters = Empty

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
struct UploadFileRequest: NetworkRequest {
    typealias Response = UploadResponse
    typealias Parameters = Empty

    let fileData: Data
    let fileName: String
    let mimeType: String

    var path: String { "/posts" } // Используем posts endpoint для демо
    var method: HTTPMethod { .post }
    var fileUpload: FileUpload? {
        .multipart([
            .data(fieldName: "file_name", data: fileData)
        ])
    }
}

/// Request to upload a file from file system.
struct UploadFileFromURLRequest: NetworkRequest {
    typealias Response = UploadResponse
    typealias Parameters = Empty

    let fileURL: URL
    let fileName: String
    let mimeType: String

    var path: String { "/posts" }
    var method: HTTPMethod { .post }
    var fileUpload: FileUpload? {
        .file(fileURL)
    }
}
