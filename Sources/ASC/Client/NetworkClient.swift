// NetworkClient.swift
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

// Main network client for executing requests with advanced Alamofire features.

import Alamofire
import Foundation

/// Main network client for executing requests.
///
/// The `NetworkClient` is the primary interface for making network requests.
/// It wraps Alamofire's `Session` and provides a type-safe, protocol-oriented API
/// with full access to Alamofire's advanced features.
///
/// Example:
/// ```swift
/// let config = NetworkClientConfiguration(
///     baseURL: "https://api.example.com",
///     interceptors: [MyAuthInterceptor()],
///     eventMonitors: [MyLogger()]
/// )
/// let client = NetworkClient(configuration: config)
/// let user = try await client.execute(GetUserRequest(userId: "123"))
/// ```
public final class NetworkClient: Sendable {
    // MARK: - Properties

    /// Client configuration.
    private let configuration: NetworkClientConfiguration

    /// Alamofire session used for networking.
    internal let session: Session

    /// Request builder for constructing URLRequests.
    private let requestBuilder: RequestBuilder

    /// Error mapper for translating Alamofire errors.
    private let errorMapper: ErrorMapper

    /// Network reachability monitor (optional).
    private let reachability: NetworkReachability?

    // MARK: - Initialization

    /// Creates a new network client with the specified configuration.
    ///
    /// - Parameter configuration: Client configuration
    public init(configuration: NetworkClientConfiguration) {
        self.configuration = configuration
        self.errorMapper = ErrorMapper(defaultTimeout: configuration.defaultTimeout)

        self.requestBuilder = RequestBuilder(
            baseURL: configuration.baseURL,
            defaultHeaders: configuration.defaultHeaders,
            defaultTimeout: configuration.defaultTimeout,
            defaultCachePolicy: configuration.defaultCachePolicy,
            defaultDecoder: configuration.decoder
        )

        if configuration.connectivityCheckEnabled {
            let reachability = NetworkReachability()
            reachability.startMonitoring()
            self.reachability = reachability
        } else {
            self.reachability = nil
        }

        let urlConfig = configuration.urlSessionConfiguration
        urlConfig.timeoutIntervalForRequest = configuration.defaultTimeout
        urlConfig.timeoutIntervalForResource = configuration.defaultTimeout * 2

        self.session = Session(
            configuration: urlConfig,
            rootQueue: configuration.rootQueue,
            requestQueue: configuration.requestQueue,
            serializationQueue: configuration.serializationQueue,
            interceptor: Interceptor(interceptors: configuration.interceptors),
            serverTrustManager: configuration.serverTrustManager,
            redirectHandler: configuration.redirectHandler,
            cachedResponseHandler: configuration.cachedResponseHandler,
            eventMonitors: configuration.eventMonitors
        )
    }

    deinit { reachability?.stopMonitoring() }

    /// Convenience initializer with base URL only.
    ///
    /// - Parameter baseURL: Default base URL for requests
    public convenience init(baseURL: String) {
        self.init(configuration: .default(baseURL: baseURL))
    }

    /// Convenience initializer without base URL.
    ///
    /// Use this when each request will provide its own baseURL.
    public convenience init() {
        self.init(configuration: .default(baseURL: nil))
    }

    // MARK: - Public Methods

    /// Executes a network request and returns the decoded response.
    ///
    /// - Parameter endpoint: The endpoint to execute
    /// - Returns: Decoded response of type `E.Response`
    /// - Throws: `ASCError`
    public func execute<E: Endpoint>(_ endpoint: E) async throws -> E.Response {
        try await executeRequest(endpoint, responseType: E.Response.self)
    }

    /// Executes a network request with Empty response type.
    ///
    /// Useful for requests that return 204 No Content or similar.
    ///
    /// - Parameter endpoint: The endpoint to execute
    /// - Returns: Decoded `Empty` response
    /// - Throws: `ASCError`
    public func execute<E: Endpoint>(_ endpoint: E) async throws where E.Response == Empty {
        _ = try await executeRequest(endpoint, responseType: Empty.self)
    }

