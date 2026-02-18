//
//  MuseumAppViewModel.swift
//  Museum
//
//  Created by Vitor Cesco on 18/02/26.
//

import Combine
import FactoryKit

// MARK: - DI Registration

extension Container {
    @MainActor
    var museumAppViewModel: Factory<MuseumAppViewModel> {
        self { @MainActor in MuseumAppViewModel() }
            .singleton
    }
}

// MARK: - Protocol

protocol MuseumAppViewModeling: ObservableObject {
    var loadingState: AppLoadingState { get }
    func startLoading()
    func retry()
}

// MARK: - Implementation

final class MuseumAppViewModel: MuseumAppViewModeling, ObservableObject {

    @Published private(set) var loadingState: AppLoadingState = .loading
    private(set) var isLoading: Bool = false

    private let logger: any Logging

    init(
        logger: any Logging = Container.shared.logOperator("MuseumAppViewModel")
    ) {
        self.logger = logger
    }

    func startLoading() {
        guard !isLoading else {
            logger.warning("startLoading() called while already loading — ignoring")
            return
        }
        isLoading = true
        loadingState = .loading
        Task.detached { [weak self] in
            await self?.performLoad()
        }
    }

    func retry() {
        logger.info("User requested retry")
        startLoading()
    }
}

// MARK: - Private

private extension MuseumAppViewModel {

    func performLoad() async {
        loadingState = .loaded
        isLoading = false
        logger.info("Root loading completed")
    }
}
