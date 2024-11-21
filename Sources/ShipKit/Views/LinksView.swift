import SwiftUI

public struct LinksView: View {
    public let termsOfServiceURL: URL
    public let privacyPolicyURL: URL

    public var body: some View {
        Text(attributedString)
            .font(.caption)
            .tint(.secondary)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
    }

    var attributedString: AttributedString {
        var termsOfService = try! AttributedString(markdown: String(localizable: .termsOfServiceLink(termsOfServiceURL.absoluteString)))
        termsOfService.underlineStyle = .single
        let and = AttributedString(String(localizable: .and))
        var privacyPolicy = try! AttributedString(markdown: String(localizable: .privacyPolicyLink(privacyPolicyURL.absoluteString)))
        privacyPolicy.underlineStyle = .single
        return termsOfService + " " + and + " " + privacyPolicy
    }
}
