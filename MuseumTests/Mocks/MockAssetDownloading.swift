//
//  MockAssetDownloading.swift
//  MuseumTests
//
//  Created by Vitor Cesco on 18/02/26.
//

import Foundation
@testable import Museum

final class MockAssetDownloading: AssetDownloading, @unchecked Sendable {

    var results: [Result<Data, Error>] = []
    var onDownloadCalled: (@Sendable (URL) async throws -> Void)?
    var shouldYieldCompletedEvent = true
    var overrideCompletedURL: URL?
    private(set) var downloadCallCount = 0
    private(set) var lastRequestedURL: URL?

    func download(from url: URL) -> AsyncThrowingStream<AssetDownloadEvent, Error> {
        downloadCallCount += 1
        lastRequestedURL = url

        let index = min(downloadCallCount - 1, results.count - 1)
        let result = results[index]
        let hook = onDownloadCalled
        let shouldComplete = shouldYieldCompletedEvent
        let overrideURL = overrideCompletedURL

        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    try await hook?(url)

                    let data = try result.get()

                    continuation.yield(.progress(0.5))

                    if shouldComplete {
                        let fileURL: URL
                        if let overrideURL {
                            fileURL = overrideURL
                        } else {
                            fileURL = FileManager.default.temporaryDirectory
                                .appendingPathComponent(UUID().uuidString)
                            FileManager.default.createFile(atPath: fileURL.path(), contents: data)
                        }
                        continuation.yield(.completed(fileURL))
                    }

                    continuation.finish()
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
