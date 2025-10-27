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

        let method = urlRequest.httpMethod ?? "GET"
        let url = urlRequest.url?.absoluteString ?? "unknown"
        let methodEmoji = methodEmoji(for: method)

        logger.info("┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        logger.info("┃ 📡 REQUEST #\(requestNumber)")
        logger.info("┃ \(methodEmoji) \(method) \(url)")

        if logLevel.rawValue >= ASCLogLevel.debug.rawValue {
            logHeaders(urlRequest.allHTTPHeaderFields, prefix: "┃")
        }

        if logLevel.rawValue >= ASCLogLevel.verbose.rawValue {
            logBody(urlRequest.httpBody, prefix: "┃")
        }

        logger.info("┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    }

    public func request<Value>(
        _ request: DataRequest,
        didParseResponse response: DataResponse<Value, AFError>
    ) {
        guard logLevel.rawValue >= ASCLogLevel.info.rawValue else { return }

        if let httpResponse = response.response {
            let statusCode = httpResponse.statusCode
            let url = httpResponse.url?.absoluteString ?? "unknown"
            let duration = response.metrics?.taskInterval.duration ?? 0
            let dataSize = response.data?.count ?? 0

            let statusEmoji = statusEmoji(for: statusCode)
            let durationEmoji = durationEmoji(for: duration)

            logger.info("┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            logger.info("┃ 📥 RESPONSE")
            logger.info("┃ \(statusEmoji) \(statusCode) \(url)")
            logger.info("┃ \(durationEmoji) Duration: \(String(format: "%.3f", duration))s • Size: \(self.formatBytes(dataSize))")

            if logLevel.rawValue >= ASCLogLevel.debug.rawValue {
                logHeaders(httpResponse.allHeaderFields as? [String: String], prefix: "┃")
            }

            if logLevel.rawValue >= ASCLogLevel.verbose.rawValue {
                logResponseBody(response.data, prefix: "┃")
            }

            logger.info("┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
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
        guard let error = error else { return }

        logError(error, for: request)
    }

    // MARK: - Private Methods

    private func logHeaders(_ headers: [String: String]?, prefix: String = "") {
        guard let headers = headers, !headers.isEmpty else { return }

        logger.debug("\(prefix) ┃")
        logger.debug("\(prefix) ┣━━ 📋 Headers (\(headers.count))")
        for (key, value) in headers.sorted(by: { $0.key < $1.key }) {
            let sanitizedValue = shouldRedact(headerName: key) ? "🔒 <redacted>" : value
            logger.debug("\(prefix) ┃   • \(key): \(sanitizedValue)")
        }
    }

    private func logBody(_ body: Data?, prefix: String = "") {
        guard let body = body else { return }

        logger.debug("\(prefix) ┃")
        logger.debug("\(prefix) ┣━━ 📦 Request Body (\(self.formatBytes(body.count)))")

        if let jsonString = prettyPrintJSON(body, maxLines: 20) {
            for line in jsonString.split(separator: "\n") {
                logger.debug("\(prefix) ┃   \(line)")
            }
        } else if let string = String(data: body, encoding: .utf8) {
            let preview = string.prefix(500)
            logger.debug("\(prefix) ┃   📝 Text: \(preview)\(string.count > 500 ? "..." : "")")
        } else {
            logger.debug("\(prefix) ┃   💾 Binary: \(body.count) bytes")
        }
    }

    private func logResponseBody(_ data: Data?, prefix: String = "") {
        guard let data = data else { return }

        logger.debug("\(prefix) ┃")
        logger.debug("\(prefix) ┣━━ 📄 Response Body (\(self.formatBytes(data.count)))")

        if let jsonString = prettyPrintJSON(data, maxLines: 50) {
            for line in jsonString.split(separator: "\n") {
                logger.debug("\(prefix) ┃   \(line)")
            }
        } else if let string = String(data: data, encoding: .utf8) {
            let preview = string.prefix(500)
            logger.debug("\(prefix) ┃   📃 Text: \(preview)\(string.count > 500 ? "..." : "")")
        } else {
            logger.debug("\(prefix) ┃   💿 Binary: \(data.count) bytes")
        }
    }

    private func logError(_ error: AFError, for request: Request) {
        guard logLevel.rawValue >= ASCLogLevel.error.rawValue else { return }

        let url = request.request?.url?.absoluteString ?? "unknown"
        let errorEmoji = errorEmoji(for: error)

        logger.error("┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        logger.error("┃ ❌ ERROR")
        logger.error("┃ \(errorEmoji) \(error.localizedDescription)")
        logger.error("┃ URL: \(url)")

        if logLevel.rawValue >= ASCLogLevel.debug.rawValue {
            if let underlyingError = error.underlyingError {
                logger.error("┃")
                logger.error("┣━━ ⚙️ Underlying Error")
                logger.error("┃   \(underlyingError.localizedDescription)")
            }
        }

        logger.error("┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
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
