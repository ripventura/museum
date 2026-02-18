//
//  AssetProviderManagerTests.swift
//  MuseumTests
//
//  Created by Vitor Cesco on 18/02/26.
//

import Foundation
import Testing
@testable import Museum

struct AssetProviderManagerTests {

    private let mockCache = MockCacheOperator()
    private let mockDownloader = MockAssetDownloading()
    private let mockLogger = MockLogging()

    private let defaultStrategy = RetryStrategy(
        maxAttempts: 2,
        initialDelay: .milliseconds(1),
        maxDelay: .milliseconds(10)
    )

    // MARK: - Cache

    @Test("Returns cached data without downloading")
    func cacheHitReturnsImmediately() async throws {
        let data = Data("cached".utf8)
        await mockCache.save(data, for: Asset.warship)

        let sut = makeSUT()
        let result = try await sut.provide(.warship, strategy: defaultStrategy)

        #expect(result == data)
        #expect(mockDownloader.downloadCallCount == 0)
    }

    @Test("Cache miss downloads and caches the data")
    func cacheMissDownloadsAndCaches() async throws {
        let data = Data("downloaded".utf8)
        mockDownloader.results = [.success(data)]

        let sut = makeSUT()
        let result = try await sut.provide(.warship, strategy: defaultStrategy)

        #expect(result == data)
        #expect(mockDownloader.downloadCallCount == 1)
        #expect(mockCache.savedEntries.count == 1)
        #expect(mockCache.savedEntries.first?.key == Asset.warship.value)
        #expect(mockCache.savedEntries.first?.data == data)
    }

    // MARK: - No Retry

