//
//  Constants.swift
//  Museum
//
//  Created by Vitor Cesco on 18/02/26.
//

import Foundation

nonisolated enum Constants {
    static let bundleIdentifier = Bundle.main.bundleIdentifier!
    static let memoryCacheLimit: Int = 1_000_000_000
    static let diskCacheTimeToLive: TimeInterval = 7 * 24 * 60 * 60
    static let cacheURL = FileManager.default.urls(
        for: .cachesDirectory,
        in: .userDomainMask
    ).first!
}
