import SwiftUI

/// A view that displays Privacy Policy and Terms of Service links.
///
/// This view creates a formatted text string containing clickable links to both
/// the Privacy Policy and Terms of Service, separated by the word "and".
///
/// Example usage:
/// ```swift
/// LinksView(
///     privacyPolicyURL: URL(string: "https://example.com/privacy")!,
///     termsOfServiceURL: URL(string: "https://example.com/terms")!
/// )
/// ```
///
/// The view automatically:
/// - Formats links with underlines
/// - Uses secondary color for text
/// - Centers the text
/// - Applies caption font size
public struct LinksView: View {
    /// URL for the Privacy Policy document.
    public let privacyPolicyURL: URL

    /// URL for the Terms of Service document.
    public let termsOfServiceURL: URL

    /// Creates a new LinksView instance.
    ///
    /// - Parameters:
    ///   - privacyPolicyURL: URL to the Privacy Policy document
    ///   - termsOfServiceURL: URL to the Terms of Service document
    public init(
        privacyPolicyURL: URL,
        termsOfServiceURL: URL
    ) {
        self.privacyPolicyURL = privacyPolicyURL
        self.termsOfServiceURL = termsOfServiceURL
    }

    public var body: some View {
        Text(attributedString)
            .font(.caption)
            .tint(.secondary)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
    }

    /// Creates an attributed string containing the formatted links.
    ///
    /// The resulting string includes:
    /// - Underlined Privacy Policy link
    /// - The word "and"
    /// - Underlined Terms of Service link
    ///
    /// - Returns: An AttributedString with formatted links
    private var attributedString: AttributedString {
        var privacyPolicy = try! AttributedString(
            markdown: String(localizable: .privacyPolicyLink(privacyPolicyURL.absoluteString))
        )
        privacyPolicy.underlineStyle = .single
        let and = AttributedString(String(localizable: .and))
        var termsOfService = try! AttributedString(
            markdown: String(localizable: .termsOfServiceLink(termsOfServiceURL.absoluteString))
        )
        termsOfService.underlineStyle = .single
        return privacyPolicy + " " + and + " " + termsOfService
    }
}
