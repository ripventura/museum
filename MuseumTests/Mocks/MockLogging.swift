//
//  MockLogging.swift
//  MuseumTests
//
//  Created by Vitor Cesco on 18/02/26.
//

@testable import Museum

final class MockLogging: Logging, @unchecked Sendable {

    struct Entry: Equatable {
        let level: String
        let message: String
    }

    private(set) var entries: [Entry] = []

    func debug(_ message: String) { entries.append(Entry(level: "debug", message: message)) }
    func info(_ message: String) { entries.append(Entry(level: "info", message: message)) }
    func warning(_ message: String) { entries.append(Entry(level: "warning", message: message)) }
    func error(_ message: String) { entries.append(Entry(level: "error", message: message)) }
    func fault(_ message: String) { entries.append(Entry(level: "fault", message: message)) }
}
