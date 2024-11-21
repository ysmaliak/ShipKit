import ComposableArchitecture
import MessageUI
import SwiftUI

@Reducer
struct MailComposerFeature {
    struct State: Equatable {
        let recipient: String
        let subject: String
        let body: String
    }

    enum Action {
        case dismiss
    }

    @Dependency(\.dismiss) var dismiss

    var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
            case .dismiss:
                .run { _ in await dismiss() }
            }
        }
    }
}

struct MailComposerView: UIViewControllerRepresentable {
    let store: StoreOf<MailComposerFeature>

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let viewStore = ViewStore(store, observe: { $0 })
        let vc = MFMailComposeViewController()
        configureMailComposer(vc, with: viewStore)
        vc.mailComposeDelegate = context.coordinator
        return vc
    }

    func updateUIViewController(_: MFMailComposeViewController, context _: Context) {}

    func makeCoordinator() -> Coordinator {
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
    class Coordinator: NSObject, @preconcurrency MFMailComposeViewControllerDelegate {
        let store: StoreOf<MailComposerFeature>

        init(store: StoreOf<MailComposerFeature>) {
            self.store = store
        }

        @MainActor func mailComposeController(_: MFMailComposeViewController, didFinishWith _: MFMailComposeResult, error _: Error?) {
            store.send(.dismiss)
        }
    }
}

enum MailComposerError: LocalizedError, Equatable {
    case failedToCompose

    var errorDescription: String? {
        switch self {
        case .failedToCompose:
            String(localizable: .mailFailedToCompose)
        }
    }

    var failureReason: String? {
        switch self {
        case .failedToCompose:
            String(localizable: .mailFailedToComposeReason)
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .failedToCompose:
            String(localizable: .mailFailedToComposeRecovery)
        }
    }
}
