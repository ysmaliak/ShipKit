import Foundation

/// A type representing an HTTP network request with a strongly-typed response
public struct Request<Response: Decodable>: Sendable {
    /// The HTTP method for the request (GET, POST, etc.)
    public let method: HTTPMethod

    /// The base URL for the request, can be nil if using absoluteURL
    public let baseURL: URL?

    /// The path component to be appended to the base URL
    public let path: String

    /// An absolute URL for the request, can be nil if using baseURL + path
    public let absoluteURL: URL?

    /// The content type of the request (JSON or multipart)
    public let contentType: ContentType

    /// Optional query parameters to be added to the URL
    public let query: [String: String]?

    /// Optional HTTP headers to be included in the request
    public let headers: [String: String]?

    /// Optional body data to be sent with the request
    public let body: Body?

    /// Optional timeout interval for the request
    public let timeoutInterval: TimeInterval?

    /// Cache policy for the request
    public let cachePolicy: URLRequest.CachePolicy

    /// Authentication policy for the request
    public let authenticationPolicy: AuthenticationPolicy

    /// Creates a new request with a base URL and path
    /// - Parameters:
    ///   - method: The HTTP method
    ///   - baseURL: Base URL for the request (defaults to APIClient configuration)
    ///   - path: Path component to append to base URL
    ///   - contentType: Type of content being sent
    ///   - query: Optional query parameters
    ///   - headers: Optional HTTP headers
    ///   - body: Optional request body
    ///   - timeoutInterval: Optional timeout duration
    ///   - cachePolicy: Cache policy for the request
    ///   - authenticationPolicy: Authentication policy for the request
    public init(
        method: HTTPMethod,
        baseURL: URL? = APIClient.configuration.baseURL,
        path: String,
        contentType: ContentType,
        query: [String: String]? = nil,
        headers: [String: String]? = nil,
        body: Body? = nil,
        timeoutInterval: TimeInterval? = 30,
        cachePolicy: URLRequest.CachePolicy = .reloadIgnoringLocalAndRemoteCacheData,
        authenticationPolicy: AuthenticationPolicy = .none
    ) {
        self.method = method
        self.baseURL = baseURL
        self.path = path
        absoluteURL = nil
        self.contentType = contentType
        self.query = query
        self.headers = headers
        self.body = body
        self.timeoutInterval = timeoutInterval
        self.cachePolicy = cachePolicy
        self.authenticationPolicy = authenticationPolicy
    }

    /// Creates a new request with an absolute URL
    /// - Parameters:
    ///   - method: The HTTP method
    ///   - absoluteURL: Complete URL for the request
    ///   - contentType: Type of content being sent
    ///   - query: Optional query parameters
    ///   - headers: Optional HTTP headers
    ///   - body: Optional request body
    ///   - timeoutInterval: Optional timeout duration
    ///   - cachePolicy: Cache policy for the request
    ///   - authenticationPolicy: Authentication policy for the request
    public init(
        method: HTTPMethod,
        absoluteURL: URL,
        contentType: ContentType,
        query: [String: String]? = nil,
        headers: [String: String]? = nil,
        body: Body? = nil,
        timeoutInterval: TimeInterval? = 30,
        cachePolicy: URLRequest.CachePolicy = .reloadIgnoringLocalAndRemoteCacheData,
        authenticationPolicy: AuthenticationPolicy = .none
    ) {
        self.method = method
        baseURL = nil
        path = ""
        self.absoluteURL = absoluteURL
        self.contentType = contentType
        self.query = query
        self.headers = headers
        self.body = body
        self.timeoutInterval = timeoutInterval
        self.cachePolicy = cachePolicy
        self.authenticationPolicy = authenticationPolicy
    }

    /// Converts the request into a URLRequest
    /// - Returns: A configured URLRequest ready to be sent
    /// - Throws: RequestError if URL construction fails or authentication fails
    public func asURLRequest() async throws -> URLRequest {
        let url: URL = if let absoluteURL {
            absoluteURL
        } else {
            try buildURL()
        }

        switch contentType {
        case .json:
            return try await asURLRequest(url: url)
        case .multipartData(let fields):
            let multipartData = MultipartData()

            for field in fields {
                multipartData.addDataField(field)
            }

            return try await multipartData.asURLRequest(
                url: url,
                method: method,
                headers: headers,
                cachePolicy: cachePolicy,
                timeoutInterval: timeoutInterval
            )
        }
    }

    /// Creates a URLRequest for JSON content type
    /// - Parameter url: The URL for the request
    /// - Returns: A configured URLRequest
    /// - Throws: Errors from authentication or JSON encoding
    private func asURLRequest(url: URL) async throws -> URLRequest {
        var urlRequest = URLRequest(url: url)

        urlRequest.cachePolicy = cachePolicy
        urlRequest.httpMethod = method.rawValue

        try await authenticationPolicy.provider.authenticate(&urlRequest)

        if let body {
            urlRequest.httpBody = try APIClient.configuration.encoder.encode(body)

            if urlRequest.value(forHTTPHeaderField: "Content-Type") == nil {
                urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
        }

        if urlRequest.value(forHTTPHeaderField: "Accept") == nil {
            urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        }

        if let headers {
            for header in headers where urlRequest.value(forHTTPHeaderField: header.0) == nil {
                urlRequest.setValue(header.1, forHTTPHeaderField: header.0)
            }
        }

        if let timeoutInterval {
            urlRequest.timeoutInterval = timeoutInterval
        }

        return urlRequest
    }

    /// Builds a URL from baseURL and path components
    /// - Returns: A complete URL
    /// - Throws: RequestError if URL construction fails
    private func buildURL() throws -> URL {
        guard let baseURL else {
            throw RequestError.missingBaseURL
        }

        let url: URL = if #available(iOS 16.0, *) {
            baseURL.appending(path: path)
        } else {
            baseURL.appendingPathComponent(path)
        }

        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw RequestError.invalidURL
        }

        if let query, !query.isEmpty {
            components.queryItems = query.map(URLQueryItem.init)
        }

        guard let url = components.url else {
            throw RequestError.invalidURL
        }

        return url
    }
}

extension Request {
    /// Type constraint for request body data
    public typealias Body = Encodable & Sendable

    /// Represents the content type of the request
    public enum ContentType: Sendable {
        /// JSON content type
        case json
        /// Multipart form data content type with fields
        case multipartData([MultipartDataField])
    }
}
