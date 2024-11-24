import Foundation

public actor APIClient {
    public static var configuration = APIConfiguration()

    private var session: URLSession {
        URLSession(configuration: APIClient.configuration.urlSessionConfiguration)
    }

    private var decoder: JSONDecoder { APIClient.configuration.decoder }
    private var encoder: JSONEncoder { APIClient.configuration.encoder }
    private var cache: URLCache { APIClient.configuration.cache }

    @discardableResult
    public func send<T: Decodable & Sendable>(
        _ request: Request<T>,
        cached: Bool = false,
        retryPolicy: RetryPolicy = .default
    ) async throws -> T {
        try await defaultSend(request, cached: cached, retryPolicy: retryPolicy)
    }

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

        guard 200 ... 299 ~= response.statusCode else {
            let error = APIError.httpError(response: response, data: data)
            if retryPolicy.strategy.shouldRetry(error, attempt: retryPolicy.currentAttempt),
               response.statusCode == 403 || response.statusCode == 401 {
                var retryPolicy = retryPolicy
                retryPolicy.currentAttempt += 1
                guard try await request.authenticationPolicy.provider.attemptAuthenticationRecovery(
                    for: response,
                    responseData: data
                ) else { throw error }
                return try await upload(for: request, from: data, retryPolicy: retryPolicy)
            } else if retryPolicy.strategy.shouldRetry(error, attempt: retryPolicy.currentAttempt) {
                var retryPolicy = retryPolicy
                retryPolicy.currentAttempt += 1
                return try await upload(for: request, from: data, retryPolicy: retryPolicy)
            }

            throw error
        }

        return try decoder.decode(T.self, from: data)
    }

    public func data(for request: Request<Data>, retryPolicy: RetryPolicy = .default) async throws -> Data {
        let urlRequest = try await request.asURLRequest()

        let (data, response) = try await session.data(for: urlRequest)

        guard let response = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard 200 ... 299 ~= response.statusCode else {
            let error = APIError.httpError(response: response, data: data)
            if retryPolicy.strategy.shouldRetry(error, attempt: retryPolicy.currentAttempt),
               response.statusCode == 403 || response.statusCode == 401 {
                var retryPolicy = retryPolicy
                retryPolicy.currentAttempt += 1
                guard try await request.authenticationPolicy.provider.attemptAuthenticationRecovery(
                    for: response,
                    responseData: data
                ) else { throw error }
                return try await self.data(for: request, retryPolicy: retryPolicy)
            } else if retryPolicy.strategy.shouldRetry(error, attempt: retryPolicy.currentAttempt) {
                var retryPolicy = retryPolicy
                retryPolicy.currentAttempt += 1
                return try await self.data(for: request, retryPolicy: retryPolicy)
            }

            throw APIError.httpError(response: response, data: data)
        }

        return data
    }

    public func data(for url: URL, retryPolicy: RetryPolicy = .default) async throws -> Data {
        let urlRequest = URLRequest(url: url)

        let (data, response) = try await session.data(for: urlRequest)

        guard let response = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

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

    @discardableResult
    private func defaultSend<T: Decodable & Sendable>(
        _ request: Request<T>,
        cached: Bool = false,
        retryPolicy: RetryPolicy = .default
    ) async throws -> T {
        let urlRequest = try await request.asURLRequest()

        let data: Data
        let response: URLResponse

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

        guard 200 ... 299 ~= response.statusCode else {
            let error = APIError.httpError(response: response, data: data)
            if retryPolicy.strategy.shouldRetry(error, attempt: retryPolicy.currentAttempt),
               response.statusCode == 403 || response.statusCode == 401 {
                var retryPolicy = retryPolicy
                retryPolicy.currentAttempt += 1
                guard try await request.authenticationPolicy.provider.attemptAuthenticationRecovery(
                    for: response,
                    responseData: data
                ) else { throw error }
                return try await defaultSend(request, cached: cached, retryPolicy: retryPolicy)
            } else if retryPolicy.strategy.shouldRetry(error, attempt: retryPolicy.currentAttempt) {
                var retryPolicy = retryPolicy
                retryPolicy.currentAttempt += 1
                return try await defaultSend(request, cached: cached, retryPolicy: retryPolicy)
            }

            throw APIError.httpError(response: response, data: data)
        }

        return try decoder.decode(T.self, from: data)
    }
}
