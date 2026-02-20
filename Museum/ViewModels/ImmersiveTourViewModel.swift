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
    var immersiveTourViewModel: Factory<ImmersiveTourViewModel> {
        self { @MainActor in ImmersiveTourViewModel() }
            .shared
    }
}

// MARK: - Protocol

protocol ImmersiveTourViewModeling: ObservableObject {
    var currentSpotIndex: Int { get }
    var currentSpot: Asset.TourSpot? { get }
    var canGoNext: Bool { get }
    var canGoPrevious: Bool { get }
    func configure(for asset: Asset)
    func goToNext()
    func goToPrevious()
    func entityOrientation(for spot: Asset.TourSpot) -> simd_quatf
}

// MARK: - Implementation

final class ImmersiveTourViewModel: ImmersiveTourViewModeling, ObservableObject {

    @Published private(set) var currentSpotIndex: Int = 0

    private var asset: Asset = .warship

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

    init() {
        setupBindings()
    }

    func configure(for asset: Asset) {
        self.asset = asset
        currentSpotIndex = 0
    }

    func goToNext() {
        guard canGoNext else { return }
        currentSpotIndex = (currentSpotIndex + 1) % asset.tourSpots.count
    }

    func goToPrevious() {
        guard canGoPrevious else { return }
        currentSpotIndex -= 1
    }

    func entityOrientation(for spot: Asset.TourSpot) -> simd_quatf {
        let euler = spot.entityOrientation
        let qx = simd_quatf(angle: euler.x, axis: SIMD3<Float>(1, 0, 0))
        let qy = simd_quatf(angle: euler.y, axis: SIMD3<Float>(0, 1, 0))
        let qz = simd_quatf(angle: euler.z, axis: SIMD3<Float>(0, 0, 1))
        return qy * qx * qz
    }
}

// MARK: - Private

private extension ImmersiveTourViewModel {
    func setupBindings() {}
}
