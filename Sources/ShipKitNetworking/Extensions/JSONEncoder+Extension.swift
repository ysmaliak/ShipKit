import Foundation

extension JSONEncoder {
    /// A pre-configured JSONEncoder instance that handles ISO8601 date formats.
    ///
    /// This encoder is configured to automatically convert Swift Date objects into
    /// ISO8601 formatted date strings. It's particularly useful when working with REST APIs
    /// that expect dates to be formatted according to the ISO8601 standard.
    ///
    /// Example usage:
    /// ```swift
    /// let model = MyModel(date: Date())
    /// let jsonData = try JSONEncoder.iso8601.encode(model)
    /// ```
    ///
    /// - Note: This is implemented as a static property to ensure we're reusing the same
    ///         encoder instance across multiple encoding operations, which is more efficient
    ///         than creating a new encoder each time.
    public static let iso8601: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
}
