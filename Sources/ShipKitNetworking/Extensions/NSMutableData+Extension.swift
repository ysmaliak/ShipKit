import Foundation

extension NSMutableData {
    /// Appends a string to the mutable data buffer by converting it to UTF-8 encoded data.
    ///
    /// This method is particularly useful when building multipart form data or other string-based
    /// data structures that need to be converted to raw bytes.
    ///
    /// Example usage:
    /// ```swift
    /// let data = NSMutableData()
    /// data.append(string: "Hello, World!")
    /// ```
    ///
    /// - Parameter string: The string to append to the data buffer
    /// - Note: If the string cannot be encoded as UTF-8, this method will silently fail
    ///         and no data will be appended
    public func append(string: String) {
        guard let data = string.data(using: .utf8) else { return }
        append(data)
    }
}
