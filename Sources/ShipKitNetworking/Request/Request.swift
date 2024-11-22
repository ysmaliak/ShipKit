import Foundation

public typealias Body = Encodable & Sendable

public struct Request<Response: Decodable>: Sendable {
    public enum RequestError: Error, LocalizedError {
        case invalidURL
        case invalidParameters
        case missingBaseURL

        public var errorDescription: String? {
            switch self {
            case .invalidURL:
                NSLocalizedString("Error.SomethingWentWrong", bundle: Bundle.module, comment: "")
            case .invalidParameters:
                NSLocalizedString("Error.SomethingWentWrong", bundle: Bundle.module, comment: "")
            case .missingBaseURL:
                NSLocalizedString("Error.SomethingWentWrong", bundle: Bundle.module, comment: "")
            }
        }
    }

    public enum ContentType: Sendable {
        case json
        case multipartData([MultipartDataField])
    }

    public let method: HTTPMethod
    public let baseURL: URL?
    public let path: String
    public let absoluteURL: URL?
    public let contentType: ContentType
    public let query: [String: String]?
    public let headers: [String: String]?
    public let body: Body?
    public let cachePolicy: URLRequest.CachePolicy
    public let timeoutInterval: TimeInterval?
    public let authenticationPolicy: AuthenticationPolicy

    public init(
        method: HTTPMethod,
        baseURL: URL? = APIClient.settings.baseURL,
        path: String,
        contentType: ContentType,
        query: [String: String]? = nil,
        headers: [String: String]? = nil,
        body: Body? = nil,
        cachePolicy: URLRequest.CachePolicy = .reloadIgnoringLocalAndRemoteCacheData,
        timeoutInterval: TimeInterval? = 30,
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
        self.cachePolicy = cachePolicy
        self.timeoutInterval = timeoutInterval
        self.authenticationPolicy = authenticationPolicy
    }

    init(
        method: HTTPMethod,
        absoluteURL: URL,
        contentType: ContentType,
        query: [String: String]? = nil,
        headers: [String: String]? = nil,
        body: Body? = nil,
        cachePolicy: URLRequest.CachePolicy = .reloadIgnoringLocalAndRemoteCacheData,
        timeoutInterval: TimeInterval? = 30,
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
        self.cachePolicy = cachePolicy
        self.timeoutInterval = timeoutInterval
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

public struct RetryPolicy {
    public var strategy: RetryStrategy
    public var maxRetries: Int
    public var currentAttempt: Int

    public init(
        strategy: RetryStrategy = DefaultRetryStrategy(),
        maxRetries: Int = 3
    ) {
        self.strategy = strategy
        self.maxRetries = maxRetries
        currentAttempt = 0
    }
}

public struct AuthenticationPolicy: Sendable {
    public var provider: AuthenticationProvider

    public init(provider: AuthenticationProvider) {
        self.provider = provider
    }
}

extension JSONEncoder {
    fileprivate static let defaultRequestEncoder = JSONEncoder()
}

public protocol AuthenticationProvider: Sendable {
    func authenticate(_ request: inout URLRequest) async throws
    func handleAuthenticationFailure(_ response: HTTPURLResponse) async throws -> Bool
}

public protocol RetryStrategy {
    func shouldRetry(_ error: Error, attempt: Int) -> Bool
    func delay(forAttempt attempt: Int) -> TimeInterval
}

public struct DefaultRetryStrategy: RetryStrategy {
    private let baseDelay: TimeInterval
    private let multiplier: Double
    private let retryableStatusCodes: Set<Int>

    public init(
        baseDelay: TimeInterval = 0.3,
        multiplier: Double = 1.0,
        retryableStatusCodes: Set<Int> = [408, 500, 502, 503, 504]
    ) {
        self.baseDelay = baseDelay
        self.multiplier = multiplier
        self.retryableStatusCodes = retryableStatusCodes
    }

    public func shouldRetry(_ error: Error, attempt _: Int) -> Bool {
        guard let urlError = error as? URLError else {
            return false
        }

        switch urlError.code {
        case .timedOut, .networkConnectionLost:
            return true
        default:
            if let response = urlError.errorUserInfo[NSUnderlyingErrorKey] as? HTTPURLResponse {
                return retryableStatusCodes.contains(response.statusCode)
            }
            return false
        }
    }

    public func delay(forAttempt attempt: Int) -> TimeInterval {
        baseDelay * pow(multiplier, Double(attempt - 1))
    }
}
//
//public struct BearerTokenAuthProvider: AuthenticationProvider {
//    private let tokenStorage: TokenStorage
//
//    public init(tokenStorage: TokenStorage = .shared) {
//        self.tokenStorage = tokenStorage
//    }
//
//    public func authenticate(_ request: inout URLRequest) async throws {
//        guard let token = tokenStorage.token?.accessToken else { return }
//        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
//    }
//
//    public func handleAuthenticationFailure(_ error: Error) async throws -> Bool {
//        guard let response = (error as? URLError)?.errorUserInfo[NSUnderlyingErrorKey] as? HTTPURLResponse,
//              response.statusCode == 401 || response.statusCode == 403 else {
//            return false
//        }
//
//        // Here you can implement token refresh logic
//        // Return true if token was refreshed successfully
//        return false
//    }
//}

public struct NoRetryStrategy: RetryStrategy {
    public init() {}

    public func shouldRetry(_: Error, attempt _: Int) -> Bool {
        false
    }

    public func delay(forAttempt _: Int) -> TimeInterval {
        0
    }
}

public struct NoAuthProvider: AuthenticationProvider {
    public init() {}

    public func authenticate(_: inout URLRequest) async throws {}

    public func handleAuthenticationFailure(_: HTTPURLResponse) async throws -> Bool {
        false
    }
}

extension RetryPolicy {
    public static var none: Self {
        RetryPolicy(strategy: NoRetryStrategy(), maxRetries: 0)
    }

    public static var `default`: Self {
        RetryPolicy(strategy: DefaultRetryStrategy(), maxRetries: 3)
    }
}

extension AuthenticationPolicy {
    public static var none: Self {
        AuthenticationPolicy(provider: NoAuthProvider())
    }
}
