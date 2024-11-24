import Foundation

extension JSONDecoder {
    /// A pre-configured JSONDecoder instance that handles ISO8601 date formats.
    ///
    /// This decoder is configured to automatically parse ISO8601 formatted date strings
    /// into Swift Date objects. It's particularly useful when dealing with REST APIs
    /// that follow the ISO8601 standard for date representations.
    ///
    /// Example usage:
    /// ```swift
    /// let data = jsonString.data(using: .utf8)!
    /// let result = try JSONDecoder.iso8601.decode(Response.self, from: data)
    /// ```
    ///
    /// - Note: This is implemented as a static property to ensure we're reusing the same
    ///         decoder instance across multiple decoding operations, which is more efficient
    ///         than creating a new decoder each time.
    public static let iso8601: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
