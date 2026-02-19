//
//  ImmersiveAssetView.swift
//  Museum
//
//  Created by Vitor Cesco on 26/02/19.
//

import SwiftUI
import RealityKit
import FactoryKit

struct ImmersiveAssetView: View {
    @ObservedObject private var viewModel = Container.shared.assetDisplayViewModel()
    @ObservedObject private var immersiveSpaceController = Container.shared.immersiveSpaceController()

    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace

    var body: some View {
        Group {
            if case .loaded(let url) = viewModel.state {
                RealityView { content, attachments in
                    do {
                        let asset = viewModel.asset
                        let entity = try await ModelEntity(contentsOf: url)

                        if let euler = asset.orientation {
                            let qx = simd_quatf(angle: euler.x, axis: SIMD3<Float>(1, 0, 0))
                            let qy = simd_quatf(angle: euler.y, axis: SIMD3<Float>(0, 1, 0))
                            let qz = simd_quatf(angle: euler.z, axis: SIMD3<Float>(0, 0, 1))
                            entity.orientation = qy * qx * qz
                        }

                        if let position = asset.position {
                            entity.position = position
                        }

                        content.add(entity)
                    } catch {
                        // Entity load failure is non-fatal;
                        // the volumetric window remains available for retry
                    }

                    if let exitButton = attachments.entity(for: exitButtonAttachmentId) {
                        let headAnchor = AnchorEntity(.head)
                        exitButton.position = SIMD3<Float>(0, -0.45, -1)
                        headAnchor.addChild(exitButton)
                        content.add(headAnchor)
                    }
                } attachments: {
                    Attachment(id: exitButtonAttachmentId) {
                        Button("Exit Immersive") {
                            dismissImmersive()
                        }
                    }
                }
            }
        }
        .onDisappear {
            immersiveSpaceController.phase = .closed
        }
    }
}

// MARK: - Private

private extension ImmersiveAssetView {

    var exitButtonAttachmentId: String { "exitButton" }

    func dismissImmersive() {
        Task {
            await dismissImmersiveSpace()
        }
    }
}
