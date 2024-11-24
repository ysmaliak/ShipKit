import Foundation

/// Represents a single field in a multipart form data request
public struct MultipartDataField: Sendable {
    /// Parameters associated with the field (e.g., name, filename)
    public let parameters: [String: String]

    /// The actual data content of the field
    public let data: Data

    /// The MIME type of the data, if applicable
    public let mimeType: String?

    /// Creates a new multipart data field
    /// - Parameters:
    ///   - parameters: Key-value pairs of parameters for the field
    ///   - data: The content data
    ///   - mimeType: Optional MIME type of the content
    public init(parameters: [String: String], data: Data, mimeType: String? = nil) {
        self.parameters = parameters
        self.data = data
        self.mimeType = mimeType
    }
}

/// Handles the creation of multipart/form-data requests
public struct MultipartData {
    /// Unique boundary string to separate form fields
    private let boundary = "Boundary-\(UUID().uuidString.lowercased())"

    /// Accumulated HTTP body data
    private var httpBody = NSMutableData()

    public init() {}

    /// Adds a data field to the form
    /// - Parameter field: The field to add
    public func addDataField(_ field: MultipartDataField) {
        httpBody.append(dataFormField(field))
    }

    /// Creates a URLRequest configured for multipart form data
    /// - Parameters:
    ///   - url: The target URL
    ///   - method: HTTP method to use
    ///   - headers: Optional additional HTTP headers
    ///   - cachePolicy: Cache policy for the request
    ///   - timeoutInterval: Optional timeout duration
    ///   - retryPolicy: Policy for request retries
    ///   - authenticationPolicy: Policy for request authentication
    /// - Returns: A configured URLRequest
    /// - Throws: Authentication errors or other request creation errors
    public func asURLRequest(
        url: URL,
        method: HTTPMethod,
        headers: [String: String]?,
        cachePolicy: URLRequest.CachePolicy = .reloadIgnoringLocalAndRemoteCacheData,
        timeoutInterval: TimeInterval? = 30,
        retryPolicy _: RetryPolicy = .default,
        authenticationPolicy: AuthenticationPolicy = .none
    ) async throws -> URLRequest {
        var urlRequest = URLRequest(url: url)
        urlRequest.cachePolicy = cachePolicy

        try await authenticationPolicy.provider.authenticate(&urlRequest)

        if let headers {
            for header in headers where urlRequest.value(forHTTPHeaderField: header.0) == nil {
                urlRequest.setValue(header.1, forHTTPHeaderField: header.0)
            }
        }

        urlRequest.httpMethod = method.rawValue
        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        httpBody.append(string: "--\(boundary)--")
        urlRequest.httpBody = httpBody as Data

        if let timeoutInterval {
            urlRequest.timeoutInterval = timeoutInterval
        }

        return urlRequest
    }

    /// Formats a single field into multipart form data format
    /// - Parameter field: The field to format
    /// - Returns: Formatted data for the field
    private func dataFormField(_ field: MultipartDataField) -> Data {
        let fieldData = NSMutableData()

        fieldData.append(string: "--\(boundary)\r\n")

        var content = "Content-Disposition: form-data"
        for (key, value) in field.parameters {
            content.append("; \(key)=\"\(value)\"")
        }
        content.append("\r\n")
        fieldData.append(string: content)

        if let mimeType = field.mimeType {
            fieldData.append(string: "Content-Type: \(mimeType)\r\n")
        }
        fieldData.append(string: "\r\n")
        fieldData.append(string: field.data.base64EncodedString())
        fieldData.append(string: "\r\n")

        return fieldData as Data
    }
}
