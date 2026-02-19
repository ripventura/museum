//
//  Asset.swift
//  Museum
//
//  Created by Vitor Cesco on 18/02/26.
//

import simd

nonisolated enum Asset: String, CaseIterable, Sendable, CacheKeyProtocol {
    case warship = "KM1PUvbAai5kXm8"

    var value: String { rawValue }
    var fileExtension: String? { "usdz" }

    var title: String {
        switch self {
        case .warship: "Warship"
        }
    }

    var offsetZ: Float? {
        switch self {
        case .warship: 400
        }
    }

    var position: SIMD3<Float>? {
        switch self {
        case .warship: SIMD3<Float>(-10, -5, -15)
        }
    }

    var orientation: SIMD3<Float>? {
        switch self {
        case .warship: SIMD3<Float>(0, .pi / 2, 0)
        }
    }
}