    public func download(
        from url: URL,
        to destinationFolderURL: URL?,
        options: DownloadRequest.Options = [.createIntermediateDirectories, .removePreviousFile]
    ) async throws -> URL? {
        try Task.checkCancellation()
        try checkConnectivity()

        let interceptor = buildRequestInterceptor(nil, retryPolicy: nil)
        let destination = buildDownloadDestination(to: destinationFolderURL, options: options)
        let downloadRequest = session.download(url, interceptor: interceptor, to: destination)

        // Set request priority
        downloadRequest.task?.priority = configuration.defaultPriority

        // Apply automatic validation if enabled
        let validatedRequest = configuration.automaticValidation
            ? downloadRequest.validate(statusCode: configuration.acceptableStatusCodes)
            : downloadRequest
        let serializedRequest = validatedRequest.serializingDownloadedFileURL()

        return try await withTaskCancellationHandler {
            let fileURL = try await serializedRequest.value
            return fileURL
        } onCancel: {
            downloadRequest.cancel()
        }
    }

    public func download<E: Endpoint>(
        _ endpoint: E,
        to destinationFolderURL: URL?,
        options: DownloadRequest.Options = [.createIntermediateDirectories, .removePreviousFile]
    ) async throws -> URL? {
        try Task.checkCancellation()
        try checkConnectivity()

        let interceptor = buildRequestInterceptor(endpoint, retryPolicy: endpoint.retryPolicy)
        let destination = buildDownloadDestination(to: destinationFolderURL, options: options)
        let urlRequest = try requestBuilder.buildURLRequest(from: endpoint)
        let downloadRequest = session.download(
            urlRequest,
            interceptor: interceptor,
            to: destination
        )

        // Set request priority
        downloadRequest.task?.priority = configuration.defaultPriority

        // Apply automatic validation if enabled
        let validatedRequest = configuration.automaticValidation
            ? downloadRequest.validate(statusCode: configuration.acceptableStatusCodes)
            : downloadRequest
        let serializedRequest = validatedRequest.serializingDownloadedFileURL()

        return try await withTaskCancellationHandler {
            let fileURL = try await serializedRequest.value
            return fileURL
        } onCancel: {
            downloadRequest.cancel()
        }
    }

//    /// Executes a network request with file upload and returns progress stream.
//    ///
//    /// Use this method when you need to track upload progress for file uploads.
//    /// Returns an AsyncThrowingStream that yields progress updates as the upload progresses.
//    ///
//    /// - Parameter request: The request to execute (must have uploadData property set)
//    /// - Returns: AsyncThrowingStream with UploadProgress updates, followed by the final response
//    /// - Throws: `ASCError` if request doesn't have uploadData or if upload fails
//    public func executeWithProgress<E: Endpoint>(
//        _ request: E
//    ) -> AsyncThrowingStream<UploadProgressOrResponse<E.Response>, Error> {
//        AsyncThrowingStream { continuation in
//            Task { @Sendable in
//                do {
//                    guard let uploadData = request.uploadData else {
//                        continuation.finish(throwing: ASCError.invalidFormat("Request must have uploadData property set to use executeWithProgress"))
//                        return
//                    }
//
//                    try Task.checkCancellation()
//                    try checkConnectivity()
//
//                    let url = try requestBuilder.buildURL(from: request)
//                    let interceptor = buildRequestInterceptor(request, retryPolicy: request.retryPolicy)
//
//                    // Create upload request using centralized method
//                    let uploadRequest = try createUploadRequest(request, uploadData: uploadData, url: url, interceptor: interceptor)
//
//                    // Set request priority
//                    uploadRequest.task?.priority = configuration.defaultPriority
//
//                    // Apply automatic validation if enabled
//                    let validatedRequest = configuration.automaticValidation
//                        ? uploadRequest.validate(statusCode: configuration.acceptableStatusCodes)
//                        : uploadRequest
//
//                    // Track upload progress before execution
//                    uploadRequest.uploadProgress { progress in
//                        let uploadProgress = UploadProgress(
//                            fractionCompleted: progress.fractionCompleted,
//                            bytesUploaded: progress.completedUnitCount,
//                            totalBytes: progress.totalUnitCount
//                        )
//                        continuation.yield(.progress(uploadProgress))
//                    }
//
//                    // Execute request using same serialization logic as performUploadRequest
//                    // Note: We can't use performUploadRequest directly because we need access to UploadRequest
//                    // for progress tracking before execution
//                    let serializedRequest = validatedRequest.serializingDecodable(
//                        Request.Response.self,
//                        decoder: configuration.decoder
//                    )
//
//                    let response = await serializedRequest.response
//                    let value = try handleResponse(response)
//                    try request.validate(response: value)
//
//                    continuation.yield(.response(value))
//                    continuation.finish()
//                } catch {
//                    continuation.finish(throwing: error)
//                }
//            }
//        }
//    }

