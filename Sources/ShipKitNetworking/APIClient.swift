import Foundation
import StuvyKeychain
import UIKit

public actor APIClient {
    public struct Settings {
        public var baseURL: URL?
    }

    public enum NetworkingError: Error, LocalizedError {
        case serverError(DecodableError)
        case unacceptableStatusCode(Int)
        case invalidResponse
        case tokenUpdateFailed
        case unknown

        public var errorDescription: String? {
            switch self {
            case .serverError(let error):
                if let errorResponse = error as? ErrorResponse {
                    return errorResponse.message
                }

                if let multipleErrorResponse = error as? MultipleErrorsResponse {
                    let errorMessage = multipleErrorResponse.errors.map(\.message).joined(separator: "\n")

                    if !errorMessage.isEmpty {
                        return errorMessage
                    }
                }

                return NSLocalizedString("Error.SomethingWentWrong", bundle: Bundle.module, comment: "")

            case .unacceptableStatusCode(let code):
                return String(format: NSLocalizedString("Error.UnacceptableStatusCode", bundle: Bundle.module, comment: ""), code)

            case .invalidResponse:
                return NSLocalizedString("Error.SomethingWentWrong", bundle: Bundle.module, comment: "")

            case .tokenUpdateFailed:
                return NSLocalizedString("Error.SomethingWentWrong", bundle: Bundle.module, comment: "")

            case .unknown:
                return NSLocalizedString("Error.SomethingWentWrong", bundle: Bundle.module, comment: "")
            }
        }
    }

    public static var settings = Settings()

    private nonisolated let session: URLSession
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    private let cache = URLCache.shared

    public init(configuration: URLSessionConfiguration = .default) {
        session = URLSession(configuration: configuration)
        decoder.dateDecodingStrategy = .iso8601
        encoder.dateEncodingStrategy = .iso8601
    }

    @discardableResult
    public func send<T: Decodable & Sendable>(
        _ request: Request<T>,
        cached: Bool = false,
        retryCount: Int = 1
    ) async throws -> T {
        try await defaultSend(request, cached: cached, retryCount: retryCount)
    }

    @discardableResult
    public func simpleSend<T: Decodable & Sendable>(url: URL) async throws -> T {
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = HTTPMethod.post.rawValue

        let (data, response) = try await session.data(for: urlRequest)

        guard let response = response as? HTTPURLResponse else {
            throw NetworkingError.invalidResponse
        }

        guard 200 ... 299 ~= response.statusCode else {
            if let error = await parseError(from: response, data: data) {
                throw NetworkingError.serverError(error)
            }
            throw NetworkingError.unacceptableStatusCode(response.statusCode)
        }

        return try decoder.decode(T.self, from: data)
    }

    @discardableResult
    public func upload<T: Decodable & Sendable>(
        for request: Request<T>,
        from data: Data,
        retryCount: Int = 1
    ) async throws -> T {
        let urlRequest = try await request.asURLRequest()
        let (data, response) = try await session.upload(for: urlRequest, from: data)

        guard let response = response as? HTTPURLResponse else {
            throw NetworkingError.invalidResponse
        }

        guard 200 ... 299 ~= response.statusCode else {
            if retryCount > 0, response.statusCode == 403 {
                try await updateToken()
                return try await upload(for: request, from: data, retryCount: retryCount - 1)
            }

            if let error = await parseError(from: response, data: data) {
                throw NetworkingError.serverError(error)
            }
            throw NetworkingError.unacceptableStatusCode(response.statusCode)
        }

        return try decoder.decode(T.self, from: data)
    }

    public func data(for request: Request<Data>, retryCount: Int = 1) async throws -> Data {
        let urlRequest = try await request.asURLRequest()

        let (data, response) = try await session.data(for: urlRequest)

        guard let response = response as? HTTPURLResponse else {
            throw NetworkingError.invalidResponse
        }

        guard 200 ... 299 ~= response.statusCode else {
            if retryCount > 0, response.statusCode == 403 {
                try await updateToken()
                return try await self.data(for: request, retryCount: retryCount - 1)
            }

            if let error = await parseError(from: response, data: data) {
                throw NetworkingError.serverError(error)
            }
            throw NetworkingError.unacceptableStatusCode(response.statusCode)
        }

        return data
    }

    public func data(for url: URL, retryCount: Int = 1) async throws -> Data {
        let urlRequest = URLRequest(url: url)

        let (data, response) = try await session.data(for: urlRequest)

        guard let response = response as? HTTPURLResponse else {
            throw NetworkingError.invalidResponse
        }

        guard 200 ... 299 ~= response.statusCode else {
            if retryCount > 0, response.statusCode == 403 {
                try await updateToken()
                return try await self.data(for: url, retryCount: retryCount - 1)
            }

            if let error = await parseError(from: response, data: data) {
                throw NetworkingError.serverError(error)
            }
            throw NetworkingError.unacceptableStatusCode(response.statusCode)
        }

        return data
    }

    private func updateToken() async throws {
        guard let token = TokenStorage.shared.token else { throw NetworkingError.unknown }
        let response = try await defaultSend(
            Endpoints.Authentication.refresh(RefreshTokenPayload(refreshToken: token.refreshToken)),
            retryCount: 0
        )
        TokenStorage.shared.token = response
    }

    @discardableResult
    private func defaultSend<T: Decodable & Sendable>(
        _ request: Request<T>,
        cached: Bool = false,
        retryCount: Int = 0
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
            throw NetworkingError.invalidResponse
        }

        guard 200 ... 299 ~= response.statusCode else {
            if retryCount > 0, response.statusCode == 403 || response.statusCode == 401 {
                try await updateToken()
                return try await defaultSend(request, cached: cached, retryCount: retryCount - 1)
            }

            if let error = await parseError(from: response, data: data) {
                throw NetworkingError.serverError(error)
            }
            throw NetworkingError.unacceptableStatusCode(response.statusCode)
        }

        return try decoder.decode(T.self, from: data)
    }

    private func parseError(from _: HTTPURLResponse, data: Data) async -> DecodableError? {
        do {
            let errorResponse = try decoder.decode(ErrorResponse.self, from: data)
            return errorResponse
        } catch {
            do {
                let multipleErrorsResponse = try decoder.decode(MultipleErrorsResponse.self, from: data)
                return multipleErrorsResponse
            } catch {
                return nil
            }
        }
    }
}
