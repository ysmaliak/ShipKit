import ComposableArchitecture
import Foundation

/// A dependency key for accessing the APIClient in TCA reducers.
private enum APIClientKey: DependencyKey {
    /// The default value provides a live APIClient instance.
    static let liveValue: APIClient = APIClient()
    
    /// A test value that can be overridden for testing.
    static let testValue: APIClient = APIClient()
}

extension DependencyValues {
    /// Access the APIClient through the dependency system.
    ///
    /// Example usage in a reducer:
    /// ```swift
    /// @Dependency(\.apiClient) var apiClient
    /// ```
    public var apiClient: APIClient {
        get { self[APIClientKey.self] }
        set { self[APIClientKey.self] = newValue }
    }
}

#if DEBUG
/// A test implementation of APIClient for use in previews and tests.
public final class TestAPIClient: APIClientProtocol, @unchecked Sendable {
    /// Closure for customizing send behavior in tests
    public var sendHandler: (@Sendable (Request<some Decodable>, Bool, RetryPolicy) async throws -> Any)?
    
    /// Closure for customizing upload behavior in tests
    public var uploadHandler: (@Sendable (Request<some Decodable>, Data, RetryPolicy) async throws -> Any)?
    
    /// Closure for customizing data request behavior in tests
    public var dataRequestHandler: (@Sendable (Request<Data>, RetryPolicy) async throws -> Data)?
    
    /// Closure for customizing URL data behavior in tests
    public var dataURLHandler: (@Sendable (URL, RetryPolicy) async throws -> Data)?

    public init(
        sendHandler: (@Sendable (Request<some Decodable>, Bool, RetryPolicy) async throws -> Any)? = nil,
        uploadHandler: (@Sendable (Request<some Decodable>, Data, RetryPolicy) async throws -> Any)? = nil,
        dataRequestHandler: (@Sendable (Request<Data>, RetryPolicy) async throws -> Data)? = nil,
        dataURLHandler: (@Sendable (URL, RetryPolicy) async throws -> Data)? = nil
    ) {
        self.sendHandler = sendHandler
        self.uploadHandler = uploadHandler
        self.dataRequestHandler = dataRequestHandler
        self.dataURLHandler = dataURLHandler
    }

    public func send<T: Decodable & Sendable>(
        _ request: Request<T>,
        cached: Bool = false,
        retryPolicy: RetryPolicy = .default
    ) async throws -> T {
        guard let handler = sendHandler else {
            throw APIError.invalidResponse
        }
        let result = try await handler(request, cached, retryPolicy)
        guard let typed = result as? T else {
            throw APIError.invalidResponse
        }
        return typed
    }

    public func upload<T: Decodable & Sendable>(
        for request: Request<T>,
        from data: Data,
        retryPolicy: RetryPolicy = .default
    ) async throws -> T {
        guard let handler = uploadHandler else {
            throw APIError.invalidResponse
        }
        let result = try await handler(request, data, retryPolicy)
        guard let typed = result as? T else {
            throw APIError.invalidResponse
        }
        return typed
    }

    public func data(
        for request: Request<Data>,
        retryPolicy: RetryPolicy = .default
    ) async throws -> Data {
        guard let handler = dataRequestHandler else {
            throw APIError.invalidResponse
        }
        return try await handler(request, retryPolicy)
    }

    public func data(
        for url: URL,
        retryPolicy: RetryPolicy = .default
    ) async throws -> Data {
        guard let handler = dataURLHandler else {
            throw APIError.invalidResponse
        }
        return try await handler(url, retryPolicy)
    }
}
#endif 