//
//  AssetDisplayState.swift
//  Museum
//
//  Created by Vitor Cesco on 26/02/19.
//

import Foundation

nonisolated enum AssetDisplayState: Sendable {
    case loading(progress: Float)
    case loaded(url: URL)
    case failed(Error)
}
