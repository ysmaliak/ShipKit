import Foundation

/// Configuration settings for the API client.
///
/// This struct encapsulates all configuration options needed to customize the behavior
/// of network requests, including URL configuration, session settings, and data encoding/decoding.
///
/// Example usage:
/// ```swift
/// var config = APIConfiguration()
/// config.baseURL = URL(string: "https://api.example.com")
/// config.decoder = .iso8601
///
/// APIClient.configuration = config
/// ```
public struct APIConfiguration {
    /// The base URL for all network requests.
    ///
    /// This URL will be used as the prefix for all relative paths in requests.
    /// If not set, requests must use absolute URLs.
    ///
    /// Example: "https://api.example.com"
    public var baseURL: URL?

    /// Configuration for the URLSession used to make network requests.
    ///
    /// This allows customization of session-wide settings such as:
    /// - Timeout values
    /// - Maximum connection count
    /// - TLS settings
    /// - Cookie policies
    /// - Proxy settings
    public var urlSessionConfiguration: URLSessionConfiguration = .default

    /// The JSON decoder used to parse response data.
    ///
    /// Defaults to a decoder configured for ISO8601 date formatting.
    /// Can be customized to handle different date formats or decoding strategies.
    public var decoder: JSONDecoder = .iso8601

    /// The JSON encoder used to serialize request data.
    ///
    /// Defaults to an encoder configured for ISO8601 date formatting.
    /// Can be customized to handle different date formats or encoding strategies.
    public var encoder: JSONEncoder = .iso8601

    /// The URL cache used for storing and retrieving cached responses.
    ///
    /// Controls how responses are cached and when cached responses are used.
    /// Defaults to the shared system cache.
    public var cache: URLCache = .shared

    /// Creates a new API configuration with the specified settings.
    ///
    /// - Parameters:
    ///   - baseURL: The base URL for all network requests.
    ///   - urlSessionConfiguration: The URL session configuration.
    ///   - decoder: The JSON decoder.
    ///   - encoder: The JSON encoder.
    ///   - cache: The URL cache.
    public init(
        baseURL: URL? = nil,
        urlSessionConfiguration: URLSessionConfiguration = .default,
        decoder: JSONDecoder = .iso8601,
        encoder: JSONEncoder = .iso8601,
        cache: URLCache = .shared
    ) {
        self.baseURL = baseURL
        self.urlSessionConfiguration = urlSessionConfiguration
        self.decoder = decoder
        self.encoder = encoder
        self.cache = cache
    }
}
