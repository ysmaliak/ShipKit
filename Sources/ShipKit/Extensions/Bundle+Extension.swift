import Foundation

extension Bundle {
    var appName: String {
        infoDictionary?["CFBundleName"] as? String ?? "Unknown"
    }

    var appVersionShort: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }

    var appVersionBuild: String {
        infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }

    var appVersionLong: String {
        "\(appVersionShort) (\(appVersionBuild))"
    }
}
