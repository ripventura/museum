//
//  AssetDisplayViewModelTests.swift
//  MuseumTests
//
//  Created by Vitor Cesco on 26/02/19.
//

import Foundation
import Testing
@testable import Museum

@MainActor
struct AssetDisplayViewModelTests {

    private let mockAssetProvider = MockAssetProviding()
    private let mockLogger = MockLogging()

    // MARK: - Initial State

    @Test("Initial state is loading with zero progress")
    func initialStateIsLoadingWithZeroProgress() {
        let sut = makeSUT()

        guard case .loading(let progress) = sut.state else {
            Issue.record("Expected .loading, got \(sut.state)")
            return
        }
        #expect(progress == 0)
    }

    @Test("isLoading is false before startLoading is called")
    func isLoadingIsFalseInitially() {
        let sut = makeSUT()

        #expect(sut.isLoading == false)
    }

    // MARK: - Loading Success

    @Test("Loading completes to loaded state with correct URL")
    func loadingCompletesToLoaded() async {
        let expectedURL = URL(filePath: "/tmp/test-asset.usdz")
        mockAssetProvider.result = .success(expectedURL)

        let sut = makeSUT()
        sut.startLoading()

        await awaitLoadingCompletion(sut)

        guard case .loaded(let url) = sut.state else {
            Issue.record("Expected .loaded, got \(sut.state)")
            return
        }
        #expect(url == expectedURL)
    }

    @Test("isLoading resets to false after successful load")
    func isLoadingResetsAfterSuccess() async {
        let sut = makeSUT()
        sut.startLoading()

        await awaitLoadingCompletion(sut)

        #expect(sut.isLoading == false)
    }

    // MARK: - Loading Failure

    @Test("Loading failure sets failed state")
    func loadingFailureSetsFailedState() async {
        mockAssetProvider.result = .failure(AssetProviderError.downloadFailed("test error"))

        let sut = makeSUT()
        sut.startLoading()

        await awaitLoadingCompletion(sut)

        guard case .failed = sut.state else {
            Issue.record("Expected .failed, got \(sut.state)")
            return
        }
    }

    @Test("isLoading resets to false after failed load")
    func isLoadingResetsAfterFailure() async {
        mockAssetProvider.result = .failure(AssetProviderError.downloadFailed("test error"))

        let sut = makeSUT()
        sut.startLoading()

        await awaitLoadingCompletion(sut)

        #expect(sut.isLoading == false)
    }

    // MARK: - Loading Gate

    @Test("startLoading sets isLoading to true")
    func startLoadingSetsIsLoading() {
        let sut = makeSUT()
        sut.startLoading()

        #expect(sut.isLoading == true)
    }

    @Test("Calling startLoading while already loading is ignored")
    func duplicateStartLoadingIsIgnored() {
        let sut = makeSUT()
        sut.startLoading()
        sut.startLoading()

        let warningCount = mockLogger.entries.filter {
            $0.level == "warning" && $0.message.contains("already loading")
        }.count
        #expect(warningCount == 1)
    }

    // MARK: - Retry

    @Test("Retry after failure resets state to loading")
    func retryAfterFailureResetsToLoading() async {
        mockAssetProvider.result = .failure(AssetProviderError.downloadFailed("test error"))

        let sut = makeSUT()
        sut.startLoading()
        await awaitLoadingCompletion(sut)

        mockAssetProvider.result = .success(URL(filePath: "/tmp/retried-asset"))
        sut.retry()

        guard case .loading = sut.state else {
            Issue.record("Expected .loading after retry, got \(sut.state)")
            return
        }
    }

    @Test("Retry after failure completes to loaded state")
    func retryCompletesToLoaded() async {
        mockAssetProvider.result = .failure(AssetProviderError.downloadFailed("test error"))

        let sut = makeSUT()
        sut.startLoading()
        await awaitLoadingCompletion(sut)

        let expectedURL = URL(filePath: "/tmp/retried-asset")
        mockAssetProvider.result = .success(expectedURL)
        sut.retry()
        await awaitLoadingCompletion(sut)

        guard case .loaded(let url) = sut.state else {
            Issue.record("Expected .loaded after retry, got \(sut.state)")
            return
        }
        #expect(url == expectedURL)
    }

    // MARK: - Provider Interaction

    @Test("Provider is called with warship asset")
    func providerCalledWithWarshipAsset() async {
        let sut = makeSUT()
        sut.startLoading()

        await awaitLoadingCompletion(sut)

        #expect(mockAssetProvider.lastAsset == .warship)
        #expect(mockAssetProvider.provideCallCount == 1)
    }
}

// MARK: - Private

@MainActor
private extension AssetDisplayViewModelTests {

    func makeSUT() -> AssetDisplayViewModel {
        AssetDisplayViewModel(
            assetProvider: mockAssetProvider,
            logger: mockLogger
        )
    }

    func awaitLoadingCompletion(_ sut: AssetDisplayViewModel) async {
        while sut.isLoading {
            await Task.yield()
        }
    }
}
