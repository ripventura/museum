//
//  CacheEngine.swift
//  Museum
//
//  Created by Vitor Cesco on 18/02/26.
//

import FactoryKit
import Foundation

// MARK: - DI Registration

extension Container {
    var cacheEngine: Factory<any CacheOperatorProtocol> {
        self { CacheEngine() }
            .singleton
    }
}

// MARK: - Implementation

nonisolated final class CacheEngine: CacheOperatorProtocol, @unchecked Sendable {

    private let memoryOperator: any CacheOperatorProtocol
    private let diskOperator: any CacheOperatorProtocol

    init(
        memoryOperator: any CacheOperatorProtocol = Container.shared.memoryCacheOperator(),
        diskOperator: any CacheOperatorProtocol = Container.shared.diskCacheOperator()
    ) {
        self.memoryOperator = memoryOperator
        self.diskOperator = diskOperator
    }

    func save(_ data: Data, for key: any CacheKeyProtocol) async {
        await memoryOperator.save(data, for: key)
        await diskOperator.save(data, for: key)
    }

    func retrieve(at key: any CacheKeyProtocol) async -> Data? {
        if let data = await memoryOperator.retrieve(at: key) {
            return data
        }

        if let data = await diskOperator.retrieve(at: key) {
            await memoryOperator.save(data, for: key)
            return data
        }

        return nil
    }
}
