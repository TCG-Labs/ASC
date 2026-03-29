// LoggingMonitor.swift
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

import Alamofire
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
/*public*/ final class LoggingMonitor: EventMonitor, Sendable {
    // MARK: - Properties

    private static let sharedQueue = DispatchQueue(label: "com.asc.logger", qos: .utility)
    private let logLevel: ASCLogLevel

    private let dateFormatter: DateFormatter = {
        let formatter: DateFormatter = .init()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()

    var queue: DispatchQueue {
        Self.sharedQueue
    }

    // MARK: - Initialization

    /// Creates a new ASC logger.
    ///
    /// - Parameters:
    ///   - logLevel: The minimum log level to display
    init(logLevel: ASCLogLevel) {
        self.logLevel = logLevel
    }

    // MARK: - Request

    func request(_ request: Request, didResumeTask task: URLSessionTask) {
        if request is UploadRequest {
            return
        }

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

        log.info("\(lines.joined(separator: "\n"), privacy: .private)")
    }

    func request(_ request: UploadRequest, didCreateUploadable uploadable: UploadRequest.Uploadable) {
        guard logLevel.rawValue >= ASCLogLevel.debug.rawValue else { return }

        let date: Date = .now
        let stringDate = dateFormatter.string(from: date)

        let urlRequest = request.request
        let method = urlRequest?.httpMethod ?? "POST"
        let url = urlRequest?.url?.absoluteString ?? "unknown"
        let methodEmoji = methodEmoji(for: method)

        var lines: [String] = []
        lines.append("┌─ \(stringDate) [ASC] ▶️ \(methodEmoji) \(method)")
        lines.append("│  \(url)")

        if logLevel.rawValue >= ASCLogLevel.debug.rawValue {
            lines.append(contentsOf: buildHeadersLines(urlRequest?.allHTTPHeaderFields, prefix: "│"))
            lines.append(contentsOf: buildUploadableLines(urlRequest: urlRequest, uploadable: uploadable, prefix: "│"))
        }

        lines.append("└─────────────────────────────────────────────────────────────────")

        log.debug("\(lines.joined(separator: "\n"), privacy: .private)")
    }

    // MARK: - Response

    func request<Value>(
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

            log.info("\(lines.joined(separator: "\n"), privacy: .private)")
        }

        if let error = response.error {
            logError(error, for: request)
        }
    }

    func request<Value: Sendable>(_ request: DownloadRequest, didParseResponse response: DownloadResponse<Value, AFError>) {
        guard logLevel.rawValue >= ASCLogLevel.info.rawValue else { return }

        if let httpResponse = response.response {
            let statusCode = httpResponse.statusCode
            let duration = response.metrics?.taskInterval.duration ?? 0
            let method = response.request?.httpMethod ?? "GET"
            let url = response.request?.url?.absoluteString ?? "unknown"
            let statusEmoji = statusEmoji(for: statusCode)
            let durationEmoji = durationEmoji(for: duration)

            // Get file information
            let fileURL = response.fileURL
            let fileSize = calculateDownloadFileSize(from: response)
            let fileName = fileURL?.lastPathComponent ?? "unknown"

            let date: Date = .now
            let stringDate = dateFormatter.string(from: date)

            var lines: [String] = []
            lines.append("┌─ 📥 \(stringDate) [ASC] ◀️ \(statusEmoji) \(method) (\(statusCode))")
            lines.append("│  \(url)")
            lines.append("│  \(durationEmoji) \(String(format: "%.3f", duration))s • 📦 \(self.formatBytes(fileSize))")

            // File information
            if let fileURL = fileURL {
                lines.append("│  📄 File: \(fileName)")
                lines.append("│  📍 Path: \(fileURL.path)")
            }

            if logLevel.rawValue >= ASCLogLevel.debug.rawValue {
                let headers = httpResponse.allHeaderFields as? [String: String]
                lines.append(contentsOf: buildHeadersLines(headers, prefix: "│"))
            }

            lines.append("└─────────────────────────────────────────────────────────────────")

            log.info("\(lines.joined(separator: "\n"), privacy: .private)")
        }

        if let error = response.error {
            logError(error, for: request)
        }
    }

    func request(
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

    /// Calculates the size of the downloaded file.
    ///
    /// Tries to determine the file size from the file system first,
    /// then falls back to the Content-Length HTTP header if available.
    ///
    /// - Parameter response: Download response from Alamofire
    /// - Returns: File size in bytes, or nil if unable to determine
    private func calculateDownloadFileSize<Value>(
        from response: DownloadResponse<Value, AFError>
    ) -> Int? {
        // Try to get file size from file URL
        if let fileURL = response.fileURL {
            if let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
               let fileSize = attributes[.size] as? Int64 {
                return Int(fileSize)
            }
        }

        // Fallback: try to get from Content-Length header
        if let httpResponse = response.response,
           let contentLengthString = httpResponse.value(forHTTPHeaderField: "Content-Length"),
           let contentLength = Int64(contentLengthString) {
            return Int(contentLength)
        }

        return nil
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

        log.error("\(lines.joined(separator: "\n"), privacy: .private)")
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

    // MARK: - Uploadable Formatting

    private func buildUploadableLines(
        urlRequest: URLRequest?,
        uploadable: UploadRequest.Uploadable,
        prefix: String = ""
    ) -> [String] {
        var lines: [String] = []

        switch uploadable {
        case .data(let data):
            lines.append("\(prefix)  📦 Uploadable Data (\(self.formatBytes(data.count)))")

            guard logLevel.rawValue >= ASCLogLevel.verbose.rawValue else {
                return lines
            }

            if let jsonString = prettyPrintJSON(data, maxLines: 30) {
                for line in jsonString.split(separator: "\n") {
                    lines.append("\(prefix)     \(line)")
                }
            } else if let string = String(data: data, encoding: .utf8) {
                let preview = string.prefix(500)
                lines.append("\(prefix)     📝 Text: \n\(preview)\(string.count > 500 ? "..." : "")")
            } else {
                lines.append("\(prefix)     💾 Binary: \(data.count) bytes")
            }

        case .file(let fileURL, _):
            let fileName = fileURL.lastPathComponent
            let fileSize = fileSizeBytes(at: fileURL)
            lines.append("\(prefix)  📄 Uploadable File: \(fileName) (\(self.formatBytes(fileSize)))")
            lines.append("\(prefix)     Path: \(fileURL.path)")

        case .stream:
            lines.append("\(prefix)  🌊 Uploadable Stream (preview not available)")
        }

        if let contentType = urlRequest?.allHTTPHeaderFields?["Content-Type"] {
            lines.append("\(prefix)  🧾 Content-Type: \(contentType)")
        }

        return lines
    }

    private func fileSizeBytes(at url: URL) -> Int? {
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        return attributes?[.size] as? Int
    }
}
