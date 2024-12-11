import Foundation
import RevenueCat
@_exported import ShipKitCore
@_exported import ShipKitNetworking
@_exported import ShipKitUI

public enum ShipKitManager {
    public static func configure(
        revenueCatAPIKey: String? = nil,
        premiumEntitlement: String? = nil,
        privacyPolicyURL: URL? = nil,
        termsOfServiceURL: URL? = nil,
        appID: String? = nil,
        baseURL: URL? = nil,
        urlSessionConfiguration: URLSessionConfiguration = .default,
        decoder: JSONDecoder = .iso8601,
        encoder: JSONEncoder = .iso8601,
        cache: URLCache = .shared
    ) {
        ShipKitCoreManager.configure(revenueCatAPIKey: revenueCatAPIKey)
        ShipKitUIManager.configure(
            premiumEntitlement: premiumEntitlement,
            privacyPolicyURL: privacyPolicyURL,
            termsOfServiceURL: termsOfServiceURL,
            appID: appID
        )
        NetworkManager.configure(
            baseURL: baseURL,
            urlSessionConfiguration: urlSessionConfiguration,
            decoder: decoder,
            encoder: encoder,
            cache: cache
        )
    }
}
