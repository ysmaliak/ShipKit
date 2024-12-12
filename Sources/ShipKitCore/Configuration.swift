import Foundation
import RevenueCat

public struct Configuration {
    public var revenueCatAPIKey: String? {
        didSet {
            if let apiKey = revenueCatAPIKey {
                Purchases.configure(withAPIKey: apiKey)
            }
        }
    }
}
