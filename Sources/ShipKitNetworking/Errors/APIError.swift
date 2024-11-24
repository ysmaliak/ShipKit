import Foundation

/// Represents errors that can occur during API operations
public enum APIError: Error, LocalizedError {
    /// Indicates the response received was invalid or couldn't be parsed
    case invalidResponse

    /// Indicates an HTTP error occurred with associated response and data
    /// - response: The HTTP response containing status code and headers
    /// - data: Raw response data that might contain error details
    case httpError(response: HTTPURLResponse, data: Data)

    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            String(localizable: .apiErrorInvalidResponseDescription)
        case .httpError:
            String(localizable: .apiErrorHttpErrorDescription)
        }
    }

    public var failureReason: String? {
        switch self {
        case .invalidResponse:
            String(localizable: .apiErrorInvalidResponseReason)
        case .httpError:
            String(localizable: .apiErrorHttpErrorReason)
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .invalidResponse:
            String(localizable: .apiErrorInvalidResponseSuggestion)
        case .httpError:
            String(localizable: .apiErrorHttpErrorSuggestion)
        }
    }
}
