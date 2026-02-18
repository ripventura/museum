//
//  CacheEngineTests.swift
//  MuseumTests
//
//  Created by Vitor Cesco on 18/02/26.
//

import Foundation
import Testing
@testable import Museum

private struct TestCacheKey: CacheKeyProtocol {
    let value: String
}

struct CacheEngineTests {

    private let memoryMock = MockCacheOperator()
    private let diskMock = MockCacheOperator()

    // MARK: Save

    @Test("Save writes data to both memory and disk operators")
    func saveWritesToBothOperators() async {
        let sut = CacheEngine(memoryOperator: memoryMock, diskOperator: diskMock)
        let key = TestCacheKey(value: "dual-save")
        let data = Data("test".utf8)

        await sut.save(data, for: key)

        #expect(memoryMock.savedEntries.count == 1)
        #expect(diskMock.savedEntries.count == 1)
        #expect(memoryMock.savedEntries.first?.data == data)
        #expect(diskMock.savedEntries.first?.data == data)
    }

    // MARK: Retrieve

    @Test("Retrieve returns data from memory when available")
    func retrieveFromMemoryFirst() async {
        let sut = CacheEngine(memoryOperator: memoryMock, diskOperator: diskMock)
        let key = TestCacheKey(value: "memory-first")
        let memoryData = Data("from-memory".utf8)
        let diskData = Data("from-disk".utf8)

        await memoryMock.save(memoryData, for: key)
        await diskMock.save(diskData, for: key)

        let retrieved = await sut.retrieve(at: key)
        #expect(retrieved == memoryData)
    }

    @Test("Retrieve falls back to disk when memory misses")
    func retrieveFallsThroughToDisk() async {
        let sut = CacheEngine(memoryOperator: memoryMock, diskOperator: diskMock)
        let key = TestCacheKey(value: "disk-fallback")
        let diskData = Data("from-disk".utf8)

        await diskMock.save(diskData, for: key)

        let retrieved = await sut.retrieve(at: key)
        #expect(retrieved == diskData)
    }

    @Test("Disk hit populates memory for subsequent retrievals")
    func diskHitPopulatesMemory() async {
        let sut = CacheEngine(memoryOperator: memoryMock, diskOperator: diskMock)
        let key = TestCacheKey(value: "populate-memory")
        let diskData = Data("from-disk".utf8)

        await diskMock.save(diskData, for: key)

        _ = await sut.retrieve(at: key)

        let memoryResult = await memoryMock.retrieve(at: key)
        #expect(memoryResult == diskData)
    }

    @Test("Returns nil when both memory and disk miss")
    func retrieveMissingKeyReturnsNil() async {
        let sut = CacheEngine(memoryOperator: memoryMock, diskOperator: diskMock)
        let key = TestCacheKey(value: "missing")

        let result = await sut.retrieve(at: key)
        #expect(result == nil)
    }
}
