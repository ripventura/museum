//
//  AssetDetailView.swift
//  Museum
//
//  Created by Vitor Cesco on 26/02/19.
//

import SwiftUI
import RealityKit
import FactoryKit

struct AssetDetailView: View {
    let url: URL

    @ObservedObject private var immersiveSpaceController = Container.shared.immersiveSpaceController()

    @Environment(\.openImmersiveSpace) private var openImmersiveSpace

    @State private var hasLoadedModel = false

    var body: some View {
        Group {
            if immersiveSpaceController.phase != .open {
                Model3D(url: url) {
                    if let model = $0.model {
                        model
                            .resizable()
                            .scaledToFit()
                            .offset(z: 400)
                            .onAppear { hasLoadedModel = true }
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
        .ornament(attachmentAnchor: .scene(.bottomFront)) {
            if hasLoadedModel && immersiveSpaceController.phase == .closed {
                Button("View Immersive") {
                    openImmersive()
                }
            } else {
                VStack {
                    ProgressView()
                    Text("Loading experience...")
                }
                .font(.headline)
            }
        }
    }
}

// MARK: - Private

private extension AssetDetailView {

    func openImmersive() {
        immersiveSpaceController.phase = .opening
        Task {
            let result = await openImmersiveSpace(id: Constants.immersiveSpaceId)
            switch result {
            case .opened:
                immersiveSpaceController.phase = .open
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
