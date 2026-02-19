//
//  MuseumApp.swift
//  Museum
//
//  Created by Vitor Cesco on 18/02/26.
//

import SwiftUI
import FactoryKit

@main
struct MuseumApp: App {
    @ObservedObject private var viewModel = Container.shared.museumAppViewModel()
    @ObservedObject private var immersiveSpaceController = Container.shared.immersiveSpaceController()
    private let isRunningTests: Bool

    init() {
        isRunningTests = NSClassFromString("XCTestProbe") != nil

        if !isRunningTests {
            viewModel.startLoading()
        }
    }

    var body: some Scene {
        WindowGroup {
            switch viewModel.loadingState {
            case .loading:
                loadingContent
            case .loaded:
                ContentView()
            case .failed:
                failureContent
            }
        }
        .windowStyle(.volumetric)
        .defaultSize(width: 1, height: 1, depth: 0.5, in: .meters)

        ImmersiveSpace(id: Constants.immersiveSpaceId) {
            ImmersiveAssetView()
        }
        .immersionStyle(selection: .constant(.full), in: .full)
    }
}

// MARK: - Private

private extension MuseumApp {

    var loadingContent: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading…")
                .foregroundStyle(.secondary)
        }
    }

    var failureContent: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.red)
            Text("Something went wrong")
            Button("Try Again") {
                viewModel.retry()
            }
        }
    }
}
