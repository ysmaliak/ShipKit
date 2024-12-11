import Foundation

public actor ShipKitUIManager {
    public static var configuration = Configuration()

    public static func configure(_ configuration: Configuration) {
        ShipKitUIManager.configuration = configuration
    }

    public static func configure(premiumEntitlement: String?, privacyPolicyURL: URL?, termsOfServiceURL: URL?, appID: String?) {
        ShipKitUIManager.configuration.premiumEntitlement = premiumEntitlement
        ShipKitUIManager.configuration.privacyPolicyURL = privacyPolicyURL
        ShipKitUIManager.configuration.termsOfServiceURL = termsOfServiceURL
        ShipKitUIManager.configuration.appID = appID
    }
}
