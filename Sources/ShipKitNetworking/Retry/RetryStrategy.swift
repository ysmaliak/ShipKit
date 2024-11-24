import Foundation

/// Defines the strategy for handling retry attempts in network requests.
///
/// A retry strategy determines two key aspects of retry behavior:
/// 1. Whether a particular error should trigger a retry
/// 2. How long to wait before the next retry attempt
public protocol RetryStrategy: Sendable {
    /// Determines if a retry should be attempted based on the error and attempt number.
    /// - Parameters:
    ///   - error: The error that occurred during the request
    ///   - attempt: The current retry attempt number (1-based)
    /// - Returns: `true` if the request should be retried, `false` otherwise
    func shouldRetry(_ error: Error, attempt: Int) -> Bool

    /// Calculates the delay duration before the next retry attempt.
    /// - Parameter attempt: The current retry attempt number (1-based)
    /// - Returns: The time interval to wait before the next retry
    func delay(forAttempt attempt: Int) -> TimeInterval
}

/// Default implementation of RetryStrategy with exponential backoff.
///
/// This strategy:
/// - Retries on common transient errors (timeouts, connection losses)
/// - Retries on specific HTTP status codes (408, 500, 502, 503, 504)
/// - Uses exponential backoff with a configurable base delay and multiplier
public struct DefaultRetryStrategy: RetryStrategy {
    /// Base delay for the first retry attempt
    private let baseDelay: TimeInterval

    /// Multiplier applied to the delay for each subsequent retry
    private let multiplier: Double

    /// Set of HTTP status codes that should trigger a retry
    private let retryableStatusCodes: Set<Int>

    /// Creates a new DefaultRetryStrategy with customizable parameters.
    /// - Parameters:
    ///   - baseDelay: Initial delay for first retry (default: 0.3 seconds)
    ///   - multiplier: Factor to multiply delay by for each attempt (default: 1.0)
    ///   - retryableStatusCodes: HTTP status codes that should trigger retries
    ///                          (default: [408, 500, 502, 503, 504])
    public init(
        baseDelay: TimeInterval = 0.3,
        multiplier: Double = 1.0,
        retryableStatusCodes: Set<Int> = [408, 500, 502, 503, 504]
    ) {
        self.baseDelay = baseDelay
        self.multiplier = multiplier
        self.retryableStatusCodes = retryableStatusCodes
    }

    /// Determines whether a request should be retried based on the error type and response.
    ///
    /// This implementation handles two types of retry scenarios:
    /// 1. Network-related errors:
    ///    - Timeouts (.timedOut)
    ///    - Connection losses (.networkConnectionLost)
    ///
    /// 2. HTTP status codes that typically indicate transient failures:
    ///    - 408 (Request Timeout)
    ///    - 500 (Internal Server Error)
    ///    - 502 (Bad Gateway)
    ///    - 503 (Service Unavailable)
    ///    - 504 (Gateway Timeout)
    ///
    /// - Parameters:
    ///   - error: The error that occurred during the request. This method specifically
    ///            handles URLError types and examines their underlying HTTP responses.
    ///   - attempt: The current retry attempt number (1-based). Not used in the default
    ///              implementation but available for custom strategies that might need it.
    ///
    /// - Returns: `true` if the error is considered retryable, `false` otherwise.
    ///
    /// - Note: Only URLErrors are considered for retry. All other error types will
    ///         result in no retry attempt.
    public func shouldRetry(_ error: Error, attempt _: Int) -> Bool {
        guard let urlError = error as? URLError else {
            return false
        }

        switch urlError.code {
        case .timedOut, .networkConnectionLost:
            return true
        default:
            if let response = urlError.errorUserInfo[NSUnderlyingErrorKey] as? HTTPURLResponse {
                return retryableStatusCodes.contains(response.statusCode)
            }
            return false
        }
    }

    /// Calculates retry delay using exponential backoff.
    /// - Parameter attempt: Current retry attempt number (1-based)
    /// - Returns: Time interval to wait before next retry
    public func delay(forAttempt attempt: Int) -> TimeInterval {
        baseDelay * pow(multiplier, Double(attempt - 1))
    }
}

/// A strategy that never retries requests.
///
/// Use this when you want to explicitly disable retry behavior.
public struct NoRetryStrategy: RetryStrategy {
    public init() {}

    /// Always returns false, preventing any retries.
    public func shouldRetry(_: Error, attempt _: Int) -> Bool {
        false
    }

    /// Always returns 0, as no retries will be attempted.
    public func delay(forAttempt _: Int) -> TimeInterval {
        0
    }
}
