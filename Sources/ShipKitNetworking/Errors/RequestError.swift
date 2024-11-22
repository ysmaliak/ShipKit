import Foundation

public enum RequestError: Error, LocalizedError {
    case invalidURL
    case invalidParameters
    case missingBaseURL

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            NSLocalizedString("Error.SomethingWentWrong", bundle: Bundle.module, comment: "")
        case .invalidParameters:
            NSLocalizedString("Error.SomethingWentWrong", bundle: Bundle.module, comment: "")
        case .missingBaseURL:
            NSLocalizedString("Error.SomethingWentWrong", bundle: Bundle.module, comment: "")
        }
    }
}
