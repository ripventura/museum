//
//  RetryStrategy.swift
//  Museum
//
//  Created by Vitor Cesco on 18/02/26.
//

nonisolated struct RetryStrategy: Sendable, Equatable {
    /// Number of additional attempts after the first failure.
    let maxAttempts: Int
    /// Initial delay before the first retry.
    let initialDelay: Duration
    /// Maximum cap for the exponential delay.
    let maxDelay: Duration
}

// MARK: - Internal

nonisolated extension RetryStrategy {

    func delay(forAttempt attempt: Int) -> Duration {
        let factor = Double(1 << min(attempt, 62))
        let computed = initialDelay * factor
        return min(computed, maxDelay)
    }
}
