//
//  CacheOperatorProtocol.swift
//  Museum
//
//  Created by Vitor Cesco on 18/02/26.
//

import Foundation

// MARK: - Cache Key Protocol

nonisolated protocol CacheKeyProtocol: Sendable {
    var value: String { get }
}

// MARK: - Cache Operator Protocol

nonisolated protocol CacheOperatorProtocol: Sendable {
    /// Saves data to the cache associated with the given key.
    func save(_ data: Data, for key: any CacheKeyProtocol) async
    /// Retrieves cached data for the given key, or nil if not found or expired.
    func retrieve(at key: any CacheKeyProtocol) async -> Data?
}
