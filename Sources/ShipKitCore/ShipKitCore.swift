import Foundation

public actor ShipKitCoreManager {
    public static var configuration = Configuration()

    public static func configure(with configuration: Configuration) {
        self.configuration = configuration
    }

    public static func configure(revenueCatAPIKey: String?) {
        configuration.revenueCatAPIKey = revenueCatAPIKey
    }
}
