import Foundation
import StuvyKeychain

public final class TokenStorage: Sendable {
    public static let shared = TokenStorage()

    public var token: Token? {
        get {
            guard let data = KeychainService.load(forKey: "token") else { return nil }
            return try? JSONDecoder().decode(Token.self, from: data)
        }
        set {
            if let token = newValue, let data = try? JSONEncoder().encode(token) {
                KeychainService.save(data, forKey: "token")
            } else {
                KeychainService.delete(forKey: "token")
            }
        }
    }

    private init() {}

    public func clear() {
        KeychainService.delete(forKey: "token")
    }
}
