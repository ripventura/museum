//
//  LogOperatorTests.swift
//  MuseumTests
//
//  Created by Vitor Cesco on 18/02/26.
//

import Testing
@testable import Museum

struct LogOperatorTests {

    // MARK: Smoke Tests

    @Test("LogOperator can be created with arbitrary subsystem and category")
    func initialization() {
        let sut = LogOperator(subsystem: "com.test", category: "TestCategory")
        // Verify it conforms to Logging (compilation is the assertion)
        let _: any Logging = sut
    }

    @Test("debug logs without crashing")
    func debugLevel() {
        let sut = LogOperator(subsystem: "com.test", category: "Test")
        sut.debug("debug message")
    }

    @Test("info logs without crashing")
    func infoLevel() {
        let sut = LogOperator(subsystem: "com.test", category: "Test")
        sut.info("info message")
    }

    @Test("warning logs without crashing")
    func warningLevel() {
        let sut = LogOperator(subsystem: "com.test", category: "Test")
        sut.warning("warning message")
    }

    @Test("error logs without crashing")
    func errorLevel() {
        let sut = LogOperator(subsystem: "com.test", category: "Test")
        sut.error("error message")
    }

    @Test("fault logs without crashing")
    func faultLevel() {
        let sut = LogOperator(subsystem: "com.test", category: "Test")
        sut.fault("fault message")
    }

    // MARK: Mock Tests

    @Test("MockLogging captures log entries with correct level and message")
    func mockCapture() {
        let mock = MockLogging()

        mock.debug("d")
        mock.info("i")
        mock.warning("w")
        mock.error("e")
        mock.fault("f")

        #expect(mock.entries.count == 5)
        #expect(mock.entries[0] == MockLogging.Entry(level: "debug", message: "d"))
        #expect(mock.entries[1] == MockLogging.Entry(level: "info", message: "i"))
        #expect(mock.entries[2] == MockLogging.Entry(level: "warning", message: "w"))
        #expect(mock.entries[3] == MockLogging.Entry(level: "error", message: "e"))
        #expect(mock.entries[4] == MockLogging.Entry(level: "fault", message: "f"))
    }
}
