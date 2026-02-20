//
//  AssetDetailView.swift
//  Museum
//
//  Created by Vitor Cesco on 26/02/19.
//

import SwiftUI
import RealityKit
import FactoryKit
import Equatable

@Equatable
struct AssetDetailView: View {
    let asset: Asset
    let url: URL

    @ObservedObject private var immersiveSpaceController = Container.shared.immersiveSpaceController()

    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissWindow) private var dismissWindow

    @State private var hasLoadedModel = false

    var body: some View {
        Group {
            if immersiveSpaceController.phase != .open {
                Model3D(url: url) {
                    if let model = $0.model {
                        model
                            .resizable()
                            .scaledToFit()
                            .offset(z: CGFloat(asset.offsetZ ?? 0))
                            .onAppear { hasLoadedModel = true }
                            .onDisappear { hasLoadedModel = false }
                    } else if let error = $0.error {
                        ContentUnavailableView(
                            "Invalid Model",
                            systemImage: "photo.badge.exclamationmark.fill",
                            description: Text(error.localizedDescription)
                        )
                    }
                }
            }
        }
        .ornament(
            visibility: hasLoadedModel ? .visible : .hidden,
            attachmentAnchor: .scene(.top)
        ) {
            Text(asset.title)
                .font(.title)
        }
        .ornament(
            visibility: isLoadingExperience ? .visible : .hidden,
            attachmentAnchor: .scene(.top)
        ) {
            VStack {
                ProgressView()
                Text("Loading experience...")
            }
            .font(.headline)
        }
        .ornament(
            visibility: !isLoadingExperience ? .visible : .hidden,
            attachmentAnchor: .scene(.bottomFront)
        ) {
            Button("View Immersive") {
                openImmersive()
            }
        }
    }
}

// MARK: - Private

private extension AssetDetailView {
    var isLoadingExperience: Bool {
        !hasLoadedModel || immersiveSpaceController.phase != .closed
    }

    func openImmersive() {
        immersiveSpaceController.phase = .opening
        Task {
            let result = await openImmersiveSpace(id: Constants.immersiveSpaceId)
            switch result {
            case .opened:
                immersiveSpaceController.phase = .open
                dismissWindow(id: Constants.volumetricSpaceId)
            case .userCancelled:
                immersiveSpaceController.phase = .closed
            case .error:
                immersiveSpaceController.phase = .closed
            @unknown default:
                immersiveSpaceController.phase = .closed
            }
        }
    }
}
