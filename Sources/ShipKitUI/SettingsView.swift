import ComposableArchitecture
import Inject
import MessageUI
import RevenueCat
import RevenueCatUtilities
import SFSafeSymbols
import ShipKitCore
import StoreKit
import SwiftUI

public enum SettingsSection: String, CaseIterable {
    case appearance
    case feedback
    case purchase
    case legal
}

public struct SettingsItem: Identifiable, Equatable, Hashable {
    public enum ItemType: Identifiable, Hashable {
        case sendFeedback
        case rateAndReview
        case restorePurchase
        case privacyPolicy
        case termsOfService

        public var id: Self { self }
    }

    public enum Indicator: Equatable, Hashable {
        case symbol(SFSymbol)
        case none
        case progress
    }

    public var id: ItemType { type.id }
    public let type: ItemType
    public let section: SettingsSection
    public var indicator: Indicator

    public init(type: ItemType, section: SettingsSection, indicator: Indicator) {
        self.type = type
        self.section = section
        self.indicator = indicator
    }

    var title: String {
        switch type {
        case .sendFeedback:
            String(localizable: .sendFeedbackSettingsOption)
        case .rateAndReview:
            String(localizable: .rateAndReviewSettingsOption)
        case .restorePurchase:
            String(localizable: .restorePurchaseSettingsOption)
        case .privacyPolicy:
            String(localizable: .privacyPolicy)
        case .termsOfService:
            String(localizable: .termsOfService)
        }
    }

    var symbol: SFSymbol {
        switch type {
        case .sendFeedback: .envelope
        case .rateAndReview: .star
        case .restorePurchase: .arrowClockwise
        case .privacyPolicy: .handRaised
        case .termsOfService: .docText
        }
    }
}

@Reducer
public struct SettingsFeature: Sendable {
    public struct EmailConfiguration: Equatable {
        public var recipient: String
        public var subject: String
        public var body: String
    }

    @Reducer
    public enum Destination {
        case alert(AlertState<SettingsFeature.Action.Alert>)
        case mailComposer(MailComposerFeature)
    }

    @ObservableState
    public struct State {
        public var settingsItems: IdentifiedArrayOf<SettingsItem> = [
            SettingsItem(type: .sendFeedback, section: .feedback, indicator: .none),
            SettingsItem(type: .rateAndReview, section: .feedback, indicator: .none),
            SettingsItem(type: .restorePurchase, section: .purchase, indicator: .none),
            SettingsItem(type: .privacyPolicy, section: .legal, indicator: .symbol(.arrowUpRight)),
            SettingsItem(type: .termsOfService, section: .legal, indicator: .symbol(.arrowUpRight))
        ]
        public var isPremiumUser = false
        public let emailConfiguration: EmailConfiguration
        public let appID: String
        public let premiumEntitlement: String
        public let privacyPolicyURL: URL
        public let termsOfServiceURL: URL
        @Presents public var destination: Destination.State?

        var groupedSettingsItems: [SettingsSection: [SettingsItem]] {
            let filteredItems = settingsItems.filter { item in
                if isPremiumUser, item.type == .restorePurchase {
                    return false
                }
                return true
            }
            return Dictionary(grouping: filteredItems, by: \.section)
        }
    }

    public enum Action {
        public enum Alert {}

        case itemSelected(id: SettingsItem.ID)
        case mailComposerCheckCompleted(Bool)
        case purchaseRestored(Result<CustomerInfo, Error>)
        case destination(PresentationAction<Destination.Action>)
    }

    @Dependency(\.openURL) private var openURL
    @Dependency(\.purchases) private var purchases

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .itemSelected(let id):
                guard let item = state.settingsItems[id: id] else { return .none }
                switch item.type {
                case .sendFeedback:
                    return checkMailComposer()

                case .rateAndReview:
                    return openReviewURL(appID: state.appID)

                case .restorePurchase:
                    state.settingsItems[id: id]?.indicator = .progress
                    return restorePurchase()

                case .privacyPolicy:
                    return .run { [privacyPolicyURL = state.privacyPolicyURL] _ in await openURL(privacyPolicyURL) }

                case .termsOfService:
                    return .run { [termsOfServiceURL = state.termsOfServiceURL] _ in await openURL(termsOfServiceURL) }
                }

            case .mailComposerCheckCompleted(let canSendMail):
                if canSendMail {
                    state.destination = .mailComposer(MailComposerFeature.State(
                        recipient: state.emailConfiguration.recipient,
                        subject: state.emailConfiguration.subject,
                        body: state.emailConfiguration.body
                    ))
                } else {
                    state.destination = .alert(.error(MailComposerError.failedToCompose))
                }
                return .none

            case .purchaseRestored(.success(let customerInfo)):
                if let index = state.settingsItems.firstIndex(where: { $0.type == .restorePurchase }) {
                    state.settingsItems[index].indicator = .none
                }
                if customerInfo.entitlements[state.premiumEntitlement]?.isActive == true {
                    state.isPremiumUser = true
                    state.destination = .alert(AlertState(
                        title: { TextState(.localizable(.success)) },
                        message: { TextState(.localizable(.purchasesRestored)) }
                    ))
                } else {
                    state.isPremiumUser = false
                    state.destination = .alert(.error(PurchaseError.failedToRestore))
                }
                return .none

            case .purchaseRestored(.failure(let error)):
                if let index = state.settingsItems.firstIndex(where: { $0.type == .restorePurchase }) {
                    state.settingsItems[index].indicator = .none
                }
                state.destination = .alert(.error(error))
                return .none

            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }

    private func checkMailComposer() -> Effect<Action> {
        .run { send in
            await send(.mailComposerCheckCompleted(MFMailComposeViewController.canSendMail()))
        }
    }

    private func restorePurchase() -> Effect<Action> {
        .run { send in
            await send(.purchaseRestored(Result {
                try await purchases.restorePurchases()
            }))
        }
    }

    private func openReviewURL(appID: String) -> Effect<Action> {
        .run { _ in
            await openURL(URL(string: "https://apps.apple.com/app/id\(appID)?action=write-review")!)
        }
    }
}

public struct SettingsView: View {
    @Bindable public var store: StoreOf<SettingsFeature>

    @ObserveInjection private var inject

    public var body: some View {
        listView
            .sheet(item: $store.scope(state: \.destination?.mailComposer, action: \.destination.mailComposer)) {
                MailComposerView(store: $0)
            }
            .alert($store.scope(state: \.destination?.alert, action: \.destination.alert))
            .enableInjection()
    }

    @ViewBuilder
    private var listView: some View {
        List {
            ForEach(SettingsSection.allCases, id: \.self) { section in
                if let items = store.groupedSettingsItems[section] {
                    Section {
                        ForEach(items) { item in
                            SettingsItemView(item: item)
                                .contentShape(.rect)
                                .disabled(item.type == .restorePurchase && item.indicator == .progress)
                                .onTapGesture {
                                    store.send(.itemSelected(id: item.id))
                                }
                        }
                    }
                }
            }
        }
    }
}

public struct SettingsItemView: View {
    public let item: SettingsItem

    public var body: some View {
        HStack {
            Image(systemSymbol: item.symbol)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 20, height: 20)
                .foregroundStyle(Color.primary)

            Text(item.title)
                .foregroundStyle(Color.primary)

            Spacer()

            switch item.indicator {
            case .symbol(let symbol):
                Image(systemSymbol: symbol)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(Color.secondary)
                    .frame(width: 12, height: 12)

            case .none:
                EmptyView()

            case .progress:
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .secondary))
            }
        }
    }
}
