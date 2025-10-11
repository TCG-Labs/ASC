// ASCError.swift
// ASC - Alamofire Swift Client
//
// Base error protocol for all ASC errors.

import Foundation

/// Base protocol for all ASC errors.
///
/// All error types in ASC conform to this protocol, providing
/// consistent error information and localized descriptions.
public protocol ASCError: LocalizedError, Sendable {
    /// Human-readable error description.
    var errorDescription: String? { get }

    /// Suggested recovery action for the user.
    var recoverySuggestion: String? { get }

    /// Underlying error that caused this error, if any.
    var underlyingError: (any Error)? { get }
}

public extension ASCError {
    /// Default recovery suggestion is nil.
    var recoverySuggestion: String? { nil }

    /// Default underlying error is nil.
    var underlyingError: (any Error)? { nil }

    /// Failure reason matches error description by default.
    var failureReason: String? { errorDescription }
}
