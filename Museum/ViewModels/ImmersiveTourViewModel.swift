//
//  ImmersiveTourViewModel.swift
//  Museum
//
//  Created by Vitor Cesco on 26/02/19.
//

import FactoryKit
import simd
import SwiftUI
import Combine

// MARK: - DI Registration

extension Container {
    @MainActor
    var immersiveTourViewModel: ParameterFactory<Asset, ImmersiveTourViewModel> {
        self { @MainActor in ImmersiveTourViewModel(asset: $0) }
            .scopeOnParameters.shared
    }
}

// MARK: - Protocol

protocol ImmersiveTourViewModeling: ObservableObject {
    var currentSpotIndex: Int { get }
    var currentSpot: Asset.TourSpot? { get }
    var canGoNext: Bool { get }
    var canGoPrevious: Bool { get }
    func goToNext()
    func goToPrevious()
    func entityOrientation(for spot: Asset.TourSpot) -> simd_quatf
}

// MARK: - Implementation

final class ImmersiveTourViewModel: ImmersiveTourViewModeling, ObservableObject {

    @Published private(set) var currentSpotIndex: Int = 0

    let asset: Asset
    private let logger: any Logging

    var currentSpot: Asset.TourSpot? {
        let spots = asset.tourSpots
        guard spots.indices.contains(currentSpotIndex) else { return nil }
        return spots[currentSpotIndex]
    }

    var canGoNext: Bool {
        asset.tourSpots.count > 1
    }

    var canGoPrevious: Bool {
        currentSpotIndex > 0
    }

    init(
        asset: Asset,
        logger: any Logging = Container.shared.logOperator("ImmersiveTourViewModel")
    ) {
        self.asset = asset
        self.logger = logger
        logger.debug("init \(asset.rawValue)")
    }

    deinit { logger.debug("deinit \(asset.rawValue)") }

    func goToNext() {
        guard canGoNext else { return }
        logger.info("Moving to next tour spot")
        currentSpotIndex = (currentSpotIndex + 1) % asset.tourSpots.count
    }

    func goToPrevious() {
        guard canGoPrevious else { return }
        logger.info("Moving to previous tour spot")
        currentSpotIndex -= 1
    }

    func entityOrientation(for spot: Asset.TourSpot) -> simd_quatf {
        let euler = spot.entityOrientation
        let qx = simd_quatf(angle: euler.x, axis: SIMD3<Float>(1, 0, 0))
        let qy = simd_quatf(angle: euler.y, axis: SIMD3<Float>(0, 1, 0))
        let qz = simd_quatf(angle: euler.z, axis: SIMD3<Float>(0, 0, 1))

        let orientation = qy * qx * qz
        logger.debug(
            "Orientation for spot \(spot.title)[\(spot.entityOrientation)]: \(orientation)"
        )
        return orientation
    }
}
