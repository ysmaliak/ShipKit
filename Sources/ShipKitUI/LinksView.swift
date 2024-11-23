import Inject
import SwiftUI

public struct LinksView: View {
    public let privacyPolicyURL: URL
    public let termsOfServiceURL: URL

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
        var privacyPolicy = try! AttributedString(markdown: String(localizable: .privacyPolicyLink(privacyPolicyURL.absoluteString)))
        privacyPolicy.underlineStyle = .single
        let and = AttributedString(String(localizable: .and))
        var termsOfService = try! AttributedString(markdown: String(localizable: .termsOfServiceLink(termsOfServiceURL.absoluteString)))
        termsOfService.underlineStyle = .single
        return privacyPolicy + " " + and + " " + termsOfService
    }
}