    @Test("Download failure without retry throws immediately")
    func noRetryThrowsOnFailure() async {
        let strategy = RetryStrategy(
            maxAttempts: 0,
            initialDelay: .milliseconds(1),
            maxDelay: .milliseconds(1)
        )
        mockDownloader.results = [.failure(AssetDownloadError.httpError(statusCode: 500))]

        let sut = makeSUT()

        await #expect(throws: AssetProviderError.self) {
            try await sut.provide(.warship, strategy: strategy)
        }
        #expect(mockDownloader.downloadCallCount == 1)
        #expect(mockCache.savedEntries.isEmpty)
    }

    // MARK: - Exponential Backoff

    @Test("Exponential backoff succeeds on second attempt")
    func backoffSucceedsOnSecondAttempt() async throws {
        let data = Data("retry-success".utf8)
        mockDownloader.results = [
            .failure(AssetDownloadError.httpError(statusCode: 503)),
            .success(data)
        ]

        let sut = makeSUT()
        let result = try await sut.provide(.warship, strategy: defaultStrategy)

        #expect(result == data)
        #expect(mockDownloader.downloadCallCount == 2)
        #expect(mockCache.savedEntries.count == 1)
    }

    @Test("Exponential backoff exhausts all attempts")
    func backoffExhaustsAllAttempts() async {
        mockDownloader.results = [
            .failure(AssetDownloadError.httpError(statusCode: 500)),
            .failure(AssetDownloadError.httpError(statusCode: 500)),
            .failure(AssetDownloadError.httpError(statusCode: 500))
        ]

        let sut = makeSUT()

        await #expect(throws: AssetProviderError.self) {
            try await sut.provide(.warship, strategy: defaultStrategy)
        }
        // 1 initial + 2 retries
        #expect(mockDownloader.downloadCallCount == 3)
        #expect(mockCache.savedEntries.isEmpty)
    }

    @Test("Exponential backoff succeeds on last attempt")
    func backoffSucceedsOnLastAttempt() async throws {
        let data = Data("last-chance".utf8)
        mockDownloader.results = [
            .failure(AssetDownloadError.httpError(statusCode: 500)),
            .failure(AssetDownloadError.httpError(statusCode: 500)),
            .success(data)
        ]

        let sut = makeSUT()
        let result = try await sut.provide(.warship, strategy: defaultStrategy)

        #expect(result == data)
        #expect(mockDownloader.downloadCallCount == 3)
    }

    // MARK: - Cancellation

    @Test("Cancellation propagates without retrying")
    func cancellationDoesNotRetry() async {
        let downloadStarted = AsyncStream.makeStream(of: Void.self)

        mockDownloader.results = [.success(Data("never".utf8))]
        mockDownloader.onDownloadCalled = { _ in
            downloadStarted.continuation.yield()
            try await Task.sleep(for: .seconds(60))
        }

        let sut = makeSUT()

        let task = Task {
            try await sut.provide(.warship, strategy: defaultStrategy)
        }

        for await _ in downloadStarted.stream { break }
        task.cancel()

        let result = await task.result

        switch result {
        case .success:
            Issue.record("Expected cancellation error")
        case .failure(let error):
            #expect(error is CancellationError)
        }

        #expect(mockDownloader.downloadCallCount == 1)
        #expect(mockCache.savedEntries.isEmpty)
    }

    // MARK: - Stream Without Completed Event

    @Test("Stream completing without a completed event throws")
    func streamWithoutCompletedEventThrows() async {
        mockDownloader.results = [.success(Data("ignored".utf8))]
        mockDownloader.shouldYieldCompletedEvent = false

        let strategy = RetryStrategy(
            maxAttempts: 0,
            initialDelay: .milliseconds(1),
            maxDelay: .milliseconds(1)
        )

        let sut = makeSUT()

        await #expect(throws: AssetProviderError.self) {
            try await sut.provide(.warship, strategy: strategy)
        }
        #expect(mockCache.savedEntries.isEmpty)
    }

    // MARK: - File Read Failure

    @Test("File read failure throws error")
    func fileReadFailedThrows() async {
        mockDownloader.results = [.success(Data("valid".utf8))]
        mockDownloader.overrideCompletedURL = URL(filePath: "/nonexistent-\(UUID().uuidString)")

        let strategy = RetryStrategy(
            maxAttempts: 0,
            initialDelay: .milliseconds(1),
            maxDelay: .milliseconds(1)
        )

        let sut = makeSUT()

        await #expect(throws: AssetProviderError.self) {
            try await sut.provide(.warship, strategy: strategy)
        }
        #expect(mockCache.savedEntries.isEmpty)
    }

    // MARK: - Progress Callback

    @Test("Progress callback is invoked during download")
    func progressCallbackInvoked() async throws {
        let data = Data("progress-test".utf8)
        mockDownloader.results = [.success(data)]

        let sut = makeSUT()
        var receivedProgress: [Float] = []

        _ = try await sut.provide(.warship, strategy: defaultStrategy) { fraction in
            receivedProgress.append(fraction)
        }

        #expect(!receivedProgress.isEmpty)
        #expect(receivedProgress.contains(0.5))
    }

    @Test("Nil progress callback does not crash")
    func nilProgressCallbackDoesNotCrash() async throws {
        let data = Data("nil-progress".utf8)
        mockDownloader.results = [.success(data)]

        let sut = makeSUT()
        let result = try await sut.provide(.warship, strategy: defaultStrategy, onProgress: nil)

        #expect(result == data)
    }

    @Test("Progress callback not invoked on cache hit")
    func progressNotInvokedOnCacheHit() async throws {
        let data = Data("cached".utf8)
        await mockCache.save(data, for: Asset.warship)

        let sut = makeSUT()
        var progressCalled = false

        _ = try await sut.provide(.warship, strategy: defaultStrategy) { _ in
            progressCalled = true
        }

        #expect(!progressCalled)
    }

    // MARK: - Asset URL

    @Test("Asset URL is passed to downloader")
    func assetURLPassedToDownloader() async throws {
        let data = Data("url-check".utf8)
        mockDownloader.results = [.success(data)]

        let sut = makeSUT()
        _ = try await sut.provide(.warship, strategy: defaultStrategy)

        let expectedURL = Constants.assetBaseURL.appendingPathComponent(Asset.warship.rawValue)
        #expect(mockDownloader.lastRequestedURL == expectedURL)
    }
}

// MARK: - Private

private extension AssetProviderManagerTests {

    func makeSUT() -> AssetProviderManager {
        AssetProviderManager(
            cacheEngine: mockCache,
            downloader: mockDownloader,
            logger: mockLogger
        )
    }
}
