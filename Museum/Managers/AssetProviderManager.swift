//
//  AssetProviderManager.swift
//  Museum
//
//  Created by Vitor Cesco on 18/02/26.
//

import FactoryKit
import Foundation

// MARK: - DI Registration

extension Container {
    var assetProviderManager: Factory<any AssetProviding> {
        self { AssetProviderManager() }
            .singleton
    }
}

// MARK: - Protocol

nonisolated protocol AssetProviding: Sendable {
    func provide(
        _ asset: Asset,
        strategy: RetryStrategy,
        onProgress: (@Sendable (Float) -> Void)?
    ) async throws -> Data
}

extension AssetProviding {
    func provide(_ asset: Asset, strategy: RetryStrategy) async throws -> Data {
        try await provide(asset, strategy: strategy, onProgress: nil)
    }
}

// MARK: - Error

nonisolated enum AssetProviderError: Error, Sendable, Equatable {
    case downloadFailed(String)
    case fileReadFailed(String)
}

// MARK: - Implementation

nonisolated final class AssetProviderManager: AssetProviding, @unchecked Sendable {

    private let cacheEngine: any CacheOperatorProtocol
    private let downloader: any AssetDownloading
    private let logger: any Logging

    init(
        cacheEngine: any CacheOperatorProtocol = Container.shared.cacheEngine(),
        downloader: any AssetDownloading = Container.shared.assetDownloadOperator(),
        logger: any Logging = Container.shared.logOperator("AssetProviderManager")
    ) {
        self.cacheEngine = cacheEngine
        self.downloader = downloader
        self.logger = logger
    }

    func provide(
        _ asset: Asset,
        strategy: RetryStrategy,
        onProgress: (@Sendable (Float) -> Void)?
    ) async throws -> Data {
        logger.debug("Provide requested for asset '\(asset.rawValue)'")

        if let cached = await cacheEngine.retrieve(at: asset) {
            logger.info("Cache hit for asset '\(asset.rawValue)'")
            return cached
        }

        logger.info("Cache miss for asset '\(asset.rawValue)', starting download")

        let data = try await downloadWithRetry(asset: asset, strategy: strategy, onProgress: onProgress)

        await cacheEngine.save(data, for: asset)
        logger.debug("Cached asset '\(asset.rawValue)'")

        return data
    }
}

// MARK: - Private

private extension AssetProviderManager {

    func downloadWithRetry(
        asset: Asset,
        strategy: RetryStrategy,
        onProgress: (@Sendable (Float) -> Void)?
    ) async throws -> Data {
        var lastError: Error?

        for attempt in 0...strategy.maxAttempts {
            try Task.checkCancellation()

            if attempt > 0 {
                let delay = strategy.delay(forAttempt: attempt - 1)
                logger.warning("Retrying asset '\(asset.rawValue)' — attempt \(attempt + 1)/\(strategy.maxAttempts + 1) after \(delay)")
                try await Task.sleep(for: delay)
            } else {
                logger.debug("Download attempt 1/\(strategy.maxAttempts + 1) for asset '\(asset.rawValue)'")
            }

            do {
                let data = try await performDownload(asset: asset, onProgress: onProgress)
                logger.info("Download succeeded for asset '\(asset.rawValue)' on attempt \(attempt + 1)")
                return data
            } catch is CancellationError {
                logger.warning("Download cancelled for asset '\(asset.rawValue)'")
                throw CancellationError()
            } catch {
                lastError = error
                logger.error("Download failed for asset '\(asset.rawValue)' on attempt \(attempt + 1): \(error)")
            }
        }

        logger.error("All \(strategy.maxAttempts + 1) attempts exhausted for asset '\(asset.rawValue)'")
        throw AssetProviderError.downloadFailed(lastError?.localizedDescription ?? "Unknown error")
    }

    func performDownload(asset: Asset, onProgress: (@Sendable (Float) -> Void)?) async throws -> Data {
        let url = url(for: asset)
        let stream = downloader.download(from: url)

        var fileURL: URL?

        for try await event in stream {
            switch event {
            case .progress(let fraction):
                logger.debug("Download progress for '\(asset.rawValue)': \(Int(fraction * 100))%")
                onProgress?(fraction)
            case .completed(let url):
                fileURL = url
            }
        }

        guard let fileURL else {
            throw AssetProviderError.downloadFailed("Stream completed without a file URL")
        }

        do {
            let data = try Data(contentsOf: fileURL)
            try? FileManager.default.removeItem(at: fileURL)
            return data
        } catch {
            throw AssetProviderError.fileReadFailed(error.localizedDescription)
        }
    }

    func url(for asset: Asset) -> URL {
        Constants.assetBaseURL
            .appendingPathComponent(asset.rawValue)
            .appendingPathComponent("/download")
    }
}
