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

    @Test("Saves file and returns its URL for a given key")
    func saveAndRetrieve() async throws {
        let sut = DiskCacheOperator(timeToLive: 3600, cachesURL: testDirectory, logger: mockLogger)
        let key = TestCacheKey(value: "test-key")

        let sourceURL = makeTempFile(contents: Data("hello".utf8))
        await sut.save(sourceURL, for: key)

        let retrieved = await sut.retrieve(at: key)
        #expect(retrieved != nil)
        #expect(FileManager.default.fileExists(atPath: retrieved!.path()))
        #expect(!FileManager.default.fileExists(atPath: sourceURL.path()))

        let contents = try Data(contentsOf: retrieved!)
        #expect(contents == Data("hello".utf8))
    }

    @Test("Returns nil for a missing key")
    func retrieveMissingKeyReturnsNil() async {
        let sut = DiskCacheOperator(timeToLive: 3600, cachesURL: testDirectory, logger: mockLogger)
        let key = TestCacheKey(value: "nonexistent")

        let result = await sut.retrieve(at: key)
        #expect(result == nil)
    }

    @Test("Overwrites existing cached file for the same key")
    func overwriteExistingKey() async throws {
        let sut = DiskCacheOperator(timeToLive: 3600, cachesURL: testDirectory, logger: mockLogger)
        let key = TestCacheKey(value: "overwrite-key")

        let source1 = makeTempFile(contents: Data("original".utf8))
        let source2 = makeTempFile(contents: Data("updated".utf8))

        await sut.save(source1, for: key)
        await sut.save(source2, for: key)

        let retrieved = await sut.retrieve(at: key)
        let contents = try Data(contentsOf: retrieved!)
        #expect(contents == Data("updated".utf8))
    }

    @Test("Different keys store separate files")
    func differentKeysAreIsolated() async throws {
        let sut = DiskCacheOperator(timeToLive: 3600, cachesURL: testDirectory, logger: mockLogger)
        let key1 = TestCacheKey(value: "key-1")
        let key2 = TestCacheKey(value: "key-2")

        let source1 = makeTempFile(contents: Data("data-1".utf8))
        let source2 = makeTempFile(contents: Data("data-2".utf8))

        await sut.save(source1, for: key1)
        await sut.save(source2, for: key2)

        let retrieved1 = await sut.retrieve(at: key1)
        let retrieved2 = await sut.retrieve(at: key2)

        let contents1 = try Data(contentsOf: retrieved1!)
        let contents2 = try Data(contentsOf: retrieved2!)
        #expect(contents1 == Data("data-1".utf8))
        #expect(contents2 == Data("data-2".utf8))
    }

    // MARK: Directory Creation

    @Test("Creates cache directory if it does not exist")
    func createsCacheDirectoryIfNeeded() async {
        let nestedDir = testDirectory.appendingPathComponent("nested-test")
        let sut = DiskCacheOperator(timeToLive: 3600, cachesURL: nestedDir, logger: mockLogger)
        let key = TestCacheKey(value: "directory-test")

        let sourceURL = makeTempFile(contents: Data("test".utf8))
        await sut.save(sourceURL, for: key)

        let cacheOperatorDir = nestedDir.appendingPathComponent("CacheOperator")
        #expect(FileManager.default.fileExists(atPath: cacheOperatorDir.path))
    }

    // MARK: Expiration

    @Test("Returns nil for an expired entry")
    func expiredEntryReturnsNil() async throws {
        let sut = DiskCacheOperator(timeToLive: 0, cachesURL: testDirectory, logger: mockLogger)
        let key = TestCacheKey(value: "expired-key")

        let sourceURL = makeTempFile(contents: Data("will-expire".utf8))
        await sut.save(sourceURL, for: key)

        try await Task.sleep(for: .milliseconds(50))

        let retrieved = await sut.retrieve(at: key)
        #expect(retrieved == nil)
    }
}

// MARK: - Private

private extension DiskCacheOperatorTests {

    func makeTempFile(contents: Data) -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        FileManager.default.createFile(atPath: url.path(), contents: contents)
        return url
    }
}
