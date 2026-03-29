// JSONMessageExtractor.swift
// ASC - Alamofire Swift Client
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

// MARK: - JSONMessageExtractor

/// Extracts human-readable error messages from arbitrary JSON server responses.
///
/// Used by both `ErrorMapper` and `NetworkResponseMonitor` to surface error
/// descriptions returned by the server in various formats.
internal enum JSONMessageExtractor {
    /// Attempts to extract an error message string from raw response data.
    ///
    /// - Parameter data: Raw JSON data from the server response.
    /// - Returns: The first matching message string found, or `nil`.
    internal static func message(from data: Data?) -> String? {
        guard let data,
              !data.isEmpty,
              let json = try? JSONSerialization.jsonObject(with: data) else {
            return nil
        }

        return findMessage(in: json)
    }

    /// Recursively finds a message string in any JSON structure.
    ///
    /// Searches through dictionaries and arrays using common error key names.
    ///
    /// - Parameter value: JSON value to search (String, Dictionary, Array, etc.)
    /// - Returns: Found message string, or `nil` if not found.
    private static func findMessage(in value: Any) -> String? {
        // Direct string value
        if let string = value as? String {
            return string
        }

        // Dictionary: check common message keys first, then recurse
        if let dict = value as? [String: Any] {
            let messageKeys = [
                "message",
                "error",
                "error_description",
                "errorMessage",
                "detail",
                "error_message",
            ]

            for key in messageKeys {
                if let message = dict[key] as? String {
                    return message
                }
            }

            for (_, nestedValue) in dict {
                if let message = findMessage(in: nestedValue) {
                    return message
                }
            }
        }

        // Array: check first element
        if let array = value as? [Any], let first = array.first {
            return findMessage(in: first)
        }

        return nil
    }
}
