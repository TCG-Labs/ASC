// ASCLogger.swift
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
import os.log
import Synchronization

let log: Logger = .init(subsystem: "com.asc.networking", category: "NetworkClient")

/// Log level for ASC logger.
public enum ASCLogLevel: Int, Sendable {
    /// No logging.
    case none = 0

    /// Log errors only.
    case error = 1

    /// Log errors and important info (requests, responses).
    case info = 2

    /// Log everything including detailed debug info.
    case debug = 3

    /// Log everything including request/response bodies.
    case verbose = 4
}

/// Built-in logger for ASC using OSLog.
///
/// Logs HTTP requests and responses with configurable log levels.
/// Uses unified logging system (os.log) for better performance and privacy.
///
/// Features enhanced visual structure with:
/// - Request numbering for tracking
/// - Visual separators between requests
/// - Grouped information blocks
/// - Improved JSON formatting
///
/// Example:
/// ```swift
/// let config = NetworkClientConfiguration(
///     baseURL: "https://api.example.com",
///     logLevel: .debug
/// )
/// let client = NetworkClient(configuration: config)
/// ```
public final class ASCLogger: EventMonitor, Sendable {
    // MARK: - Properties

    private static let sharedQueue = DispatchQueue(label: "com.asc.logger", qos: .utility)
    private let logLevel: ASCLogLevel

