import Foundation

public enum Endpoints {
    public enum Authentication {
        /// Refresh session for the current user
        /// - Parameter token: Current session token
        /// - Returns: New session token
        public static func refresh(_ token: RefreshTokenPayload) -> Request<Token> {
            Request<Token>(
                method: .post,
                path: "auth/refresh",
                contentType: .json,
                body: token
            )
        }
    }
}
