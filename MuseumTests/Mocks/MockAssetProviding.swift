//
//  MockAssetProviding.swift
//  MuseumTests
//
//  Created by Vitor Cesco on 26/02/19.
//

import Foundation
@testable import Museum

final class MockAssetProviding: AssetProviding, @unchecked Sendable {

    var result: Result<URL, Error> = .success(URL(filePath: "/tmp/mock-asset"))
    var onProvideCalled: (@Sendable () async throws -> Void)?
    var progressValues: [Float] = [0.5, 1.0]
    private(set) var provideCallCount = 0
    private(set) var lastAsset: Asset?
    private(set) var lastStrategy: RetryStrategy?

    func provide(
        _ asset: Asset,
        strategy: RetryStrategy,
        onProgress: (@Sendable (Float) -> Void)?
    ) async throws -> URL {
        provideCallCount += 1
        lastAsset = asset
        lastStrategy = strategy

        try await onProvideCalled?()

        for value in progressValues {
            onProgress?(value)
        }

        return try result.get()
    }
}
