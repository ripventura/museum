//
//  Asset.swift
//  Museum
//
//  Created by Vitor Cesco on 18/02/26.
//

nonisolated enum Asset: String, CaseIterable, Sendable, CacheKeyProtocol {
    case warship = "KM1PUvbAai5kXm8"

    var value: String { rawValue }
}
