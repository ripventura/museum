//
//  MockCacheOperator.swift
//  MuseumTests
//
//  Created by Vitor Cesco on 18/02/26.
//

import Foundation
@testable import Museum

final class MockCacheOperator: CacheOperatorProtocol, @unchecked Sendable {

    private(set) var savedEntries: [(key: String, data: Data)] = []
    private var storage: [String: Data] = [:]

    func save(_ data: Data, for key: any CacheKeyProtocol) async {
        savedEntries.append((key: key.value, data: data))
        storage[key.value] = data
    }

    func retrieve(at key: any CacheKeyProtocol) async -> Data? {
        storage[key.value]
    }
}
