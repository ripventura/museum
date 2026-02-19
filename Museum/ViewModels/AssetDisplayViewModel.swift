//
//  AssetDisplayViewModel.swift
//  Museum
//
//  Created by Vitor Cesco on 26/02/19.
//

import Combine
import FactoryKit
import Foundation

// MARK: - DI Registration

extension Container {
    @MainActor
    var assetDisplayViewModel: Factory<AssetDisplayViewModel> {
        self { @MainActor in AssetDisplayViewModel() }
            .shared
    }
}

// MARK: - Protocol

protocol AssetDisplayViewModeling: ObservableObject {
    var state: AssetDisplayState { get }
    func startLoading()
    func retry()
}

// MARK: - Implementation

final class AssetDisplayViewModel: AssetDisplayViewModeling, ObservableObject {

    @Published private(set) var state: AssetDisplayState = .loading(progress: 0)
    private(set) var isLoading: Bool = false

    private let assetProvider: any AssetProviding
    private let logger: any Logging

    init(
        assetProvider: any AssetProviding = Container.shared.assetProviderManager(),
        logger: any Logging = Container.shared.logOperator("AssetDisplayViewModel")
    ) {
        self.assetProvider = assetProvider
        self.logger = logger
        setupBindings()
    }

    func startLoading() {
        guard !isLoading else {
            logger.warning("startLoading() called while already loading — ignoring")
            return
        }
        isLoading = true
        state = .loading(progress: 0)
        Task.detached { [weak self] in
            await self?.performLoad()
        }
    }

    func retry() {
        logger.info("User requested retry")
        isLoading = false
        startLoading()
    }
}

// MARK: - Private

private extension AssetDisplayViewModel {

    func setupBindings() {}

    func performLoad() async {
        let strategy = RetryStrategy(
            maxAttempts: 2,
            initialDelay: .seconds(1),
            maxDelay: .seconds(8)
        )

        do {
            let url = try await assetProvider.provide(
                .warship,
                strategy: strategy
            ) { [weak self] progress in
                Task { @MainActor [weak self] in
                    guard let self, self.isLoading else { return }
                    self.state = .loading(progress: progress)
                }
            }
            state = .loaded(url: url)
            logger.info("Asset loaded successfully")
        } catch {
            state = .failed(error)
            logger.error("Asset loading failed: \(error)")
        }
        isLoading = false
    }
}
