import Foundation

public enum TokenError: Error, LocalizedError {
    case invalidAccessToken
    case invalidRefreshToken
    case unknown

    public var errorDescription: String? {
        switch self {
        case .invalidAccessToken:
            NSLocalizedString("Error.SomethingWentWrong", bundle: Bundle.module, comment: "")

        case .invalidRefreshToken:
            NSLocalizedString("Error.SomethingWentWrong", bundle: Bundle.module, comment: "")

        case .unknown:
            NSLocalizedString("Error.SomethingWentWrong", bundle: Bundle.module, comment: "")
        }
    }
}
