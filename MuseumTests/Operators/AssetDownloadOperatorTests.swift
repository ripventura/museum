//
//  AssetDownloadOperatorTests.swift
//  MuseumTests
//
//  Created by Vitor Cesco on 18/02/26.
//

import Foundation
import Testing
@testable import Museum

struct AssetDownloadOperatorTests {

    private let mockSession = MockURLSessionDownloading()

    // MARK: Successful Download

    @Test("Download completes successfully with file at temporary location")
    func successfulDownload() async throws {
        let sourceFile = FileManager.default.temporaryDirectory
            .appendingPathComponent("source-\(UUID().uuidString).usdz")
        FileManager.default.createFile(atPath: sourceFile.path(), contents: Data("test".utf8))
        defer { try? FileManager.default.removeItem(at: sourceFile) }

        let response = HTTPURLResponse(
            url: URL(string: "https://example.com/asset.usdz")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        mockSession.result = .success((sourceFile, response))

        let sut = AssetDownloadOperator(session: mockSession)
        let stream = sut.download(from: URL(string: "https://example.com/asset.usdz")!)

        var completedURL: URL?
        for try await event in stream {
            if case .completed(let url) = event {
                completedURL = url
            }
        }

        #expect(mockSession.downloadCallCount == 1)
        #expect(mockSession.lastRequestedURL?.absoluteString == "https://example.com/asset.usdz")
        let fileURL = try #require(completedURL)
        #expect(FileManager.default.fileExists(atPath: fileURL.path()))
        #expect(fileURL.pathExtension == "usdz")

        try? FileManager.default.removeItem(at: fileURL)
    }

    // MARK: File Extension Preserved

    @Test("Downloaded file preserves the original URL's file extension")
    func fileExtensionPreserved() async throws {
        let sourceFile = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        FileManager.default.createFile(atPath: sourceFile.path(), contents: Data("data".utf8))
        defer { try? FileManager.default.removeItem(at: sourceFile) }

        let response = HTTPURLResponse(
            url: URL(string: "https://example.com/model.reality")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        mockSession.result = .success((sourceFile, response))

        let sut = AssetDownloadOperator(session: mockSession)
        let stream = sut.download(from: URL(string: "https://example.com/model.reality")!)

        var completedURL: URL?
        for try await event in stream {
            if case .completed(let url) = event {
                completedURL = url
            }
        }

        let fileURL = try #require(completedURL)
        #expect(fileURL.pathExtension == "reality")

        try? FileManager.default.removeItem(at: fileURL)
    }

    // MARK: HTTP Error

    @Test("Download throws httpError for non-success status codes")
    func httpErrorStatusCode() async throws {
        let tempFile = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        FileManager.default.createFile(atPath: tempFile.path(), contents: Data())
        defer { try? FileManager.default.removeItem(at: tempFile) }

        let response = HTTPURLResponse(
            url: URL(string: "https://example.com/asset.usdz")!,
            statusCode: 404,
            httpVersion: nil,
            headerFields: nil
        )!
        mockSession.result = .success((tempFile, response))

        let sut = AssetDownloadOperator(session: mockSession)
        let stream = sut.download(from: URL(string: "https://example.com/asset.usdz")!)

        await #expect(throws: AssetDownloadError.self) {
            for try await _ in stream { }
        }
    }

    // MARK: Invalid Response

    @Test("Download throws invalidResponse for non-HTTP responses")
    func invalidResponse() async throws {
        let tempFile = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        FileManager.default.createFile(atPath: tempFile.path(), contents: Data())
        defer { try? FileManager.default.removeItem(at: tempFile) }

        let response = URLResponse(
            url: URL(string: "https://example.com/asset")!,
            mimeType: nil,
            expectedContentLength: 0,
            textEncodingName: nil
        )
        mockSession.result = .success((tempFile, response))

        let sut = AssetDownloadOperator(session: mockSession)
        let stream = sut.download(from: URL(string: "https://example.com/asset")!)

        await #expect(throws: AssetDownloadError.invalidResponse) {
            for try await _ in stream { }
        }
    }

    // MARK: Network Error Propagation

    @Test("Download propagates URLSession network errors")
    func networkError() async throws {
        mockSession.result = .failure(URLError(.notConnectedToInternet))

        let sut = AssetDownloadOperator(session: mockSession)
        let stream = sut.download(from: URL(string: "https://example.com/asset.usdz")!)

        await #expect(throws: URLError.self) {
            for try await _ in stream { }
        }
    }

    // MARK: File Move Failure

    @Test("Download throws fileOperationFailed when file move fails")
    func fileMoveFailed() async throws {
        let nonExistentFile = URL(fileURLWithPath: "/nonexistent/path/file.usdz")

        let response = HTTPURLResponse(
            url: URL(string: "https://example.com/asset.usdz")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        mockSession.result = .success((nonExistentFile, response))

        let sut = AssetDownloadOperator(session: mockSession)
        let stream = sut.download(from: URL(string: "https://example.com/asset.usdz")!)

        await #expect(throws: AssetDownloadError.self) {
            for try await _ in stream { }
        }
    }

    // MARK: Cancellation

    @Test("Cancelling the consuming task cancels the underlying download")
    func cancellation() async throws {
        let downloadStarted = AsyncStream.makeStream(of: Void.self)
        let downloadCancelled = AsyncStream.makeStream(of: Void.self)

        mockSession.onDownloadCalled = { _, _ in
            downloadStarted.continuation.yield()
            do {
                try await Task.sleep(for: .seconds(60))
            } catch is CancellationError {
                downloadCancelled.continuation.yield()
                downloadCancelled.continuation.finish()
                throw CancellationError()
            }
        }
        mockSession.result = .failure(CancellationError())

        let sut = AssetDownloadOperator(session: mockSession)
        let stream = sut.download(from: URL(string: "https://example.com/asset.usdz")!)

        let task = Task {
            for try await _ in stream { }
        }

        // Wait until the download has actually started
        for await _ in downloadStarted.stream { break }

        task.cancel()

        // Verify the underlying download was cancelled
        for await _ in downloadCancelled.stream { break }

        _ = await task.result
    }
}
