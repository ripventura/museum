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
    var fileExtension: String? { get }
}

extension CacheKeyProtocol {
    var fileExtension: String? { nil }
}

// MARK: - Cache Operator Protocol

nonisolated protocol CacheOperatorProtocol: Sendable {
    /// Moves the file at `sourceURL` into the cache associated with the given key.
    func save(_ sourceURL: URL, for key: any CacheKeyProtocol) async
    /// Returns the cached file URL for the given key, or nil if not found or expired.
    func retrieve(at key: any CacheKeyProtocol) async -> URL?
}