    // MARK: - Private Methods
    private func buildRequestInterceptor(_ endpoint: (any Endpoint)?, retryPolicy: Alamofire.RetryPolicy?) -> Interceptor {
        let effectiveRetryPolicy = retryPolicy ?? configuration.defaultRetryPolicy
        let authInterceptor = (endpoint?.enableAuthorization ?? false) ? configuration.authInterceptor : nil
        var interceptors: [any RequestInterceptor] = []

        if let effectiveRetryPolicy {
            interceptors.append(effectiveRetryPolicy)
        }
        if let authInterceptor {
            interceptors.append(authInterceptor)
        }

        let interceptor: Interceptor = .init(interceptors: interceptors)
        return interceptor
    }

    /// Executes a network request.
    ///
    /// Centralized request execution that always uses decoding.
    /// - Parameters:
    ///   - endpoint: The network endpoint to execute
    ///   - responseType: Expected response type
    /// - Returns: Decoded response
    /// - Throws: `ASCError`
    private func executeRequest<E: Endpoint, Response: Decodable & Sendable>(
        _ endpoint: E,
        responseType: Response.Type
    ) async throws -> Response where E.Response == Response {
        // Check if this is an upload request
        if let uploadData = endpoint.uploadData {
            let url = try requestBuilder.buildURL(from: endpoint)
            let interceptor = buildRequestInterceptor(endpoint, retryPolicy: endpoint.retryPolicy)

            return try await performUploadRequest(
                endpoint,
                uploadData: uploadData,
                url: url,
                interceptor: interceptor,
                responseType: responseType
            )
        }

        // Regular request (non-upload)
        let urlRequest = try requestBuilder.buildURLRequest(from: endpoint)

        return try await performRequest(
            endpoint,
            urlRequest: urlRequest,
            responseType: responseType,
            retryPolicy: endpoint.retryPolicy
        )
    }

    // MARK: - Data Request Handling

    /// Performs the actual network request using Alamofire.
    ///
    /// Supports Task cancellation - when the Swift Task is cancelled,
    /// the underlying Alamofire request is automatically cancelled.
    ///
    /// Calls request.validate() on successful response.
    private func performRequest<E: Endpoint, Response: Decodable & Sendable>(
        _ endpoint: E,
        urlRequest: URLRequest,
        responseType: Response.Type,
        retryPolicy: Alamofire.RetryPolicy?
    ) async throws -> Response where E.Response == Response {
        try Task.checkCancellation()
        try checkConnectivity()

        let interceptor = buildRequestInterceptor(endpoint, retryPolicy: retryPolicy)
        let dataRequest = session.request(urlRequest, interceptor: interceptor)

        // Set request priority
        dataRequest.task?.priority = configuration.defaultPriority

        // Apply automatic validation if enabled
        let validatedRequest = configuration.automaticValidation
            ? dataRequest.validate(statusCode: configuration.acceptableStatusCodes)
            : dataRequest
        let serializedRequest = validatedRequest.serializingDecodable(
            Response.self,
            decoder: configuration.decoder
        )

        return try await withTaskCancellationHandler {
            let response = await serializedRequest.response
            let value = try handleResponse(response)

            try endpoint.validate(response: value)

            return value
        } onCancel: {
            dataRequest.cancel()
        }
    }

