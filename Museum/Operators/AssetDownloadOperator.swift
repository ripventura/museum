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
        onProgress: (@Sendable (Float) -> Void)?
    ) async throws -> (URL, URLResponse)
}

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
    private let logger: any Logging
    private let fileManager: FileManager

    init(
        session: any URLSessionDownloading = URLSessionDownloader(),
        logger: any Logging = Container.shared.logOperator("AssetDownloadOperator"),
        fileManager: FileManager = .default
    ) {
        self.session = session
        self.logger = logger
        self.fileManager = fileManager
    }

    func download(from url: URL) -> AsyncThrowingStream<AssetDownloadEvent, Error> {
        logger.debug("Downloading asset from \(url)")
        return AsyncThrowingStream { continuation in
            let task = Task { [weak self] in
                guard let self else { return }
                do {
                    let fileURL = try await self.performDownload(
                        from: url,
                        continuation: continuation
                    )
                    logger.debug("Asset downloaded to \(fileURL)")
                    continuation.yield(.completed(fileURL))
                    continuation.finish()
                } catch is CancellationError {
                    logger.debug("User cancelled asset download")
                    continuation.finish(throwing: CancellationError())
                } catch {
                    logger.error(
                        "Failed downloading asset: \(error.localizedDescription)"
                    )
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
        self { AssetDownloadOperator() }
    }
}

// MARK: - Private

private extension AssetDownloadOperator {

    func performDownload(
        from url: URL,
        continuation: AsyncThrowingStream<AssetDownloadEvent, Error>.Continuation
    ) async throws -> URL {
        let (tempURL, response) = try await session.download(from: url) { fraction in
            continuation.yield(.progress(fraction))
        }

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

        logger.debug("Moving downloaded file from \(tempURL) to \(stableURL)")

        do {
            try fileManager.moveItem(at: tempURL, to: stableURL)
        } catch {
            throw AssetDownloadError.fileOperationFailed(error.localizedDescription)
        }

        return stableURL
    }
}
