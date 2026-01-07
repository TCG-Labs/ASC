//
//  BaseEventMonitor.swift
//  ASC
//
//  Created by Vyacheslav Razumeenko on 06.01.2026.
//

import Foundation

extension Data {
    var toString: String {
        .init(bytes: self, encoding: .utf8) ?? ""
    }

    // NSString gives us a nice sanitized debugDescription
    var prettyPrintedJSONString: NSString? {
        guard
            let object = try? JSONSerialization.jsonObject(with: self, options: []),
            let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]),
            let prettyPrintedString = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
        else { return nil }

        return prettyPrintedString
    }
}

public final class BaseEventMonitor: EventMonitor {
    public let queue = DispatchQueue(label: "\(Bundle.main.bundleIdentifier ?? "").networklogger")

    public init() { }

    // MARK: - Multipart Upload
    public func request(_ request: UploadRequest, didCreateUploadable uploadable: UploadRequest.Uploadable) {
        var body = "nil"
        if case .data(let data) = uploadable {
            body = data.toString
        }
        log.debug("multipart data: \n\(body)")
    }

    // MARK: - Response
//    public func requestDidFinish(_ request: Request) {
//        guard let statusCode = request.response?.statusCode else {
//            log.error("⛔️ Cancel: \(request.description)")
//            return
//        }
//
//        log.debug("\n✅ \(request.description)\n🔸 Status code: \(statusCode)")
//    }

//    public func request<Value>(
//        _ request: DataRequest,
//        didParseResponse response: DataResponse<Value, AFError>
//    ) {
//        guard
//            let data = response.data
//        else {
//            log.error("\n🔸 Data: nil")
//            return
//        }
//
//        log.debug("\n🔸 Data: \(data.prettyPrintedJSONString ?? .init())")
//
//        do {
//            _ = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
//            log.debug("\n👍🏼 Serialization: OK")
//        } catch let error {
//            log.error("‼️ Serialization: \(error.localizedDescription)")
//        }
//    }

    public func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        log.debug("progress: \(progress)")
    }
}
