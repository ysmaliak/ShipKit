import Foundation

public enum RequestError: Error, LocalizedError {
    case invalidURL
    case invalidParameters
    case missingBaseURL
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return String(localizable: .requestErrorInvalidURLDescription)
        case .invalidParameters:
            return String(localizable: .requestErrorInvalidParametersDescription)
        case .missingBaseURL:
            return String(localizable: .requestErrorMissingBaseURLDescription)
        }
    }
    
    public var failureReason: String? {
        switch self {
        case .invalidURL:
            return String(localizable: .requestErrorInvalidURLReason)
        case .invalidParameters:
            return String(localizable: .requestErrorInvalidParametersReason)
        case .missingBaseURL:
            return String(localizable: .requestErrorMissingBaseURLReason)
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .invalidURL:
            return String(localizable: .requestErrorInvalidURLSuggestion)
        case .invalidParameters:
            return String(localizable: .requestErrorInvalidParametersSuggestion)
        case .missingBaseURL:
            return String(localizable: .requestErrorMissingBaseURLSuggestion)
        }
    }
}
