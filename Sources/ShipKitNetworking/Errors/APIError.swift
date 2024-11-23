import Foundation

public enum APIError: Error, LocalizedError {
    case invalidResponse
    case httpError(response: HTTPURLResponse, data: Data)
    
    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return String(localizable: .apiErrorInvalidResponseDescription)
        case .httpError:
            return String(localizable: .apiErrorHttpErrorDescription)
        }
    }
    
    public var failureReason: String? {
        switch self {
        case .invalidResponse:
            return String(localizable: .apiErrorInvalidResponseReason)
        case .httpError:
            return String(localizable: .apiErrorHttpErrorReason)
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .invalidResponse:
            return String(localizable: .apiErrorInvalidResponseSuggestion)
        case .httpError:
            return String(localizable: .apiErrorHttpErrorSuggestion)
        }
    }
}
