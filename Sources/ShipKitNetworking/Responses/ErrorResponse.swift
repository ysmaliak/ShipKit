import Foundation

public struct ErrorResponse: DecodableError {
    public let message: String
}

extension ErrorResponse {
    enum CodingKeys: String, CodingKey {
        case message = "error"
    }
}
