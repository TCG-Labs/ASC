//
//  DownloadExampleView.swift
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

import SwiftUI
import ASC

// MARK: - Download Example View

/// View demonstrating file download capabilities through ASC.
///
/// This view shows how to:
/// - Download files from direct URL
/// - Download files via Endpoint
/// - Visual display of downloaded images
/// - Track download history
struct DownloadExampleView: View {
    @StateObject private var viewModel = DownloadExampleViewModel()

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Configuration Section
                configurationSection

                // MARK: - Download Section
                downloadSection

                // MARK: - Progress Section
                if viewModel.isLoading || viewModel.downloadProgress != nil {
                    progressSection
                }

                // MARK: - Image Preview Section
                if viewModel.downloadedFileURL != nil {
                    imagePreviewSection
                }

                // MARK: - History Section
                if !viewModel.downloadHistory.isEmpty {
                    historySection
                }

                // MARK: - Error Section
                if let errorMessage = viewModel.errorMessage {
                    errorSection(message: errorMessage)
                }
            }
            .navigationTitle("Download Demo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if viewModel.downloadedFileURL != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            viewModel.clearDownload()
                        } label: {
                            Image(systemName: "trash")
                        }
                    }
                }
            }
        }
    }

    // MARK: - Configuration Section

    private var configurationSection: some View {
        Section("Configuration") {
            Picker("Download Method", selection: $viewModel.downloadMethod) {
                ForEach(DownloadMethod.allCases, id: \.self) { method in
                    Text(method.rawValue).tag(method)
                }
            }

            Picker("Image Size", selection: $viewModel.selectedImageSize) {
                ForEach(ImageSize.allCases, id: \.self) { size in
                    Text(size.rawValue).tag(size)
                }
            }
        }
    }

    // MARK: - Download Section

    private var downloadSection: some View {
        Section("Actions") {
            Button {
                Task {
                    await viewModel.downloadImage(imageSize: viewModel.selectedImageSize)
                }
            } label: {
                HStack {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(.blue)
                    Text("Download Image")
                }
            }
            .disabled(viewModel.isLoading)

            if viewModel.downloadedFileURL != nil {
                Button {
                    viewModel.retryDownload()
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Retry Download")
                    }
                }
                .disabled(viewModel.isLoading)
            }
        }
    }

    // MARK: - Progress Section

    private var progressSection: some View {
        Section("Progress") {
            if viewModel.isLoading {
                ProgressView(value: viewModel.downloadProgress, total: 1.0) {
                    Text("Downloading...")
                        .font(.caption)
                } currentValueLabel: {
                    if let progress = viewModel.downloadProgress {
                        Text("\(Int(progress * 100))%")
                            .font(.caption)
                    }
                }
            } else if let progress = viewModel.downloadProgress {
                ProgressView(value: progress, total: 1.0) {
                    Text("Completed")
                        .font(.caption)
                } currentValueLabel: {
                    Text("\(Int(progress * 100))%")
                        .font(.caption)
                }
                .tint(.green)
            }
        }
    }

    // MARK: - Image Preview Section

    private var imagePreviewSection: some View {
        Section("Downloaded Image") {
            if let fileURL = viewModel.downloadedFileURL {
                VStack(spacing: 12) {
                    // Display image from local file
                    imagePreview(fileURL: fileURL)

                    // File information
                    if let selectedFile = viewModel.selectedFile {
                        fileInfoView(file: selectedFile)
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }

    // MARK: - Image Preview

    private func imagePreview(fileURL: URL) -> some View {
        Group {
            if let data = try? Data(contentsOf: fileURL),
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: 300)
                    .cornerRadius(12)
                    .shadow(radius: 5)
            } else {
                Image(systemName: "photo")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
            }
        }
    }

    // MARK: - File Info View

    private func fileInfoView(file: DownloadedFile) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            LabeledContent("Method") {
                Text(file.method.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            LabeledContent("Size") {
                Text(file.imageSize.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            LabeledContent("File Name") {
                Text(file.fileName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.trailing)
            }

            LabeledContent("Downloaded At") {
                Text(file.downloadedAt, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let fileSize = getFileSize(url: file.fileURL) {
                LabeledContent("File Size") {
                    Text(fileSize)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - History Section

    private var historySection: some View {
        Section("Download History") {
            ForEach(viewModel.downloadHistory) { file in
                Button {
                    viewModel.selectFile(file)
                } label: {
                    HStack {
                        // File icon
                        Image(systemName: "photo.fill")
                            .foregroundColor(.blue)
                            .frame(width: 30)

                        // File info
                        VStack(alignment: .leading, spacing: 4) {
                            Text(file.fileName)
                                .font(.subheadline)
                                .foregroundColor(.primary)

                            HStack {
                                Text(file.method.rawValue)
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Text("•")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Text(file.imageSize.rawValue)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        // Selection indicator
                        if viewModel.selectedFile?.id == file.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        viewModel.removeFromHistory(file)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
    }

    // MARK: - Error Section

    private func errorSection(message: String) -> some View {
        Section("Error") {
            Text(message)
                .foregroundColor(.red)
                .font(.caption)
        }
    }

    // MARK: - Helper Methods

    /// Gets the file size as a formatted string.
    ///
    /// - Parameter url: The file URL
    /// - Returns: Formatted file size string, or nil if unable to read file
    private func getFileSize(url: URL) -> String? {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let fileSize = attributes[.size] as? Int64 else {
            return nil
        }

        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
}

// MARK: - Preview

#Preview {
    DownloadExampleView()
}

