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
    func handleAuthenticationFailure(_ response: HTTPURLResponse) async throws -> Bool
}

public struct NoAuthProvider: AuthenticationProvider {
    public init() {}

    public func authenticate(_: inout URLRequest) async throws {}

    public func handleAuthenticationFailure(_: HTTPURLResponse) async throws -> Bool {
        false
    }
}