    private let dateFormatter: DateFormatter = {
        let formatter: DateFormatter = .init()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()

    public var queue: DispatchQueue {
        Self.sharedQueue
    }

    // MARK: - Initialization

    /// Creates a new ASC logger.
    ///
    /// - Parameters:
    ///   - logLevel: The minimum log level to display
    public init(logLevel: ASCLogLevel) {
        self.logLevel = logLevel
    }

    // MARK: - EventMonitor

    public func request(_ request: Request, didResumeTask task: URLSessionTask) {
        guard logLevel.rawValue >= ASCLogLevel.info.rawValue else { return }
        guard let urlRequest = request.request else { return }

        let method = urlRequest.httpMethod ?? "GET"
        let url = urlRequest.url?.absoluteString ?? "unknown"
        let methodEmoji = methodEmoji(for: method)

        let date: Date = .now
        let stringDate = dateFormatter.string(from: date)

        var lines: [String] = []
        lines.append("┌─ \(stringDate) [ASC] ▶️ \(methodEmoji) \(method)")
        lines.append("│  \(url)")

        if logLevel.rawValue >= ASCLogLevel.debug.rawValue {
            lines.append(contentsOf: buildHeadersLines(urlRequest.allHTTPHeaderFields, prefix: "│"))
        }

        if logLevel.rawValue >= ASCLogLevel.verbose.rawValue {
            lines.append(contentsOf: buildBodyLines(urlRequest.httpBody, prefix: "│"))
        }

        lines.append("└─────────────────────────────────────────────────────────────────")

        log.info("\(lines.joined(separator: "\n"))")
    }

    public func request<Value>(
        _ request: DataRequest,
        didParseResponse response: DataResponse<Value, AFError>
    ) {
        guard logLevel.rawValue >= ASCLogLevel.info.rawValue else { return }

        if let httpResponse = response.response {
            let statusCode = httpResponse.statusCode
            let duration = response.metrics?.taskInterval.duration ?? 0
            let dataSize = calculateResponseSize(from: response)
            let method = response.request?.httpMethod ?? "GET"
            let url = response.request?.url?.absoluteString ?? "unknown"
            let statusEmoji = statusEmoji(for: statusCode)
            let durationEmoji = durationEmoji(for: duration)

            let date: Date = .now
            let stringDate = dateFormatter.string(from: date)

            var lines: [String] = []
            lines.append("┌─ 📡 \(stringDate) [ASC] ◀️ \(statusEmoji) \(method) (\(statusCode))")
            lines.append("│  \(url)")
            lines.append("│  \(durationEmoji) \(String(format: "%.3f", duration))s • 📦 \(self.formatBytes(dataSize))")

            if logLevel.rawValue >= ASCLogLevel.debug.rawValue {
                let headers = httpResponse.allHeaderFields as? [String: String]
                lines.append(contentsOf: buildHeadersLines(headers, prefix: "│"))
            }

            if logLevel.rawValue >= ASCLogLevel.verbose.rawValue {
                lines.append(contentsOf: buildResponseBodyLines(response.data, prefix: "│"))
            }

            lines.append("└─────────────────────────────────────────────────────────────────")

            log.info("\(lines.joined(separator: "\n"))")
        }

        if let error = response.error {
            logError(error, for: request)
        }
    }

    public func request(
        _ request: Request,
        didCompleteTask task: URLSessionTask,
        with error: AFError?
    ) {
        // Log error if present
        if let error = error {
            logError(error, for: request)
        }
    }

    // MARK: - Private Methods

    /// Calculates the total response size in bytes from URLSessionTaskMetrics.
    ///
    /// Returns nil if size cannot be determined (metrics unavailable).
    ///
    /// Calculates total size as sum of:
    /// - `countOfResponseHeaderBytesReceived` (response headers size)
    /// - `countOfResponseBodyBytesReceived` (response body size)
    ///
    /// Sums across all transaction metrics to handle redirects and retries correctly.
    ///
    /// - Parameter response: The DataResponse to calculate size from
    /// - Returns: Total response size in bytes (headers + body), or nil if unavailable
    private func calculateResponseSize<Value>(
        from response: DataResponse<Value, AFError>
    ) -> Int? {
        guard let metrics = response.metrics else {
            return nil
        }

        var totalBytes: Int64 = 0
        for transaction in metrics.transactionMetrics {
            totalBytes += transaction.countOfResponseHeaderBytesReceived
            totalBytes += transaction.countOfResponseBodyBytesReceived
        }

        guard totalBytes > 0 else {
            return nil
        }

        return Int(totalBytes)
    }

    private func buildHeadersLines(_ headers: [String: String]?, prefix: String = "") -> [String] {
        guard let headers = headers, !headers.isEmpty else { return [] }

        var lines: [String] = []
        lines.append("\(prefix)  📋 Headers (\(headers.count))")
        for (key, value) in headers.sorted(by: { $0.key < $1.key }) {
            #if DEBUG
            lines.append("\(prefix)     • \(key): \(value)")
            #else
            let sanitizedValue = shouldRedact(headerName: key) ? "🔒 <redacted>" : value
            lines.append("\(prefix)     • \(key): \(sanitizedValue)")
            #endif
        }
        return lines
    }

    private func buildBodyLines(_ body: Data?, prefix: String = "") -> [String] {
        guard let body = body else { return [] }

        var lines: [String] = []
        lines.append("\(prefix)  📦 Request Body (\(self.formatBytes(body.count)))")

        if let jsonString = prettyPrintJSON(body, maxLines: 30) {
            for line in jsonString.split(separator: "\n") {
                lines.append("\(prefix)     \(line)")
            }
        } else if let string = String(data: body, encoding: .utf8) {
            let preview = string.prefix(500)
            lines.append("\(prefix)     📝 Text: \(preview)\(string.count > 500 ? "..." : "")")
        } else {
            lines.append("\(prefix)     💾 Binary: \(body.count) bytes")
        }
        return lines
    }

    private func buildResponseBodyLines(_ data: Data?, prefix: String = "") -> [String] {
        guard let data = data else { return [] }

        var lines: [String] = []
        lines.append("\(prefix)  📄 Response Body (\(self.formatBytes(data.count)))")

        if let jsonString: String = .init(data: data, encoding: .utf8),
           jsonString == "[]" {
            lines.append("\(prefix)     \(jsonString)")
            return lines
        }

        if let jsonString = prettyPrintJSON(data, maxLines: 50) {
            for line in jsonString.split(separator: "\n") {
                lines.append("\(prefix)     \(line)")
            }
        } else if let string = String(data: data, encoding: .utf8) {
            let preview = string.prefix(500)
            lines.append("\(prefix)     📝 Text: \(preview)\(string.count > 500 ? "..." : "")")
        } else {
            lines.append("\(prefix)     💾 Binary: \(data.count) bytes")
        }
        return lines
    }

    private func logError(_ error: AFError, for request: Request) {
        guard logLevel.rawValue >= ASCLogLevel.error.rawValue else { return }

        let url = request.request?.url?.absoluteString ?? "unknown"
        let errorEmoji = errorEmoji(for: error)

        let date: Date = .now
        let stringDate = dateFormatter.string(from: date)

        var lines: [String] = []
        lines.append("┌─ 📡 \(stringDate) [ASC] ✗ ERROR")
        lines.append("│  \(errorEmoji) \(error.localizedDescription)")
        lines.append("│  URL: \(url)")

        if logLevel.rawValue >= ASCLogLevel.debug.rawValue {
            if let underlyingError = error.underlyingError {
                lines.append("│  ⚙️ Underlying: \(underlyingError.localizedDescription)")
            }
        }

        lines.append("└─────────────────────────────────────────────────────────────────")

        log.error("\(lines.joined(separator: "\n"))")
    }

    private func formatBytes(_ bytes: Int?) -> String {
        guard let bytes = bytes, bytes > 0 else {
            return "??? B"
        }

        let units = ["B", "KB", "MB", "GB"]
        var value = Double(bytes)
        var unitIndex = 0

        while value >= 1024 && unitIndex < units.count - 1 {
            value /= 1024
            unitIndex += 1
        }

        if unitIndex == 0 {
            return "\(bytes) B"
        } else {
            return String(format: "%.2f %@", value, units[unitIndex])
        }
    }

    private func methodEmoji(for method: String) -> String {
        switch method.uppercased() {
        case "GET": return "📥"
        case "POST": return "📤"
        case "PUT": return "🔄"
        case "PATCH": return "✏️"
        case "DELETE": return "🗑️"
        case "HEAD": return "👀"
        case "OPTIONS": return "🔍"
        default: return "📡"
        }
    }

    private func statusEmoji(for statusCode: Int) -> String {
        switch statusCode {
        case 200: return "✅"
        case 201: return "🎉"
        case 202: return "👌"
        case 204: return "🆗"
        case 200..<300: return "✓"

        case 301, 302, 303, 307, 308: return "🔀"
        case 304: return "💾"
        case 300..<400: return "↪️"

        case 400: return "❌"
        case 401: return "🔐"
        case 403: return "🚫"
        case 404: return "🔍"
        case 429: return "⏸️"
        case 400..<500: return "⚠️"

        case 500: return "💥"
        case 502: return "🚧"
        case 503: return "⛔"
        case 504: return "⏰"
        case 500..<600: return "❗"

        default: return "❓"
        }
    }

    private func durationEmoji(for duration: TimeInterval) -> String {
        switch duration {
        case 0..<0.1: return "⚡"
        case 0.1..<0.5: return "🚀"
        case 0.5..<1.0: return "⏱️"
        case 1.0..<3.0: return "🐌"
        default: return "🐢"
        }
    }

    private func errorEmoji(for error: AFError) -> String {
        if let urlError = error.underlyingError as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost: return "📡"
            case .timedOut: return "⏰"
            case .cannotFindHost, .cannotConnectToHost: return "🔌"
            case .serverCertificateUntrusted, .serverCertificateHasUnknownRoot: return "🔒"
            case .cancelled: return "🛑"
            default: return "⚠️"
            }
        }

        if case .explicitlyCancelled = error {
            return "🛑"
        }

        return "❌"
    }

    private func shouldRedact(headerName: String) -> Bool {
        let redactedHeaders = [
            "authorization",
            "cookie",
            "set-cookie",
            "api-key",
            "x-api-key",
            "token",
        ]

        return redactedHeaders.contains(headerName.lowercased())
    }

    private func prettyPrintJSON(_ data: Data, maxLines: Int? = nil) -> String? {
        guard data.count < 100_000 else {
            return "JSON too large (\(self.formatBytes(data.count)))"
        }

        guard let json = try? JSONSerialization.jsonObject(with: data),
              let prettyData = try? JSONSerialization.data(
                withJSONObject: json,
                options: [.prettyPrinted, .sortedKeys]
              ),
              let string = String(data: prettyData, encoding: .utf8) else {
            return nil
        }

        if let maxLines = maxLines {
            let lines = string.split(separator: "\n", omittingEmptySubsequences: false)
            if lines.count > maxLines {
                let preview = lines.prefix(maxLines).joined(separator: "\n")
                let remaining = lines.count - maxLines
                return preview + "\n... (\(remaining) more lines)"
            }
        }

        return string
    }
}
