import Foundation

public struct MultipleErrorsResponse: DecodableError {
    public let errors: [NetworkingErrorResponse]
}

public struct NetworkingErrorResponse: DecodableError {
    public let type: String?
    public let value: String?
    public let message: String
}

extension NetworkingErrorResponse {
    enum CodingKeys: String, CodingKey {
        case type
        case value
        case message = "msg"
    }
}
