import Foundation

/// Represents errors that can occur during request creation and configuration.
///
/// These errors are typically encountered before the request is sent and relate to:
/// - URL formation
/// - Parameter validation
/// - Configuration issues
///
/// Example handling:
/// ```swift
/// do {
///     let request = try Request<Response>(
///         method: .get,
///         path: "/users"
///     )
/// } catch let error as RequestError {
///     switch error {
///     case .invalidURL:
///         // Handle malformed URL
///     case .invalidParameters:
///         // Handle invalid parameters
///     case .missingBaseURL:
///         // Handle missing base URL configuration
///     }
/// }
/// ```
public enum RequestError: Error, LocalizedError {
    /// Indicates that the URL could not be constructed or is malformed.
    ///
    /// This can occur when:
    /// - The path contains invalid characters
    /// - The URL components cannot be combined
    /// - The resulting URL is malformed
    case invalidURL
    
    /// Indicates that the request parameters are invalid.
    ///
    /// This can occur when:
    /// - Query parameters are malformed
    /// - Required parameters are missing
    /// - Parameter values are invalid
    case invalidParameters
    
    /// Indicates that no base URL was configured.
    ///
    /// This occurs when:
    /// - The APIConfiguration.baseURL is nil
    /// - A relative path is used without a base URL
    /// - The client is not properly configured
    case missingBaseURL

    /// A user-friendly description of the error.
    ///
    /// This property provides localized descriptions suitable for
    /// displaying to users or logging.
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

    /// The technical reason for the error.
    ///
    /// This property provides more detailed, technical explanations
    /// suitable for debugging or logging.
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

    /// Suggestions for resolving the error.
    ///
    /// This property provides actionable steps that can be taken
    /// to resolve the error condition.
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
