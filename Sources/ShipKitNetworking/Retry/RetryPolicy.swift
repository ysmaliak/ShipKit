import Foundation

/// Defines the retry behavior for network requests that fail.
///
/// RetryPolicy allows you to configure how many times a request should be retried
/// and what strategy should be used to determine the delay between retries.
///
/// Example usage:
/// ```swift
/// // Create a default retry policy with 3 maximum retries
/// let policy = RetryPolicy()
///
/// // Create a custom retry policy
/// let customPolicy = RetryPolicy(strategy: ExponentialBackoffStrategy(), maxRetries: 5)
/// ```
public struct RetryPolicy: Sendable {
    /// The strategy that determines the delay between retry attempts
    public var strategy: RetryStrategy

    /// Maximum number of retry attempts allowed
    public var maxRetries: Int

    /// Current number of retry attempts made
    public var currentAttempt: Int

    /// Creates a new retry policy with the specified strategy and maximum retries.
    ///
    /// - Parameters:
    ///   - strategy: The retry strategy to use. Defaults to `DefaultRetryStrategy`
    ///   - maxRetries: Maximum number of retry attempts. Defaults to 3
    public init(
        strategy: RetryStrategy = DefaultRetryStrategy(),
        maxRetries: Int = 3
    ) {
        self.strategy = strategy
        self.maxRetries = maxRetries
        currentAttempt = 0
    }
}

extension RetryPolicy {
    /// A policy that performs no retries.
    ///
    /// Use this when you want to disable retry behavior entirely.
    public static var none: Self {
        RetryPolicy(strategy: NoRetryStrategy(), maxRetries: 0)
    }

    /// The default retry policy.
    ///
    /// Uses `DefaultRetryStrategy` with 3 maximum retries.
    public static var `default`: Self {
        RetryPolicy(strategy: DefaultRetryStrategy(), maxRetries: 3)
    }
}
