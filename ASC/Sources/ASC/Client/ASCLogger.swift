// ASCLogger.swift
// ASC - Alamofire Swift Client

import Foundation
import os.log
import Synchronization

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
    private let requestCounter = Mutex<Int>(0)
    private let requestNumbers = Mutex<[UUID: Int]>([:])
    private let logLevel: ASCLogLevel
    private let logger: Logger

    public var queue: DispatchQueue {
        Self.sharedQueue
    }

    // MARK: - Initialization

    /// Creates a new ASC logger.
    ///
    /// - Parameters:
    ///   - logLevel: The minimum log level to display
    ///   - subsystem: OSLog subsystem (default: "com.asc.networking")
    ///   - category: OSLog category (default: "NetworkClient")
    public init(
        logLevel: ASCLogLevel,
        subsystem: String = "com.asc.networking",
        category: String = "NetworkClient"
    ) {
        self.logLevel = logLevel
        self.logger = Logger(subsystem: subsystem, category: category)
    }

    // MARK: - EventMonitor

    public func requestDidResume(_ request: Request) {
        guard logLevel.rawValue >= ASCLogLevel.info.rawValue else { return }
        guard let urlRequest = request.request else { return }

        let requestNumber = requestCounter.withLock { counter in
            counter += 1
            return counter
        }

        // Store request number for later correlation
        requestNumbers.withLock { $0[request.id] = requestNumber }

        let method = urlRequest.httpMethod ?? "GET"
        let url = urlRequest.url?.absoluteString ?? "unknown"
        let methodEmoji = methodEmoji(for: method)

        var lines: [String] = []
        lines.append("┌─ 📡 #\(requestNumber) ▶️ \(methodEmoji) \(method)")
        lines.append("│  \(url)")

        if logLevel.rawValue >= ASCLogLevel.debug.rawValue {
            lines.append(contentsOf: buildHeadersLines(urlRequest.allHTTPHeaderFields, prefix: "│"))
        }

        if logLevel.rawValue >= ASCLogLevel.verbose.rawValue {
            lines.append(contentsOf: buildBodyLines(urlRequest.httpBody, prefix: "│"))
        }

        lines.append("└─────────────────────────────────────────────────────────────────")

        logger.info("\(lines.joined(separator: "\n"))")
    }

    public func request<Value>(
        _ request: DataRequest,
        didParseResponse response: DataResponse<Value, AFError>
    ) {
        guard logLevel.rawValue >= ASCLogLevel.info.rawValue else { return }

        // Get request number for correlation
        let requestNumber = requestNumbers.withLock { $0[request.id] }

        if let httpResponse = response.response {
            let statusCode = httpResponse.statusCode
            let duration = response.metrics?.taskInterval.duration ?? 0
            let dataSize = response.data?.count ?? 0

            let statusEmoji = statusEmoji(for: statusCode)
            let durationEmoji = durationEmoji(for: duration)

            // Format request number
            let requestTag = requestNumber.map { "#\($0)" } ?? "#?"

            var lines: [String] = []
            lines.append("┌─ 📡 \(requestTag) ◀️ \(statusEmoji) \(statusCode)")
            lines.append("│  \(durationEmoji) \(String(format: "%.3f", duration))s • 📦 \(self.formatBytes(dataSize))")

            if logLevel.rawValue >= ASCLogLevel.debug.rawValue {
                let headers = httpResponse.allHeaderFields as? [String: String]
                lines.append(contentsOf: buildHeadersLines(headers, prefix: "│"))
            }

            if logLevel.rawValue >= ASCLogLevel.verbose.rawValue {
                lines.append(contentsOf: buildResponseBodyLines(response.data, prefix: "│"))
            }

            lines.append("└─────────────────────────────────────────────────────────────────")

            logger.info("\(lines.joined(separator: "\n"))")
        }

        if let error = response.error {
            logError(error, for: request)
        }

        // Cleanup: remove request number after logging response
        _ = requestNumbers.withLock { $0.removeValue(forKey: request.id) }
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

        // Always cleanup request number when task completes
        // This ensures no memory leak even if didParseResponse is never called
        _ = requestNumbers.withLock { $0.removeValue(forKey: request.id) }
    }

    // MARK: - Private Methods

    private func buildHeadersLines(_ headers: [String: String]?, prefix: String = "") -> [String] {
        guard let headers = headers, !headers.isEmpty else { return [] }

        var lines: [String] = []
        lines.append("\(prefix)  📋 Headers (\(headers.count))")
        for (key, value) in headers.sorted(by: { $0.key < $1.key }) {
            let sanitizedValue = shouldRedact(headerName: key) ? "🔒 <redacted>" : value
            lines.append("\(prefix)     • \(key): \(sanitizedValue)")
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

        // Get request number for correlation
        let requestNumber = requestNumbers.withLock { $0[request.id] }
        let requestTag = requestNumber.map { "#\($0)" } ?? "#?"

        let url = request.request?.url?.absoluteString ?? "unknown"
        let errorEmoji = errorEmoji(for: error)

        var lines: [String] = []
        lines.append("┌─ 📡 \(requestTag) ✗ ERROR")
        lines.append("│  \(errorEmoji) \(error.localizedDescription)")
        lines.append("│  URL: \(url)")

        if logLevel.rawValue >= ASCLogLevel.debug.rawValue {
            if let underlyingError = error.underlyingError {
                lines.append("│  ⚙️ Underlying: \(underlyingError.localizedDescription)")
            }
        }

        lines.append("└─────────────────────────────────────────────────────────────────")

        logger.error("\(lines.joined(separator: "\n"))")
    }

    private func formatBytes(_ bytes: Int) -> String {
        guard bytes > 0 else { return "0 B" }

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
