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
    @ObservedObject private var tourViewModel = Container.shared.immersiveTourViewModel()
    @ObservedObject private var immersiveSpaceController = Container.shared.immersiveSpaceController()

    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace

    var body: some View {
        Group {
            if case .loaded(let url) = viewModel.state {
                RealityView { content, attachments in
                    tourViewModel.configure(for: viewModel.asset)

                    do {
                        let entity = try await ModelEntity(contentsOf: url)
                        entity.name = tourAssetEntityName

                        if let firstSpot = viewModel.asset.tourSpots.first {
                            applySpot(firstSpot, to: entity, animated: false)
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

                    if let tourPanel = attachments.entity(for: tourPanelAttachmentId) {
                        let headAnchor = AnchorEntity(.head)
                        tourPanel.position = SIMD3<Float>(-0.55, 0, -1)
                        headAnchor.addChild(tourPanel)
                        content.add(headAnchor)
                    }
                } update: { content, attachments in
                    guard
                        let spot = tourViewModel.currentSpot,
                        let entity = content.entities.first(where: { $0.name == tourAssetEntityName })
                    else { return }

                    applySpot(spot, to: entity, animated: true)
                } attachments: {
                    Attachment(id: exitButtonAttachmentId) {
                        Button("Exit Immersive") {
                            dismissImmersive()
                        }
                    }

                    Attachment(id: tourPanelAttachmentId) {
                        TourSpotPanelView(tourViewModel: tourViewModel)
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

    var tourAssetEntityName: String { "tourAssetEntity" }
    var exitButtonAttachmentId: String { "exitButton" }
    var tourPanelAttachmentId: String { "tourPanel" }

    func dismissImmersive() {
        Task {
            await dismissImmersiveSpace()
        }
    }

    func applySpot(_ spot: Asset.TourSpot, to entity: Entity, animated: Bool) {
        let orientation = tourViewModel.entityOrientation(for: spot)

        if animated {
            var transform = entity.transform
            transform.translation = spot.entityPosition
            transform.rotation = orientation
            entity
                .move(
                    to: transform,
                    relativeTo: nil,
                    duration: 1.2,
                    timingFunction: .easeInOut
                )
        } else {
            entity.position = spot.entityPosition
            entity.orientation = orientation
        }
    }
}
