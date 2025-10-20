// ASCLogger.swift
// ASC - Alamofire Swift Client

// Built-in debug logger using OSLog.

import Alamofire
import Foundation
import os.log

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
/// Example:
/// ```swift
/// let config = NetworkClientConfiguration(
///     baseURL: "https://api.example.com",
///     logLevel: .debug
/// )
/// let client = NetworkClient(configuration: config)
/// ```
public final class ASCLogger: EventMonitor, @unchecked Sendable {
    // MARK: - Properties

    /// The log level for this logger.
    private let logLevel: ASCLogLevel

    /// OSLog logger instance.
    private let logger: Logger

    /// Dispatch queue for thread-safe logging.
    public let queue: DispatchQueue

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
        self.queue = DispatchQueue(label: "com.asc.logger", qos: .utility)
    }

    // MARK: - EventMonitor

    /// Called when a request is about to start.
    public func requestDidResume(_ request: Request) {
        guard logLevel.rawValue >= ASCLogLevel.info.rawValue else { return }

        if let urlRequest = request.request {
            let method = urlRequest.httpMethod ?? "GET"
            let url = urlRequest.url?.absoluteString ?? "unknown"
            let methodEmoji = methodEmoji(for: method)

            logger.info("\(methodEmoji) \(method) \(url)")

            if logLevel.rawValue >= ASCLogLevel.debug.rawValue {
                logHeaders(urlRequest.allHTTPHeaderFields)
            }

            if logLevel.rawValue >= ASCLogLevel.verbose.rawValue {
                logBody(urlRequest.httpBody)
            }
        }
    }

    /// Called when a request finishes successfully.
    public func request<Value>(
        _ request: DataRequest,
        didParseResponse response: DataResponse<Value, AFError>
    ) {
        guard logLevel.rawValue >= ASCLogLevel.info.rawValue else { return }

        if let httpResponse = response.response {
            let statusCode = httpResponse.statusCode
            let url = httpResponse.url?.absoluteString ?? "unknown"
            let duration = response.metrics?.taskInterval.duration ?? 0

            let statusEmoji = statusEmoji(for: statusCode)
            let durationEmoji = durationEmoji(for: duration)
            logger.info("← \(statusEmoji) \(statusCode) \(url) \(durationEmoji) \(String(format: "%.2f", duration))s")

            if logLevel.rawValue >= ASCLogLevel.debug.rawValue {
                logHeaders(httpResponse.allHeaderFields as? [String: String])
            }

            if logLevel.rawValue >= ASCLogLevel.verbose.rawValue {
                logResponseBody(response.data)
            }
        }

        if let error = response.error {
            logError(error, for: request)
        }
    }

    /// Called when a request fails.
    public func request(
        _ request: Request,
        didCompleteTask task: URLSessionTask,
        with error: AFError?
    ) {
        guard let error = error else { return }

        logError(error, for: request)
    }

    // MARK: - Private Methods

    /// Logs HTTP headers.
    private func logHeaders(_ headers: [String: String]?) {
        guard let headers = headers, !headers.isEmpty else { return }

        logger.debug("  📋 Headers:")
        for (key, value) in headers.sorted(by: { $0.key < $1.key }) {
            let sanitizedValue = shouldRedact(headerName: key) ? "🔒 <redacted>" : value
            logger.debug("    \(key): \(sanitizedValue)")
        }
    }

    /// Logs request body.
    private func logBody(_ body: Data?) {
        guard let body = body else { return }

        if let jsonString = prettyPrintJSON(body) {
            logger.debug("  📦 Body (JSON):\n\(jsonString)")
        } else if let string = String(data: body, encoding: .utf8) {
            logger.debug("  📝 Body (Text): \(string)")
        } else {
            logger.debug("  💾 Body (Binary): \(body.count) bytes")
        }
    }

    /// Logs response body.
    private func logResponseBody(_ data: Data?) {
        guard let data = data else { return }

        if let jsonString = prettyPrintJSON(data) {
            logger.debug("  📄 Response (JSON):\n\(jsonString)")
        } else if let string = String(data: data, encoding: .utf8) {
            logger.debug("  📃 Response (Text): \(string)")
        } else {
            logger.debug("  💿 Response (Binary): \(data.count) bytes")
        }
    }

    /// Logs an error.
    private func logError(_ error: AFError, for request: Request) {
        guard logLevel.rawValue >= ASCLogLevel.error.rawValue else { return }

        let url = request.request?.url?.absoluteString ?? "unknown"
        let errorEmoji = errorEmoji(for: error)
        logger.error("\(errorEmoji) Error for \(url): \(error.localizedDescription)")

        if logLevel.rawValue >= ASCLogLevel.debug.rawValue {
            if let underlyingError = error.underlyingError {
                logger.error("  ⚙️ Underlying error: \(underlyingError.localizedDescription)")
            }
        }
    }

    /// Returns emoji for HTTP method.
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

    /// Returns emoji for HTTP status code.
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

    /// Returns emoji for request duration.
    private func durationEmoji(for duration: TimeInterval) -> String {
        switch duration {
        case 0..<0.1: return "⚡"
        case 0.1..<0.5: return "🚀"
        case 0.5..<1.0: return "⏱️"
        case 1.0..<3.0: return "🐌"
        default: return "🐢"
        }
    }

    /// Returns emoji for error type.
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

    /// Checks if a header should be redacted for privacy.
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

    /// Pretty prints JSON data.
    private func prettyPrintJSON(_ data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data),
              let prettyData = try? JSONSerialization.data(
                withJSONObject: json,
                options: [.prettyPrinted, .sortedKeys]
              ),
              let string = String(data: prettyData, encoding: .utf8) else {
            return nil
        }

        return string
    }
}
