//
//  AssetTests.swift
//  MuseumTests
//
//  Created by Vitor Cesco on 18/02/26.
//

import Testing
@testable import Museum

struct AssetTests {

    @Test("Asset cache key equals its raw value")
    func assetCacheKey() {
        #expect(Asset.warship.value == "KM1PUvbAai5kXm8")
    }
}
