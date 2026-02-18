//
//  DiskCacheOperatorTests.swift
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

struct DiskCacheOperatorTests {

    private let testDirectory: URL
    private let mockLogger = MockLogging()

    init() throws {
        testDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("DiskCacheOperatorTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: testDirectory, withIntermediateDirectories: true)
    }

    // MARK: Save & Retrieve

    @Test("Saves and retrieves data for a given key")
    func saveAndRetrieve() async {
        let sut = DiskCacheOperator(timeToLive: 3600, cachesURL: testDirectory, logger: mockLogger)
        let key = TestCacheKey(value: "test-key")
        let data = Data("hello".utf8)

        await sut.save(data, for: key)

        let retrieved = await sut.retrieve(at: key)
        #expect(retrieved == data)
    }

    @Test("Returns nil for a missing key")
    func retrieveMissingKeyReturnsNil() async {
        let sut = DiskCacheOperator(timeToLive: 3600, cachesURL: testDirectory, logger: mockLogger)
        let key = TestCacheKey(value: "nonexistent")

        let result = await sut.retrieve(at: key)
        #expect(result == nil)
    }

    @Test("Overwrites existing data for the same key")
    func overwriteExistingKey() async {
        let sut = DiskCacheOperator(timeToLive: 3600, cachesURL: testDirectory, logger: mockLogger)
        let key = TestCacheKey(value: "overwrite-key")
        let originalData = Data("original".utf8)
        let updatedData = Data("updated".utf8)

        await sut.save(originalData, for: key)
        await sut.save(updatedData, for: key)

        let retrieved = await sut.retrieve(at: key)
        #expect(retrieved == updatedData)
    }

    @Test("Different keys store separate values")
    func differentKeysAreIsolated() async {
        let sut = DiskCacheOperator(timeToLive: 3600, cachesURL: testDirectory, logger: mockLogger)
        let key1 = TestCacheKey(value: "key-1")
        let key2 = TestCacheKey(value: "key-2")
        let data1 = Data("data-1".utf8)
        let data2 = Data("data-2".utf8)

        await sut.save(data1, for: key1)
        await sut.save(data2, for: key2)

        let retrieved1 = await sut.retrieve(at: key1)
        let retrieved2 = await sut.retrieve(at: key2)
        #expect(retrieved1 == data1)
        #expect(retrieved2 == data2)
    }

    // MARK: Directory Creation

    @Test("Creates cache directory if it does not exist")
    func createsCacheDirectoryIfNeeded() async {
        let nestedDir = testDirectory.appendingPathComponent("nested-test")
        let sut = DiskCacheOperator(timeToLive: 3600, cachesURL: nestedDir, logger: mockLogger)
        let key = TestCacheKey(value: "directory-test")
        let data = Data("test".utf8)

        await sut.save(data, for: key)

        let cacheOperatorDir = nestedDir.appendingPathComponent("CacheOperator")
        #expect(FileManager.default.fileExists(atPath: cacheOperatorDir.path))
    }

    // MARK: Expiration

    @Test("Returns nil for an expired entry")
    func expiredEntryReturnsNil() async throws {
        let sut = DiskCacheOperator(timeToLive: 0, cachesURL: testDirectory, logger: mockLogger)
        let key = TestCacheKey(value: "expired-key")
        let data = Data("will-expire".utf8)

        await sut.save(data, for: key)

        try await Task.sleep(for: .milliseconds(50))

        let retrieved = await sut.retrieve(at: key)
        #expect(retrieved == nil)
    }
}
