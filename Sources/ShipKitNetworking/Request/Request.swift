import Foundation

public struct Request<Response: Decodable>: Sendable {
    public let method: HTTPMethod
    public let baseURL: URL?
    public let path: String
    public let absoluteURL: URL?
    public let contentType: ContentType
    public let query: [String: String]?
    public let headers: [String: String]?
    public let body: Body?
    public let timeoutInterval: TimeInterval?
    public let cachePolicy: URLRequest.CachePolicy
    public let authenticationPolicy: AuthenticationPolicy

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

    init(
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

    private func asURLRequest(url: URL) async throws -> URLRequest {
        var urlRequest = URLRequest(url: url)

        urlRequest.cachePolicy = cachePolicy
        urlRequest.httpMethod = method.rawValue

        try await authenticationPolicy.provider.authenticate(&urlRequest)

        if let body {
            urlRequest.httpBody = try JSONEncoder.defaultRequestEncoder.encode(body)

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
    public typealias Body = Encodable & Sendable

    public enum ContentType: Sendable {
        case json
        case multipartData([MultipartDataField])
    }
}
