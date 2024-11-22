import Foundation

public struct RetryPolicy {
    public var strategy: RetryStrategy
    public var maxRetries: Int
    public var currentAttempt: Int

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
    public static var none: Self {
        RetryPolicy(strategy: NoRetryStrategy(), maxRetries: 0)
    }

    public static var `default`: Self {
        RetryPolicy(strategy: DefaultRetryStrategy(), maxRetries: 3)
    }
}
