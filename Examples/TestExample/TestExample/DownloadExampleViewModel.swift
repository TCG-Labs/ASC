//
//  DownloadExampleViewModel.swift
//  TestExample
//
//  Created on 06.01.2026.
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
import SwiftUI
import ASC
import Combine

// MARK: - Download Method

/// Method for downloading files.
enum DownloadMethod: String, CaseIterable {
    case url = "From URL"
    case endpoint = "From Endpoint"
}

// MARK: - Image Size

/// Available image sizes for download.
enum ImageSize: String, CaseIterable {
    case small = "Small (400x300)"
    case medium = "Medium (800x600)"
    case large = "Large (1024x768)"

    var dimensions: (width: Int, height: Int) {
        switch self {
        case .small:
            return (400, 300)
        case .medium:
            return (800, 600)
        case .large:
            return (1024, 768)
        }
    }
}

// MARK: - Downloaded File

/// Information about a downloaded file.
struct DownloadedFile: Identifiable, Sendable {
    let id = UUID()
    let fileURL: URL
    let downloadedAt: Date
    let method: DownloadMethod
    let imageSize: ImageSize
    let fileName: String

    init(fileURL: URL, downloadedAt: Date, method: DownloadMethod, imageSize: ImageSize) {
        self.fileURL = fileURL
        self.downloadedAt = downloadedAt
        self.method = method
        self.imageSize = imageSize
        self.fileName = fileURL.lastPathComponent
    }
}

// MARK: - Download Example ViewModel

/// ViewModel demonstrating file download capabilities through ASC.
///
/// This ViewModel showcases:
/// - Downloading files from direct URL
/// - Downloading files via Endpoint
/// - Visual display of downloaded images
/// - Download history tracking
@MainActor
final class DownloadExampleViewModel: ObservableObject {
    // MARK: - Published Properties

    /// URL of the currently downloaded file.
    @Published var downloadedFileURL: URL?

    /// Download progress (0.0 to 1.0).
    @Published var downloadProgress: Double?

    /// Loading state indicator.
    @Published var isLoading = false

    /// Error message to display.
    @Published var errorMessage: String?

    /// Selected download method (URL or Endpoint).
    @Published var downloadMethod: DownloadMethod = .url

    /// Selected image size.
    @Published var selectedImageSize: ImageSize = .medium

    /// History of downloaded files.
    @Published var downloadHistory: [DownloadedFile] = []

    /// Currently selected file from history.
    @Published var selectedFile: DownloadedFile?

    // MARK: - Private Properties

    /// Network client for making requests.
    private let client: NetworkClient

    /// Last used image size for retry functionality.
    private var lastImageSize: ImageSize?

    // MARK: - Initialization

    /// Creates a new ViewModel with the specified network client.
    ///
    /// - Parameter client: Network client to use (defaults to DI container's default client)
    init(client: NetworkClient = DIContainer.shared.defaultClient()) {
        self.client = client
    }

    // MARK: - Public Methods

    /// Downloads an image from a direct URL.
    ///
    /// - Parameter imageSize: The size of the image to download
    func downloadFromURL(imageSize: ImageSize) async {
        isLoading = true
        errorMessage = nil
        downloadProgress = 0.0
        lastImageSize = imageSize

        do {
            let dimensions = imageSize.dimensions
            let url = "https://picsum.photos/\(dimensions.width)/\(dimensions.height)"

            // Create downloads directory
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let downloadsFolder = documentsPath.appendingPathComponent("Downloads")

            // Create directory if it doesn't exist
            try? FileManager.default.createDirectory(at: downloadsFolder, withIntermediateDirectories: true)

            // Download file
            let fileURL = try await client.download(
                from: url,
//                to: downloadsFolder,
                to: nil,
                options: [.createIntermediateDirectories, .removePreviousFile]
            )

            guard let fileURL = fileURL else {
                throw ASCError.missingData
            }

            downloadedFileURL = fileURL
            downloadProgress = 1.0

            // Add to history
            let downloadedFile = DownloadedFile(
                fileURL: fileURL,
                downloadedAt: Date(),
                method: .url,
                imageSize: imageSize
            )
            downloadHistory.insert(downloadedFile, at: 0)
            selectedFile = downloadedFile

            debugPrint("✅ Downloaded image from URL: \(fileURL)")
        } catch {
            errorMessage = "Download failed: \(error.localizedDescription)"
            downloadProgress = nil
            debugPrint("❌ Error downloading from URL: \(error)")
        }

        isLoading = false
    }

    /// Downloads an image via Endpoint.
    ///
    /// - Parameter imageSize: The size of the image to download
    func downloadFromEndpoint(imageSize: ImageSize) async {
        isLoading = true
        errorMessage = nil
        downloadProgress = 0.0
        lastImageSize = imageSize

        do {
            let dimensions = imageSize.dimensions
            let endpoint = DownloadImageEndpoint(
                imageId: Int.random(in: 1...1000),
                width: dimensions.width,
                height: dimensions.height
            )

            // Create downloads directory
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let downloadsFolder = documentsPath.appendingPathComponent("Downloads")

            // Create directory if it doesn't exist
            try? FileManager.default.createDirectory(at: downloadsFolder, withIntermediateDirectories: true)

            // Download file
            let fileURL = try await client.download(
                endpoint,
                to: downloadsFolder,
                options: [.createIntermediateDirectories, .removePreviousFile]
            )

            guard let fileURL = fileURL else {
                throw ASCError.missingData
            }

            downloadedFileURL = fileURL
            downloadProgress = 1.0

            // Add to history
            let downloadedFile = DownloadedFile(
                fileURL: fileURL,
                downloadedAt: Date(),
                method: .endpoint,
                imageSize: imageSize
            )
            downloadHistory.insert(downloadedFile, at: 0)
            selectedFile = downloadedFile

            debugPrint("✅ Downloaded image from Endpoint: \(fileURL)")
        } catch {
            errorMessage = "Download failed: \(error.localizedDescription)"
            downloadProgress = nil
            debugPrint("❌ Error downloading from Endpoint: \(error)")
        }

        isLoading = false
    }

    /// Downloads an image based on the selected method.
    ///
    /// - Parameter imageSize: The size of the image to download
    func downloadImage(imageSize: ImageSize) async {
        switch downloadMethod {
        case .url:
            await downloadFromURL(imageSize: imageSize)
        case .endpoint:
            await downloadFromEndpoint(imageSize: imageSize)
        }
    }

    /// Clears the current download.
    func clearDownload() {
        downloadedFileURL = nil
        downloadProgress = nil
        selectedFile = nil
        errorMessage = nil
    }

    /// Retries the last download.
    func retryDownload() {
        guard let imageSize = lastImageSize else {
            return
        }
        Task {
            await downloadImage(imageSize: imageSize)
        }
    }

    /// Selects a file from history for viewing.
    ///
    /// - Parameter file: The file to select
    func selectFile(_ file: DownloadedFile) {
        selectedFile = file
        downloadedFileURL = file.fileURL
    }

    /// Removes a file from history.
    ///
    /// - Parameter file: The file to remove
    func removeFromHistory(_ file: DownloadedFile) {
        downloadHistory.removeAll { $0.id == file.id }
        if selectedFile?.id == file.id {
            selectedFile = nil
            downloadedFileURL = nil
        }
    }
}

