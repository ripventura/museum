//
//  MockCacheOperator.swift
//  MuseumTests
//
//  Created by Vitor Cesco on 18/02/26.
//

import Foundation
@testable import Museum

final class MockCacheOperator: CacheOperatorProtocol, @unchecked Sendable {

    private(set) var savedEntries: [(key: String, url: URL)] = []
    private var storage: [String: URL] = [:]

    func save(_ sourceURL: URL, for key: any CacheKeyProtocol) async {
        savedEntries.append((key: key.value, url: sourceURL))
        storage[key.value] = sourceURL
    }

    func retrieve(at key: any CacheKeyProtocol) async -> URL? {
        storage[key.value]
    }
}
