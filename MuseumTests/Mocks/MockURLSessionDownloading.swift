//
//  MockURLSessionDownloading.swift
//  MuseumTests
//
//  Created by Vitor Cesco on 18/02/26.
//

import Foundation
@testable import Museum

final class MockURLSessionDownloading: URLSessionDownloading, @unchecked Sendable {

    var result: Result<(URL, URLResponse), Error>!
    var onDownloadCalled: (@Sendable (URL, (any URLSessionTaskDelegate)?) async throws -> Void)?
    private(set) var downloadCallCount = 0
    private(set) var lastRequestedURL: URL?

    func download(
        from url: URL,
        delegate: (any URLSessionTaskDelegate)?
    ) async throws -> (URL, URLResponse) {
        downloadCallCount += 1
        lastRequestedURL = url
        try await onDownloadCalled?(url, delegate)
        return try result.get()
    }
}
