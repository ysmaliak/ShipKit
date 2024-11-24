import Foundation

/// A policy that defines how authentication should be handled for network requests
public struct AuthenticationPolicy: Sendable {
    /// The provider responsible for handling authentication operations
    public var provider: AuthenticationProvider

    /// Creates a new authentication policy with the specified provider
    /// - Parameter provider: The authentication provider to use
    public init(provider: AuthenticationProvider) {
        self.provider = provider
    }

    /// A policy that performs no authentication
    /// - Returns: An authentication policy with a `NoAuthProvider`
    public static var none: Self {
        AuthenticationPolicy(provider: NoAuthProvider())
    }
}

/// A protocol defining the requirements for an authentication provider
public protocol AuthenticationProvider: Sendable {
    /// Authenticates a URL request by modifying it as needed (e.g., adding auth headers)
    /// - Parameter request: The request to authenticate
    /// - Throws: Any error that occurs during authentication
    func authenticate(_ request: inout URLRequest) async throws

    /// Attempts to recover from an authentication error, typically by refreshing the auth token
    /// - Parameters:
    ///   - response: The HTTP response that triggered the authentication failure
    ///   - data: The response data that might contain error details
    /// - Returns: True if recovery was successful and the request should be retried
    /// - Throws: Any error that occurs during recovery
    func attemptAuthenticationRecovery(for response: HTTPURLResponse, responseData: Data?) async throws -> Bool
}

/// A no-op authentication provider that performs no authentication
public struct NoAuthProvider: AuthenticationProvider {
    public init() {}

    /// Does nothing to the request
    /// - Parameter request: The request that won't be modified
    public func authenticate(_: inout URLRequest) async throws {}

    /// Always returns false as no recovery is possible
    /// - Parameters:
    ///   - response: Ignored
    ///   - responseData: Ignored
    /// - Returns: Always returns false
    public func attemptAuthenticationRecovery(for _: HTTPURLResponse, responseData _: Data?) async throws -> Bool {
        false
    }
}
