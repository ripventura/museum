//
//  ContentView.swift
//  Museum
//
//  Created by Vitor Cesco on 18/02/26.
//

import SwiftUI
import FactoryKit

struct ContentView: View {
    let asset: Asset

    @ObservedObject private var viewModel: AssetDisplayViewModel

    init(asset: Asset) {
        self.asset = asset
        self.viewModel = Container.shared.assetDisplayViewModel(asset)
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle:
                ProgressView()
                    .onAppear {
                        viewModel.startLoading()
                    }
            case .loading(let progress):
                AssetLoadingView(progress: progress)
            case .loaded(let url):
                AssetDetailView(asset: viewModel.asset, url: url)
            case .failed:
                failureContent
            }
        }
    }
}

// MARK: - Private

private extension ContentView {

    var failureContent: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.red)
            Text("Failed to load asset")
            Button("Try Again") {
                viewModel.retry()
            }
        }
    }
}

#Preview(windowStyle: .automatic) {
    ContentView(asset: .warship)
}
