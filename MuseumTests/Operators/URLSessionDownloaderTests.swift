//
//  URLSessionDownloaderTests.swift
//  MuseumTests
//
//  Created by Vitor Cesco on 26/02/19.
//

import Foundation
import Testing
@testable import Museum

struct URLSessionDownloaderTests {

    // MARK: Successful Download

    @Test("Download returns file URL and HTTP response")
    func successfulDownload() async throws {
        let expectedData = Data("hello world".utf8)
        MockDownloadProtocol.requestHandler = { _ in
            let response = HTTPURLResponse(
                url: URL(string: "https://example.com/file.usdz")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Length": "\(expectedData.count)"]
            )!
            return (response, expectedData)
        }

        let sut = makeSUT()
        let (fileURL, response) = try await sut.download(from: URL(string: "https://example.com/file.usdz")!, onProgress: nil)
        defer { try? FileManager.default.removeItem(at: fileURL) }

        let httpResponse = try #require(response as? HTTPURLResponse)
        #expect(httpResponse.statusCode == 200)
        #expect(FileManager.default.fileExists(atPath: fileURL.path()))

        let downloadedData = try Data(contentsOf: fileURL)
        #expect(downloadedData == expectedData)
    }

    // MARK: Progress Events

    @Test("Download reports progress via onProgress closure")
    func progressEvents() async throws {
        let totalSize = 1024
        MockDownloadProtocol.requestHandler = { _ in
            let response = HTTPURLResponse(
                url: URL(string: "https://example.com/file.usdz")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Length": "\(totalSize)"]
            )!
            return (response, Data(count: totalSize))
        }

        let sut = makeSUT()
        var progressValues: [Float] = []

        let (fileURL, _) = try await sut.download(from: URL(string: "https://example.com/file.usdz")!) { fraction in
            progressValues.append(fraction)
        }
        defer { try? FileManager.default.removeItem(at: fileURL) }

        #expect(!progressValues.isEmpty)
        #expect(progressValues.allSatisfy { $0 > 0.0 && $0 <= 1.0 })

        if let last = progressValues.last {
            #expect(last == 1.0)
        }
    }

    // MARK: Network Error

    @Test("Download throws when the network request fails")
    func networkError() async {
        MockDownloadProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }

        let sut = makeSUT()

        await #expect(throws: URLError.self) {
            try await sut.download(from: URL(string: "https://example.com/file.usdz")!, onProgress: nil)
        }
    }

    // MARK: Cancellation

    @Test("Cancelling the task cancels the download")
    func cancellation() async throws {
        let downloadStarted = AsyncStream.makeStream(of: Void.self)

        MockDownloadProtocol.requestHandler = { _ in
            downloadStarted.continuation.yield()
            downloadStarted.continuation.finish()
            // Block long enough for cancellation to arrive
            try await Task.sleep(for: .seconds(60))
            return (HTTPURLResponse(), Data())
        }

        let sut = makeSUT()

        let task = Task {
            try await sut.download(from: URL(string: "https://example.com/file.usdz")!, onProgress: nil)
        }

        for await _ in downloadStarted.stream { break }

        task.cancel()

        let result = await task.result

        #expect(throws: (any Error).self) {
            try result.get()
        }
    }

    // MARK: Non-HTTP Response

    @Test("Download returns non-HTTP response without error")
    func nonHTTPResponse() async throws {
        MockDownloadProtocol.requestHandler = { request in
            let response = URLResponse(
                url: request.url!,
                mimeType: nil,
                expectedContentLength: 0,
                textEncodingName: nil
            )
            return (response, Data("data".utf8))
        }

        let sut = makeSUT()
        let (fileURL, response) = try await sut.download(from: URL(string: "https://example.com/file")!, onProgress: nil)
        defer { try? FileManager.default.removeItem(at: fileURL) }

        #expect(!(response is HTTPURLResponse))
        #expect(FileManager.default.fileExists(atPath: fileURL.path()))
    }
}

// MARK: - Helpers

private extension URLSessionDownloaderTests {

    func makeSUT() -> URLSessionDownloader {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockDownloadProtocol.self]
        return URLSessionDownloader(configuration: configuration)
    }
}

// MARK: - Mock URL Protocol

private final class MockDownloadProtocol: URLProtocol, @unchecked Sendable {

    nonisolated(unsafe) static var requestHandler: (@Sendable (URLRequest) async throws -> (URLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }

        let request = self.request
        Task { [weak self] in
            guard let self else { return }
            do {
                let (response, data) = try await handler(request)
                self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                self.client?.urlProtocol(self, didLoad: data)
                self.client?.urlProtocolDidFinishLoading(self)
            } catch {
                self.client?.urlProtocol(self, didFailWithError: error)
            }
        }
    }

    override func stopLoading() {}
}
