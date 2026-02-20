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

    @Test("Warship title is USS Gato (SS-212)")
    func warshipTitle() {
        #expect(Asset.warship.title == "USS Gato (SS-212)")
    }

    @Test("Warship offsetZ is 400")
    func warshipOffsetZ() {
        #expect(Asset.warship.offsetZ == 400)
    }

    @Test("Warship has tour spots")
    func warshipTourSpots() {
        let spots = Asset.warship.tourSpots
        #expect(spots.count == 5)
        #expect(spots[0].title == "Forward Torpedo Room")
        #expect(spots[0].entityPosition == SIMD3<Float>(-10, -5, -10))
        #expect(spots[0].entityOrientation == SIMD3<Float>(0, .pi, 0))
    }
}
