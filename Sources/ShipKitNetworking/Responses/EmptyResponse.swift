import Foundation

/// Represents an empty response from an API endpoint.
/// Used when an API call succeeds but returns no data,
/// typically for DELETE operations or status-only endpoints.
public struct EmptyResponse: Decodable {
    public init() {}
}
