import ComposableArchitecture
import MessageUI
import SwiftUI

@Reducer
public struct MailComposerFeature {
    public struct State: Equatable {
        public let recipient: String
        public let subject: String
        public let body: String
    }

    public enum Action {
        case dismiss
    }

    @Dependency(\.dismiss) private var dismiss

    public var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
            case .dismiss:
                .run { _ in await dismiss() }
            }
        }
    }
}

public struct MailComposerView: UIViewControllerRepresentable {
    let store: StoreOf<MailComposerFeature>

    public func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let viewStore = ViewStore(store, observe: { $0 })
        let vc = MFMailComposeViewController()
        configureMailComposer(vc, with: viewStore)
        vc.mailComposeDelegate = context.coordinator
        return vc
    }

    public func updateUIViewController(_: MFMailComposeViewController, context _: Context) {}

    public func makeCoordinator() -> Coordinator {
        Coordinator(store: store)
    }

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
    public class Coordinator: NSObject, @preconcurrency MFMailComposeViewControllerDelegate {
        let store: StoreOf<MailComposerFeature>

        public init(store: StoreOf<MailComposerFeature>) {
            self.store = store
        }

        @MainActor public func mailComposeController(
            _: MFMailComposeViewController,
            didFinishWith _: MFMailComposeResult,
            error _: Error?
        ) {
            store.send(.dismiss)
        }
    }
}

public enum MailComposerError: LocalizedError, Equatable {
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
