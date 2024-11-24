import Foundation

/// An actor that handles network requests with built-in retry and authentication support.
///
/// APIClient provides a type-safe way to make network requests with automatic
/// JSON encoding/decoding, authentication, caching, and retry capabilities.
///
/// Example usage:
/// ```swift
/// let client = APIClient()
/// let response: UserData = try await client.send(
///     Request<UserData>(method: .get, path: "/user")
/// )
/// ```
public actor APIClient {
    /// Global configuration settings for all API clients
    public static var configuration = APIConfiguration()

    /// The URLSession used for network requests
    ///
    /// Created lazily with the current configuration settings
    private var session: URLSession {
        URLSession(configuration: APIClient.configuration.urlSessionConfiguration)
    }

    /// JSON decoder used for parsing responses
    private var decoder: JSONDecoder { APIClient.configuration.decoder }

    /// JSON encoder used for request bodies
    private var encoder: JSONEncoder { APIClient.configuration.encoder }

    /// Cache for storing and retrieving responses
    private var cache: URLCache { APIClient.configuration.cache }

    /// Sends a network request and decodes the response.
    ///
    /// - Parameters:
    ///   - request: The typed request to send
    ///   - cached: Whether to use cached responses if available
    ///   - retryPolicy: Policy determining retry behavior for failed requests
    /// - Returns: The decoded response of type T
    /// - Throws: APIError or any error from the network request or decoding
    @discardableResult
    public func send<T: Decodable & Sendable>(
        _ request: Request<T>,
        cached: Bool = false,
        retryPolicy: RetryPolicy = .default
    ) async throws -> T {
        try await defaultSend(request, cached: cached, retryPolicy: retryPolicy)
    }

    /// Uploads data with a network request and decodes the response.
    ///
    /// - Parameters:
    ///   - request: The typed request to send
    ///   - data: The data to upload
    ///   - retryPolicy: Policy determining retry behavior for failed requests
    /// - Returns: The decoded response of type T
    /// - Throws: APIError or any error from the network request or decoding
    @discardableResult
    public func upload<T: Decodable & Sendable>(
        for request: Request<T>,
        from data: Data,
        retryPolicy: RetryPolicy = .default
    ) async throws -> T {
        let urlRequest = try await request.asURLRequest()
        let (data, response) = try await session.upload(for: urlRequest, from: data)

        guard let response = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        // Handle HTTP errors and retry logic
        guard 200 ... 299 ~= response.statusCode else {
            let error = APIError.httpError(response: response, data: data)
            // Handle authentication errors (401, 403)
            if retryPolicy.strategy.shouldRetry(error, attempt: retryPolicy.currentAttempt),
               response.statusCode == 403 || response.statusCode == 401 {
                var retryPolicy = retryPolicy
                retryPolicy.currentAttempt += 1
                guard try await request.authenticationPolicy.provider.attemptAuthenticationRecovery(
                    for: response,
                    responseData: data
                ) else { throw error }
                return try await upload(for: request, from: data, retryPolicy: retryPolicy)
            }
            // Handle other retryable errors
            else if retryPolicy.strategy.shouldRetry(error, attempt: retryPolicy.currentAttempt) {
                var retryPolicy = retryPolicy
                retryPolicy.currentAttempt += 1
                return try await upload(for: request, from: data, retryPolicy: retryPolicy)
            }

            throw error
        }

        return try decoder.decode(T.self, from: data)
    }

    /// Downloads data from a URL with retry support.
    ///
    /// - Parameters:
    ///   - request: The request for raw data
    ///   - retryPolicy: Policy determining retry behavior for failed requests
    /// - Returns: The downloaded data
    /// - Throws: APIError or any network request error
    public func data(for request: Request<Data>, retryPolicy: RetryPolicy = .default) async throws -> Data {
        let urlRequest = try await request.asURLRequest()
        let (data, response) = try await session.data(for: urlRequest)

        guard let response = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        // Handle HTTP errors and retry logic
        guard 200 ... 299 ~= response.statusCode else {
            let error = APIError.httpError(response: response, data: data)
            // Handle authentication errors
            if retryPolicy.strategy.shouldRetry(error, attempt: retryPolicy.currentAttempt),
               response.statusCode == 403 || response.statusCode == 401 {
                var retryPolicy = retryPolicy
                retryPolicy.currentAttempt += 1
                guard try await request.authenticationPolicy.provider.attemptAuthenticationRecovery(
                    for: response,
                    responseData: data
                ) else { throw error }
                return try await self.data(for: request, retryPolicy: retryPolicy)
            }
            // Handle other retryable errors
            else if retryPolicy.strategy.shouldRetry(error, attempt: retryPolicy.currentAttempt) {
                var retryPolicy = retryPolicy
                retryPolicy.currentAttempt += 1
                return try await self.data(for: request, retryPolicy: retryPolicy)
            }

            throw APIError.httpError(response: response, data: data)
        }

        return data
    }

    /// Downloads data from a raw URL with retry support.
    ///
    /// - Parameters:
    ///   - url: The URL to download from
    ///   - retryPolicy: Policy determining retry behavior for failed requests
    /// - Returns: The downloaded data
    /// - Throws: APIError or any network request error
    public func data(for url: URL, retryPolicy: RetryPolicy = .default) async throws -> Data {
        let urlRequest = URLRequest(url: url)
        let (data, response) = try await session.data(for: urlRequest)

        guard let response = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        // Handle HTTP errors and retry logic
        guard 200 ... 299 ~= response.statusCode else {
            let error = APIError.httpError(response: response, data: data)
            if retryPolicy.strategy.shouldRetry(error, attempt: retryPolicy.currentAttempt) {
                var retryPolicy = retryPolicy
                retryPolicy.currentAttempt += 1
                return try await self.data(for: url, retryPolicy: retryPolicy)
            }

            throw APIError.httpError(response: response, data: data)
        }

        return data
    }

    /// Internal method to handle the common request sending logic.
    ///
    /// - Parameters:
    ///   - request: The typed request to send
    ///   - cached: Whether to use cached responses
    ///   - retryPolicy: Policy for handling request failures
    /// - Returns: The decoded response of type T
    /// - Throws: APIError or any error from the network request or decoding
    @discardableResult
    private func defaultSend<T: Decodable & Sendable>(
        _ request: Request<T>,
        cached: Bool = false,
        retryPolicy: RetryPolicy = .default
    ) async throws -> T {
        let urlRequest = try await request.asURLRequest()

        let data: Data
        let response: URLResponse

        // Handle cached responses
        if cached, let cachedResponse = cache.cachedResponse(for: urlRequest) {
            data = cachedResponse.data
            response = cachedResponse.response
        } else {
            (data, response) = try await session.data(for: urlRequest)

            if cached {
                cache.storeCachedResponse(CachedURLResponse(response: response, data: data), for: urlRequest)
            }
        }

        guard let response = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        // Handle HTTP errors and retry logic
        guard 200 ... 299 ~= response.statusCode else {
            let error = APIError.httpError(response: response, data: data)
            // Handle authentication errors
            if retryPolicy.strategy.shouldRetry(error, attempt: retryPolicy.currentAttempt),
               response.statusCode == 403 || response.statusCode == 401 {
                var retryPolicy = retryPolicy
                retryPolicy.currentAttempt += 1
                guard try await request.authenticationPolicy.provider.attemptAuthenticationRecovery(
                    for: response,
                    responseData: data
                ) else { throw error }
                return try await defaultSend(request, cached: cached, retryPolicy: retryPolicy)
            }
            // Handle other retryable errors
            else if retryPolicy.strategy.shouldRetry(error, attempt: retryPolicy.currentAttempt) {
                var retryPolicy = retryPolicy
                retryPolicy.currentAttempt += 1
                return try await defaultSend(request, cached: cached, retryPolicy: retryPolicy)
            }

            throw APIError.httpError(response: response, data: data)
        }

        return try decoder.decode(T.self, from: data)
    }
}
