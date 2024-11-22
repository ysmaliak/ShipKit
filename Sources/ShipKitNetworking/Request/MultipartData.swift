import Foundation

public struct MultipartDataField: Sendable {
    public let parameters: [String: String]
    public let data: Data
    public let mimeType: String?

    public init(parameters: [String: String], data: Data, mimeType: String? = nil) {
        self.parameters = parameters
        self.data = data
        self.mimeType = mimeType
    }
}

public struct MultipartData {
    private let boundary = "Boundary-\(UUID().uuidString.lowercased())"
    private var httpBody = NSMutableData()

    public func addDataField(_ field: MultipartDataField) {
        httpBody.append(dataFormField(field))
    }

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
