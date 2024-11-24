import ComposableArchitecture
import MessageUI
import SwiftUI

/// A reducer that manages the state and actions for mail composition.
///
/// This feature handles the presentation and dismissal of the mail composer interface,
/// managing the email content and recipient information.
///
/// Example usage:
/// ```swift
/// let store = Store(initialState: MailComposerFeature.State(
///     recipient: "support@example.com",
///     subject: "Help",
///     body: "I need assistance"
/// )) {
///     MailComposerFeature()
/// }
/// ```
@Reducer
public struct MailComposerFeature: Sendable {
    /// The state for mail composition.
    public struct State: Equatable {
        /// The email address of the recipient
        public let recipient: String

        /// The subject line of the email
        public let subject: String

        /// The body content of the email
        public let body: String
    }

    /// Actions that can be performed in the mail composer.
    public enum Action {
        /// Triggered when the mail composer should be dismissed
        case dismiss
    }

    /// Dependency for dismissing the mail composer
    @Dependency(\.dismiss) private var dismiss

    /// The reducer's body implementing the composition logic.
    public var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
            case .dismiss:
                .run { _ in await dismiss() }
            }
        }
    }
}

/// A SwiftUI view that wraps MFMailComposeViewController for email composition.
///
/// This view provides a native mail composition interface using the system's
/// mail composer. It handles configuration and delegation automatically.
///
/// Example usage:
/// ```swift
/// MailComposerView(store: store)
/// ```
public struct MailComposerView: UIViewControllerRepresentable {
    /// The store managing the mail composer's state and actions
    let store: StoreOf<MailComposerFeature>

    /// Creates and configures the mail compose view controller.
    ///
    /// - Parameter context: The context in which the view controller is created
    /// - Returns: A configured MFMailComposeViewController instance
    public func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let viewStore = ViewStore(store, observe: { $0 })
        let vc = MFMailComposeViewController()
        configureMailComposer(vc, with: viewStore)
        vc.mailComposeDelegate = context.coordinator
        return vc
    }

    /// Required by UIViewControllerRepresentable but not used.
    public func updateUIViewController(_: MFMailComposeViewController, context _: Context) {}

    /// Creates a coordinator to handle mail composer delegate callbacks.
    public func makeCoordinator() -> Coordinator {
        Coordinator(store: store)
    }

    /// Configures the mail composer with the current state.
    ///
    /// - Parameters:
    ///   - vc: The mail compose view controller to configure
    ///   - viewStore: The view store containing the current state
    private func configureMailComposer(
        _ vc: MFMailComposeViewController,
        with viewStore: ViewStore<MailComposerFeature.State, MailComposerFeature.Action>
    ) {
        vc.setToRecipients([viewStore.recipient])
        vc.setSubject(viewStore.subject)
        vc.setMessageBody(viewStore.body, isHTML: false)
    }
}

extension MailComposerView {
    /// Coordinator class that handles mail composer delegate callbacks.
    ///
    /// This class receives notifications about the mail composition process
    /// and dispatches appropriate actions to the store.
    public class Coordinator: NSObject, @preconcurrency MFMailComposeViewControllerDelegate {
        /// The store managing the mail composer's state and actions
        let store: StoreOf<MailComposerFeature>

        /// Creates a new coordinator with the specified store.
        ///
        /// - Parameter store: The store to dispatch actions to
        public init(store: StoreOf<MailComposerFeature>) {
            self.store = store
        }

        /// Handles the completion of mail composition.
        ///
        /// - Parameters:
        ///   - controller: The mail compose view controller
        ///   - result: The result of the composition
        ///   - error: Any error that occurred during composition
        @MainActor public func mailComposeController(
            _: MFMailComposeViewController,
            didFinishWith _: MFMailComposeResult,
            error _: Error?
        ) {
            store.send(.dismiss)
        }
    }
}

/// Errors that can occur during mail composition.
public enum MailComposerError: LocalizedError, Equatable {
    /// Indicates that mail composition failed
    case failedToCompose

    public var errorDescription: String? {
        switch self {
        case .failedToCompose:
            String(localizable: .mailFailedToCompose)
        }
    }

    public var failureReason: String? {
        switch self {
        case .failedToCompose:
            String(localizable: .mailFailedToComposeReason)
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .failedToCompose:
            String(localizable: .mailFailedToComposeRecovery)
        }
    }
}
