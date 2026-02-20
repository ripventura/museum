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
    ) async throws -> URL
}

extension AssetProviding {
    func provide(_ asset: Asset, strategy: RetryStrategy) async throws -> URL {
        try await provide(asset, strategy: strategy, onProgress: nil)
    }
}

// MARK: - Error

nonisolated enum AssetProviderError: Error, Sendable, Equatable {
    case downloadFailed(String)
}

// MARK: - Implementation

nonisolated final class AssetProviderManager: AssetProviding, @unchecked Sendable {

    private let diskCache: any CacheOperatorProtocol
    private let downloader: any AssetDownloading
    private let logger: any Logging

    init(
        diskCache: any CacheOperatorProtocol = Container.shared.diskCacheOperator(),
        downloader: any AssetDownloading = Container.shared.assetDownloadOperator(),
        logger: any Logging = Container.shared.logOperator("AssetProviderManager")
    ) {
        self.diskCache = diskCache
        self.downloader = downloader
        self.logger = logger

        logger.debug("init")
    }

    deinit { logger.debug("deinit") }

    func provide(
        _ asset: Asset,
        strategy: RetryStrategy,
        onProgress: (@Sendable (Float) -> Void)?
    ) async throws -> URL {
        logger.debug("Provide requested for asset '\(asset.rawValue)'")

        if let cachedURL = await diskCache.retrieve(at: asset) {
            logger.info("Cache hit for asset '\(asset.rawValue)'")
            return cachedURL
        }

        logger.info("Cache miss for asset '\(asset.rawValue)', starting download")

        let tempURL = try await downloadWithRetry(asset: asset, strategy: strategy, onProgress: onProgress)

        await diskCache.save(tempURL, for: asset)
        logger.debug("Cached asset '\(asset.rawValue)'")

        guard let stableURL = await diskCache.retrieve(at: asset) else {
            throw AssetProviderError.downloadFailed("File was not found in cache after save")
        }

        return stableURL
    }
}

// MARK: - Private

private extension AssetProviderManager {

    func downloadWithRetry(
        asset: Asset,
        strategy: RetryStrategy,
        onProgress: (@Sendable (Float) -> Void)?
    ) async throws -> URL {
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
                let tempURL = try await performDownload(asset: asset, onProgress: onProgress)
                logger.info("Download succeeded for asset '\(asset.rawValue)' on attempt \(attempt + 1)")
                return tempURL
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

    func performDownload(asset: Asset, onProgress: (@Sendable (Float) -> Void)?) async throws -> URL {
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

        return fileURL
    }

    func url(for asset: Asset) -> URL {
        Constants.assetBaseURL
            .appendingPathComponent(asset.rawValue)
            .appendingPathComponent("/download")
    }
}
