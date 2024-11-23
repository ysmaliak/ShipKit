import Foundation

public enum APIError: Error, LocalizedError {
    case invalidResponse
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
