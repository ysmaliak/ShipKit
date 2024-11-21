import Foundation

extension Bundle {
    public var appName: String {
        infoDictionary?["CFBundleName"] as? String ?? "Unknown"
    }

    public var appVersionShort: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }

    public var appVersionBuild: String {
        infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }

    public var appVersionLong: String {
        "\(appVersionShort) (\(appVersionBuild))"
    }
}
