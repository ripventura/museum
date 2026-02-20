//
//  DiskCacheOperator.swift
//  Museum
//
//  Created by Vitor Cesco on 18/02/26.
//

import FactoryKit
import Foundation

// MARK: - DI Registration

extension Container {
    var diskCacheOperator: Factory<any CacheOperatorProtocol> {
        self {
            DiskCacheOperator(
                timeToLive: Constants.diskCacheTimeToLive,
                cachesURL: Constants.cacheURL,
                logger: self.logOperator("DiskCacheOperator")
            )
        }
    }
}

// MARK: - Implementation

nonisolated final class DiskCacheOperator: CacheOperatorProtocol, @unchecked Sendable {

    private let timeToLive: TimeInterval
    private let cachesURL: URL
    private let fileManager: FileManager
    private let logger: any Logging

    private var cacheDirectory: URL { cachesURL.appendingPathComponent("CacheOperator") }

    init(
        timeToLive: TimeInterval,
        cachesURL: URL,
        logger: any Logging,
        fileManager: FileManager = .default
    ) {
        self.timeToLive = timeToLive
        self.cachesURL = cachesURL
        self.logger = logger
        self.fileManager = fileManager

        setup()
        clearExpired()
    }

    func save(_ sourceURL: URL, for key: any CacheKeyProtocol) async {
        let destination = fileURL(for: key)
        do {
            if fileManager.fileExists(atPath: destination.path) {
                try fileManager.removeItem(at: destination)
            }
            try fileManager.moveItem(at: sourceURL, to: destination)
            logger.debug("Saved cache \(key.value) at \(destination)")
        } catch {
            assertionFailure("\(error)")
            logger.error("Failed to save cache \(key.value) on disk: \(error)")
        }
    }

    func retrieve(at key: any CacheKeyProtocol) async -> URL? {
        let url = fileURL(for: key)

        guard fileManager.fileExists(atPath: url.path) else {
            logger.debug(
                "Failed to retrieve cache \(key.value) as it's missing"
            )
            return nil
        }

        guard !isExpired(fileURL: url) else {
            try? fileManager.removeItem(at: url)
            logger.debug(
                "Failed to retrieve cache \(key.value) as it's already expired"
            )
            return nil
        }

        logger.debug("Retrieved cache \(key.value) from \(url)")

        return url
    }
}

// MARK: - Private

private extension DiskCacheOperator {

    func fileURL(for key: any CacheKeyProtocol) -> URL {
        let base = cacheDirectory.appendingPathComponent(key.value)
        guard let ext = key.fileExtension else { return base }
        return base.appendingPathExtension(ext)
    }

    func setup() {
        guard !fileManager.fileExists(atPath: cacheDirectory.path) else { return }

        logger.debug("Creating cache directory at \(cacheDirectory)")
        do {
            try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        } catch {
            assertionFailure("\(error)")
            logger.error("Failed to create cache directory: \(error)")
        }
    }

    func clearExpired() {
        do {
            for fileName in try fileManager.contentsOfDirectory(atPath: cacheDirectory.path) {
                let fileURL = cacheDirectory.appendingPathComponent(fileName)
                guard isExpired(fileURL: fileURL) else { continue }

                logger.debug("Clearing expired cache at \(fileURL)")
                try fileManager.removeItem(atPath: fileURL.path)
            }
        } catch {
            assertionFailure("\(error)")
            logger.error("Failed to clear expired cache: \(error)")
        }
    }

    func isExpired(fileURL: URL) -> Bool {
        do {
            let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
            guard let creationDate = attributes[.creationDate] as? Date else { return true }
            return Date().timeIntervalSince(creationDate) >= timeToLive
        } catch {
            return true
        }
    }
}
