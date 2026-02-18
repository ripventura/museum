//
//  LogOperator.swift
//  Museum
//
//  Created by Vitor Cesco on 18/02/26.
//

import FactoryKit
import os

// MARK: - DI Registration

extension Container {
    var logOperator: ParameterFactory<String, any Logging> {
        self { LogOperator(subsystem: Constants.bundleIdentifier, category: $0) }
    }
}

// MARK: - Logging Protocol

nonisolated protocol Logging: Sendable {
    /// Logs a debug-level message. Use for verbose development-time information.
    func debug(_ message: String)
    /// Logs an info-level message. Use for helpful but non-essential runtime information.
    func info(_ message: String)
    /// Logs a warning-level message. Use for unexpected but recoverable situations.
    func warning(_ message: String)
    /// Logs an error-level message. Use for errors that affect functionality.
    func error(_ message: String)
    /// Logs a fault-level message. Use for critical system-level failures.
    func fault(_ message: String)
}

// MARK: - Implementation

nonisolated final class LogOperator: Logging, Sendable {

    private let logger: Logger

    init(subsystem: String, category: String) {
        self.logger = Logger(subsystem: subsystem, category: category)
    }

    func debug(_ message: String) { logger.debug("\(message)") }
    func info(_ message: String) { logger.info("\(message)") }
    func warning(_ message: String) { logger.warning("\(message)") }
    func error(_ message: String) { logger.error("\(message)") }
    func fault(_ message: String) { logger.fault("\(message)") }
}
