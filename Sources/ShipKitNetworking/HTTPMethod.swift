import Foundation

/// Represents standard HTTP methods (verbs) used in network requests.
///
/// This enum defines the standard HTTP methods as specified in:
/// - RFC 7231 (HTTP/1.1)
/// - RFC 5789 (PATCH method)
///
/// Example usage:
/// ```swift
/// let request = Request<Response>(
///     method: .get,
///     path: "/users"
/// )
/// ```
public enum HTTPMethod: String, Sendable {
    /// GET method - Retrieve a resource.
    ///
    /// Used to request data from a specified resource. GET requests:
    /// - Should only retrieve data
    /// - Should not modify server state
    /// - Can be cached
    /// - Remain in browser history
    /// - Can be bookmarked
    case get = "GET"

    /// POST method - Submit data to be processed.
    ///
    /// Used to send data to create or update a resource. POST requests:
    /// - Can modify server state
    /// - Can create new resources
    /// - Are not cached by default
    /// - Are not retained in browser history
    /// - Cannot be bookmarked
    case post = "POST"

    /// PUT method - Update a resource.
    ///
    /// Used to update an existing resource or create a new one. PUT requests:
    /// - Are idempotent (multiple identical requests should have same effect as single request)
    /// - Replace the entire resource at the specified URL
    /// - Create the resource if it doesn't exist
    case put = "PUT"

    /// DELETE method - Remove a resource.
    ///
    /// Used to request the removal of a resource. DELETE requests:
    /// - Are idempotent
    /// - May return a response body
    /// - Cannot be cached
    case delete = "DELETE"

    /// PATCH method - Partially modify a resource.
    ///
    /// Used to apply partial modifications to a resource. PATCH requests:
    /// - May not be idempotent
    /// - Only send the changes, not the entire resource
    /// - Are not guaranteed to be safe
    case patch = "PATCH"

    /// OPTIONS method - Get allowed methods.
    ///
    /// Used to describe the communication options for the target resource. OPTIONS requests:
    /// - Are safe (don't modify resources)
    /// - Are commonly used for CORS preflight requests
    /// - Return allowed HTTP methods and other capabilities
    case options = "OPTIONS"

    /// HEAD method - Get response headers only.
    ///
    /// Identical to GET but returns only HTTP headers, no body. HEAD requests:
    /// - Are safe
    /// - Can be cached
    /// - Useful for checking resource metadata
    /// - Often used to test hyperlinks for validity
    case head = "HEAD"

    /// TRACE method - Diagnostic tool.
    ///
    /// Used to retrieve a diagnostic trace of the request chain. TRACE requests:
    /// - Are safe
    /// - Should not include a body
    /// - Typically used for debugging
    /// - May pose security risks if enabled
    case trace = "TRACE"

    /// CONNECT method - Establish tunnel.
    ///
    /// Used to establish a network connection through a proxy. CONNECT requests:
    /// - Typically used with SSL (HTTPS)
    /// - Convert the request connection to a transparent TCP/IP tunnel
    /// - Usually used to facilitate HTTPS through an HTTP proxy
    case connect = "CONNECT"
}
