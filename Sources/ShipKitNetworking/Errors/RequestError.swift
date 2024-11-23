import Foundation

public enum RequestError: Error, LocalizedError {
    case invalidURL
    case invalidParameters
    case missingBaseURL

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            String(localizable: .requestErrorInvalidURLDescription)
        case .invalidParameters:
            String(localizable: .requestErrorInvalidParametersDescription)
        case .missingBaseURL:
            String(localizable: .requestErrorMissingBaseURLDescription)
        }
    }

    public var failureReason: String? {
        switch self {
        case .invalidURL:
            String(localizable: .requestErrorInvalidURLReason)
        case .invalidParameters:
            String(localizable: .requestErrorInvalidParametersReason)
        case .missingBaseURL:
            String(localizable: .requestErrorMissingBaseURLReason)
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .invalidURL:
            String(localizable: .requestErrorInvalidURLSuggestion)
        case .invalidParameters:
            String(localizable: .requestErrorInvalidParametersSuggestion)
        case .missingBaseURL:
            String(localizable: .requestErrorMissingBaseURLSuggestion)
        }
    }
}