    // MARK: - Upload Request Handling

    /// Performs an upload request with file upload.
    ///
    /// Handles all three types of uploads: .data, .file, and .multipart
    private func performUploadRequest<E: Endpoint, Response: Decodable & Sendable>(
        _ endpoint: E,
        uploadData: UploadData,
        url: URL,
        interceptor: Interceptor,
        responseType: Response.Type
    ) async throws -> Response where E.Response == Response {
        try Task.checkCancellation()
        try checkConnectivity()

        // Create upload request using centralized method
        let uploadRequest = try createUploadRequest(endpoint, uploadData: uploadData, url: url, interceptor: interceptor)

        // Set request priority
        uploadRequest.task?.priority = configuration.defaultPriority

        // Apply automatic validation if enabled
        let validatedRequest = configuration.automaticValidation
            ? uploadRequest.validate(statusCode: configuration.acceptableStatusCodes)
            : uploadRequest

        let serializedRequest = validatedRequest.serializingDecodable(
            Response.self,
            decoder: configuration.decoder
        )

        return try await withTaskCancellationHandler {
            let response = await serializedRequest.response
            let value = try handleResponse(response)

            try endpoint.validate(response: value)

            return value
        } onCancel: {
            uploadRequest.cancel()
        }
    }

    /// Creates an UploadRequest from UploadData configuration.
    ///
    /// Centralized method for creating upload requests to avoid code duplication.
    /// Handles all three types of uploads: .data, .file, and .multipart
    ///
    /// - Parameters:
    ///   - endpoint: The network endpoint
    ///   - uploadData: Upload data configuration
    ///   - url: Target URL for upload
    ///   - interceptor: Request interceptor
    /// - Returns: Configured UploadRequest
    /// - Throws: ASCError if file validation fails
    private func createUploadRequest<E: Endpoint>(
        _ endpoint: E,
        uploadData: UploadData,
        url: URL,
        interceptor: Interceptor
    ) throws -> UploadRequest {
        switch uploadData {
        case let .data(data):
            // Upload Data directly from memory
            return session.upload(data, to: url, interceptor: interceptor)

        case let .file(fileURL):
            // Upload File from file system (memory-efficient)
            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                throw ASCError.invalidFormat("File does not exist at path: \(fileURL.path)")
            }
            return session.upload(fileURL, to: url, interceptor: interceptor)

        case let .multipart(items):
            // Validate files exist before creating multipart
            for item in items {
                if case let .file(_, fileURL, _, _) = item {
                    guard FileManager.default.fileExists(atPath: fileURL.path) else {
                        throw ASCError.invalidFormat("File does not exist at path: \(fileURL.path)")
                    }
                }
            }

            // Pre-encode parameters before entering the non-throwing multipart closure
            let encodedParameters: [(String, Data)]
            if let parameters = endpoint.parameters {
                encodedParameters = try encodeParametersForMultipart(parameters)
            } else {
                encodedParameters = []
            }

            // Upload Multipart Form Data
            return session.upload(
                multipartFormData: { multipartFormData in
                    // Add pre-encoded parameters
                    for (key, data) in encodedParameters {
                        multipartFormData.append(data, withName: key)
                    }

                    // Add multipart items
                    for item in items {
                        switch item {
                        case let .data(fieldName, data, fileName, mimeType):
                            multipartFormData.append(data, withName: fieldName, fileName: fileName, mimeType: mimeType)

                        case let .file(fieldName, fileURL, fileName, mimeType):
                            if let fileName, let mimeType {
                                multipartFormData.append(fileURL, withName: fieldName, fileName: fileName, mimeType: mimeType)
                            } else {
                                multipartFormData.append(fileURL, withName: fieldName)
                            }

                        case let .parameter(fieldName, value):
                            if let valueData = value.data(using: .utf8) {
                                multipartFormData.append(valueData, withName: fieldName)
                            }
                        }
                    }
                },
                to: url,
                interceptor: interceptor
            )
        }
    }

    /// Encodes parameters into an array of (fieldName, data) pairs for multipart upload.
    ///
    /// Each top-level key of the `Encodable` becomes a separate multipart field.
    /// Scalar values are UTF-8 strings; nested objects/arrays become compact JSON.
    ///
    /// - Throws: `ASCError.invalidFormat` if the encoded value is not a JSON object.
    private func encodeParametersForMultipart<Params: Encodable & Sendable>(
        _ parameters: Params
    ) throws -> [(String, Data)] {
        let jsonData = try JSONEncoder().encode(parameters)

        guard let jsonObject = try? JSONSerialization.jsonObject(with: jsonData),
              let dictionary = jsonObject as? [String: Any] else {
            throw ASCError.invalidFormat("Multipart parameters must encode to a JSON object")
        }

        var result: [(String, Data)] = []
        for (key, value) in dictionary {
            let fieldData: Data?
            if let string = value as? String {
                fieldData = string.data(using: .utf8)
            } else if let number = value as? NSNumber {
                fieldData = number.stringValue.data(using: .utf8)
            } else {
                // Nested object or array: serialize as compact JSON
                fieldData = try? JSONSerialization.data(withJSONObject: value)
            }

            if let data = fieldData {
                result.append((key, data))
            }
        }
        return result
    }

    private func buildDownloadDestination(to destinationFolderURL: URL?, options: DownloadRequest.Options) -> DownloadRequest.Destination? {
        return { temporaryURL, response in
            let filename = response.suggestedFilename ?? "file.\(UUID().uuidString)"

            let destinationURL = destinationFolderURL?.appendingPathComponent(filename)
            let defaultURL = temporaryURL.deletingLastPathComponent().appendingPathComponent(filename)
            let url = destinationURL ?? defaultURL

            return (url, options)
        }
    }

    // MARK: - Response Handling

    /// Validates response and extracts value.
    ///
    /// Checks for errors and ensures response value is present.
    ///
    /// - Parameter response: Data response from Alamofire
    /// - Returns: Extracted response value
    /// - Throws: Mapped error or ASCError.missingData
    private func handleResponse<T>(_ response: DataResponse<T, AFError>) throws -> T {
        if let error = response.error {
            throw errorMapper.mapError(error, data: response.data)
        }

        guard let value = response.value else {
            throw ASCError.missingData
        }

        return value
    }

    // MARK: - Connectivity Check

    /// Checks network connectivity before making a request.
    /// - Throws: ASCError.noConnection if no connection available
    private func checkConnectivity() throws {
        guard let reachability = reachability else { return }

        if case .unreachable = reachability.currentStatus {
            throw ASCError.noConnection
        }
    }
}

// MARK: - Upload Progress

/// Progress information for file uploads.
public struct UploadProgress: Sendable {
    /// Fraction of upload completed (0.0 to 1.0).
    public let fractionCompleted: Double

    /// Number of bytes uploaded so far.
    public let bytesUploaded: Int64

    /// Total number of bytes to upload.
    public let totalBytes: Int64

    public init(fractionCompleted: Double, bytesUploaded: Int64, totalBytes: Int64) {
        self.fractionCompleted = fractionCompleted
        self.bytesUploaded = bytesUploaded
        self.totalBytes = totalBytes
    }
}

/// Represents either upload progress or final response.
public enum UploadProgressOrResponse<Response: Sendable>: Sendable {
    /// Upload progress update.
    case progress(UploadProgress)

    /// Final response after upload completes.
    case response(Response)
}
