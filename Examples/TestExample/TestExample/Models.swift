//
//  Models.swift
//  TestExample
//
//  Created by Claude on 25.10.2025.
//

import Foundation
import ASC

// MARK: - User Model

nonisolated struct User: Codable, Identifiable, Sendable {
    let id: Int
    let name: String
    let email: String
}

// MARK: - API Request

struct GetUsersRequest: NetworkRequest {
    typealias Response = [User]

    var path: String { "/users" }
    var method: HTTPMethod { .get }
}
