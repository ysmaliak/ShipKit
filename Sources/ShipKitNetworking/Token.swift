import Foundation

public struct Token: Codable, Sendable {
    public let accessToken: String
    public let refreshToken: String
}
