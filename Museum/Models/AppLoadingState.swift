//
//  AppLoadingState.swift
//  Museum
//
//  Created by Vitor Cesco on 18/02/26.
//

nonisolated enum AppLoadingState: Sendable {
    case loading
    case loaded
    case failed(Error)
}
