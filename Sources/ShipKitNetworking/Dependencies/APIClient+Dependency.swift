import ComposableArchitecture
import Foundation

/// A dependency key for accessing the APIClient in TCA reducers.
private enum APIClientKey: DependencyKey {
    /// The default value provides a live APIClient instance.
    static let liveValue: APIClient = APIClient()
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
