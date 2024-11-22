import Foundation

public enum APIError: Error, LocalizedError {
    case invalidResponse
    case httpError(response: HTTPURLResponse, data: Data)
}
