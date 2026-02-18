//
//  AssetDownloadOperator.swift
//  Museum
//
//  Created by Vitor Cesco on 18/02/26.
//

import FactoryKit
import Foundation

// MARK: - Download Event

nonisolated enum AssetDownloadEvent: Sendable {
    /// Fractional progress update (0.0 to 1.0).
    case progress(Float)
    /// Download completed; contains the temporary file URL.
    case completed(URL)
}

// MARK: - Error

nonisolated enum AssetDownloadError: Error, Sendable, Equatable {
    /// The server returned an HTTP error status code.
    case httpError(statusCode: Int)
    /// The server response was not a valid HTTP URL response.
    case invalidResponse
    /// Failed to move the downloaded file to a stable temporary location.
    case fileOperationFailed(String)
}

// MARK: - URLSession Protocol

nonisolated protocol URLSessionDownloading: Sendable {
    func download(
        from url: URL,
        delegate: (any URLSessionTaskDelegate)?
    ) async throws -> (URL, URLResponse)
}

extension URLSession: URLSessionDownloading {}

// MARK: - AssetDownloading Protocol

nonisolated protocol AssetDownloading: Sendable {
    /// Starts downloading an asset from the given URL.
    ///
    /// Returns an `AsyncThrowingStream` that emits:
    /// - `.progress(Float)` with values in 0.0...1.0 as data is received
    /// - `.completed(URL)` once the file has been saved to a temporary location
    ///
    /// The stream throws `AssetDownloadError` on failure.
    /// Cancelling the consuming `Task` cancels the download.
    func download(from url: URL) -> AsyncThrowingStream<AssetDownloadEvent, Error>
}

// MARK: - Implementation

nonisolated final class AssetDownloadOperator: AssetDownloading, @unchecked Sendable {

    private let session: any URLSessionDownloading
    private let fileManager: FileManager

    init(session: any URLSessionDownloading, fileManager: FileManager = .default) {
        self.session = session
        self.fileManager = fileManager
    }

    func download(from url: URL) -> AsyncThrowingStream<AssetDownloadEvent, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let fileURL = try await performDownload(from: url, continuation: continuation)
                    continuation.yield(.completed(fileURL))
                    continuation.finish()
                } catch is CancellationError {
                    continuation.finish(throwing: CancellationError())
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }
}

// MARK: - DI Registration

extension Container {
    var assetDownloadOperator: Factory<any AssetDownloading> {
        self { AssetDownloadOperator(session: URLSession.shared) }
    }
}

// MARK: - Private

private extension AssetDownloadOperator {

    func performDownload(
        from url: URL,
        continuation: AsyncThrowingStream<AssetDownloadEvent, Error>.Continuation
    ) async throws -> URL {
        let progressDelegate = DownloadProgressDelegate { fraction in
            continuation.yield(.progress(fraction))
        }

        let (tempURL, response) = try await session.download(
            from: url,
            delegate: progressDelegate
        )

        try validate(response)

        return try moveToStableLocation(from: tempURL, preservingExtensionOf: url)
    }

    func validate(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AssetDownloadError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw AssetDownloadError.httpError(statusCode: httpResponse.statusCode)
        }
    }

    func moveToStableLocation(from tempURL: URL, preservingExtensionOf originalURL: URL) throws -> URL {
        let stableURL = fileManager.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(originalURL.pathExtension)

        do {
            try fileManager.moveItem(at: tempURL, to: stableURL)
        } catch {
            throw AssetDownloadError.fileOperationFailed(error.localizedDescription)
        }

        return stableURL
    }

    final class DownloadProgressDelegate: NSObject, URLSessionDownloadDelegate, Sendable {

        private let onProgress: @Sendable (Float) -> Void

        init(onProgress: @escaping @Sendable (Float) -> Void) {
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
            onProgress(min(max(fraction, 0.0), 1.0))
        }

        nonisolated func urlSession(
            _ session: URLSession,
            downloadTask: URLSessionDownloadTask,
            didFinishDownloadingTo location: URL
        ) {
            // No-op: the async download(from:delegate:) API handles completion.
        }
    }
}
