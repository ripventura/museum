//
//  MemoryCacheOperator.swift
//  Museum
//
//  Created by Vitor Cesco on 18/02/26.
//

import Foundation

nonisolated final class MemoryCacheOperator: CacheOperatorProtocol, @unchecked Sendable {

    private let cache: NSCache<NSString, NSData>

    init(limit: Int) {
        cache = NSCache<NSString, NSData>()
        cache.totalCostLimit = limit
    }

    func save(_ data: Data, for key: any CacheKeyProtocol) async {
        cache.setObject(data as NSData, forKey: key.value as NSString, cost: data.count)
    }

    func retrieve(at key: any CacheKeyProtocol) async -> Data? {
        guard let value = cache.object(forKey: key.value as NSString) else { return nil }
        return Data(value)
    }
}
