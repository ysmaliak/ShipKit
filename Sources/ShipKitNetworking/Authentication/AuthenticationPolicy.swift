import Foundation

public struct AuthenticationPolicy: Sendable {
    public var provider: AuthenticationProvider

    public init(provider: AuthenticationProvider) {
        self.provider = provider
    }

    public static var none: Self {
        AuthenticationPolicy(provider: NoAuthProvider())
    }
}

public protocol AuthenticationProvider: Sendable {
    func authenticate(_ request: inout URLRequest) async throws

    /// Attempts to recover from an authentication error, typically by refreshing the auth token
    /// - Parameters:
    ///   - response: The HTTP response that triggered the authentication failure
    ///   - data: The response data that might contain error details
    /// - Returns: True if recovery was successful and the request should be retried
    func attemptAuthenticationRecovery(for response: HTTPURLResponse, responseData: Data?) async throws -> Bool
}

public struct NoAuthProvider: AuthenticationProvider {
    public init() {}

    public func authenticate(_: inout URLRequest) async throws {}

    public func attemptAuthenticationRecovery(for _: HTTPURLResponse, responseData _: Data?) async throws -> Bool {
        false
    }
}
