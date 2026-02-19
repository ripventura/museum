//
//  ContentView.swift
//  Museum
//
//  Created by Vitor Cesco on 18/02/26.
//

import SwiftUI
import FactoryKit

struct ContentView: View {
    @ObservedObject private var viewModel = Container.shared.assetDisplayViewModel()

    var body: some View {
        Group {
            switch viewModel.state {
            case .loading(let progress):
                AssetLoadingView(progress: progress)
            case .loaded(let url):
                AssetDetailView(url: url)
            case .failed:
                failureContent
            }
        }
        .onAppear {
            viewModel.startLoading()
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
    ContentView()
}
