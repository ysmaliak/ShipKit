import Foundation

public struct APIConfiguration {
    public var baseURL: URL?
    public var urlSessionConfiguration: URLSessionConfiguration = .default
    public var decoder: JSONDecoder = .iso8601
    public var encoder: JSONEncoder = .iso8601
    public var cache: URLCache = .shared
}
