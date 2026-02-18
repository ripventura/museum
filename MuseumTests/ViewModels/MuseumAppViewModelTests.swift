//
//  MuseumAppViewModelTests.swift
//  MuseumTests
//
//  Created by Vitor Cesco on 18/02/26.
//

import Testing
@testable import Museum


@MainActor
struct MuseumAppViewModelTests {

    private let mockLogger = MockLogging()

    // MARK: - Initial State

    @Test("Initial state is loading")
    func initialStateIsLoading() {
        let sut = makeSUT()

        guard case .loading = sut.loadingState else {
            Issue.record("Expected .loading, got \(sut.loadingState)")
            return
        }
    }

    @Test("isLoading is false before startLoading is called")
    func isLoadingIsFalseInitially() {
        let sut = makeSUT()

        #expect(sut.isLoading == false)
    }

    // MARK: - Loading

    @Test("Loading completes to loaded state")
    func loadingCompletesToLoaded() async {
        let sut = makeSUT()
        sut.startLoading()

        await awaitLoadingCompletion(sut)

        guard case .loaded = sut.loadingState else {
            Issue.record("Expected .loaded, got \(sut.loadingState)")
            return
        }
    }

    // MARK: - Loading Gate

    @Test("startLoading sets isLoading to true")
    func startLoadingSetsIsLoading() {
        let sut = makeSUT()
        sut.startLoading()

        #expect(sut.isLoading == true)
    }

    @Test("isLoading resets to false after loading completes")
    func isLoadingResetsAfterCompletion() async {
        let sut = makeSUT()
        sut.startLoading()

        await awaitLoadingCompletion(sut)

        #expect(sut.isLoading == false)
    }

    @Test("Calling startLoading while already loading is ignored")
    func startLoadingWhileLoadingIsIgnored() {
        let sut = makeSUT()
        sut.startLoading()
        sut.startLoading()

        let warningCount = mockLogger.entries.filter {
            $0.level == "warning" && $0.message.contains("already loading")
        }.count
        #expect(warningCount == 1)
    }

    // MARK: - Retry

    @Test("Retry resets state to loading before completing")
    func retryResetsToLoading() async {
        let sut = makeSUT()
        sut.startLoading()
        await awaitLoadingCompletion(sut)

        sut.retry()

        guard case .loading = sut.loadingState else {
            Issue.record("Expected .loading after retry, got \(sut.loadingState)")
            return
        }
    }

    @Test("Retry completes to loaded state")
    func retryCompletesToLoaded() async {
        let sut = makeSUT()
        sut.startLoading()
        await awaitLoadingCompletion(sut)

        sut.retry()
        await awaitLoadingCompletion(sut)

        guard case .loaded = sut.loadingState else {
            Issue.record("Expected .loaded after retry, got \(sut.loadingState)")
            return
        }
    }
}

// MARK: - Private


@MainActor
private extension MuseumAppViewModelTests {

    func makeSUT() -> MuseumAppViewModel {
        MuseumAppViewModel(logger: mockLogger)
    }

    func awaitLoadingCompletion(_ sut: MuseumAppViewModel) async {
        while sut.isLoading {
            await Task.yield()
        }
    }
}
