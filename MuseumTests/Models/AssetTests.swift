//
//  AssetTests.swift
//  MuseumTests
//
//  Created by Vitor Cesco on 18/02/26.
//

import simd
import Testing
@testable import Museum

struct AssetTests {

    @Test("Asset cache key equals its raw value")
    func assetCacheKey() {
        #expect(Asset.warship.value == "KM1PUvbAai5kXm8")
    }

    @Test("Asset file extension is usdz")
    func assetFileExtension() {
        #expect(Asset.warship.fileExtension == "usdz")
    }

    @Test("Warship title is Warship")
    func warshipTitle() {
        #expect(Asset.warship.title == "Warship")
    }

    @Test("Warship offsetZ is 400")
    func warshipOffsetZ() {
        #expect(Asset.warship.offsetZ == 400)
    }

    @Test("Warship position is (-10, -5, -15)")
    func warshipPosition() {
        #expect(Asset.warship.position == SIMD3<Float>(-10, -5, -15))
    }

    @Test("Warship orientation is (0, pi/2, 0)")
    func warshipOrientation() {
        #expect(Asset.warship.orientation == SIMD3<Float>(0, .pi / 2, 0))
    }
}
