import SwiftUI
import Inject

public struct LinksView: View {
    public let termsOfServiceURL: URL
    public let privacyPolicyURL: URL

    @ObserveInjection private var inject

    public var body: some View {
        Text(attributedString)
            .font(.caption)
            .tint(.secondary)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .enableInjection()
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
