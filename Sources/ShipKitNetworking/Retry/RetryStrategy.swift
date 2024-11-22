import Foundation

public protocol RetryStrategy {
    func shouldRetry(_ error: Error, attempt: Int) -> Bool
    func delay(forAttempt attempt: Int) -> TimeInterval
}

public struct DefaultRetryStrategy: RetryStrategy {
    private let baseDelay: TimeInterval
    private let multiplier: Double
    private let retryableStatusCodes: Set<Int>

    public init(
        baseDelay: TimeInterval = 0.3,
        multiplier: Double = 1.0,
        retryableStatusCodes: Set<Int> = [408, 500, 502, 503, 504]
    ) {
        self.baseDelay = baseDelay
        self.multiplier = multiplier
        self.retryableStatusCodes = retryableStatusCodes
    }

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

    public func delay(forAttempt attempt: Int) -> TimeInterval {
        baseDelay * pow(multiplier, Double(attempt - 1))
    }
}

public struct NoRetryStrategy: RetryStrategy {
    public init() {}

    public func shouldRetry(_: Error, attempt _: Int) -> Bool {
        false
    }

    public func delay(forAttempt _: Int) -> TimeInterval {
        0
    }
}
