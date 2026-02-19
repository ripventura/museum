//
//  URLSessionDownloader.swift
//  Museum
//
//  Created by Vitor Cesco on 26/02/19.
//

import Foundation

// MARK: - Implementation

nonisolated final class URLSessionDownloader: URLSessionDownloading, @unchecked Sendable {

    private let configuration: URLSessionConfiguration

    init(configuration: URLSessionConfiguration = .default) {
        self.configuration = configuration
    }

    func download(
        from url: URL,
        onProgress: (@Sendable (Float) -> Void)?
    ) async throws -> (URL, URLResponse) {
        let delegate = DownloadDelegate(onProgress: onProgress)
        let session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                delegate.continuation = continuation
                let task = session.downloadTask(with: url)
                task.resume()
            }
        } onCancel: {
            session.invalidateAndCancel()
        }
    }
}

// MARK: - Private

private extension URLSessionDownloader {

    final class DownloadDelegate: NSObject, URLSessionDownloadDelegate, @unchecked Sendable {

        let onProgress: (@Sendable (Float) -> Void)?
        var continuation: CheckedContinuation<(URL, URLResponse), Error>?
        var downloadedFileURL: URL?

        init(onProgress: (@Sendable (Float) -> Void)?) {
            self.onProgress = onProgress
        }

        nonisolated func urlSession(
            _ session: URLSession,
            downloadTask: URLSessionDownloadTask,
            didWriteData bytesWritten: Int64,
            totalBytesWritten: Int64,
            totalBytesExpectedToWrite: Int64
        ) {
            guard totalBytesExpectedToWrite > 0 else { return }
            let fraction = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
            onProgress?(min(max(fraction, 0.0), 1.0))
        }

        nonisolated func urlSession(
            _ session: URLSession,
            downloadTask: URLSessionDownloadTask,
            didFinishDownloadingTo location: URL
        ) {
            let stableURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)

            do {
                try FileManager.default.moveItem(at: location, to: stableURL)
                downloadedFileURL = stableURL
            } catch {
                // File move failed — didCompleteWithError will fire next and surface the issue.
            }
        }

        nonisolated func urlSession(
            _ session: URLSession,
            task: URLSessionTask,
            didCompleteWithError error: (any Error)?
        ) {
            if let error {
                continuation?.resume(throwing: error)
                return
            }

            guard let fileURL = downloadedFileURL,
                  let response = task.response else {
                continuation?.resume(throwing: AssetDownloadError.invalidResponse)
                return
            }

            continuation?.resume(returning: (fileURL, response))
        }
    }
}
