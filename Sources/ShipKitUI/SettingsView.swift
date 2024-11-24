import ComposableArchitecture
import Inject
import MessageUI
import RevenueCat
import RevenueCatUtilities
import SFSafeSymbols
import ShipKitCore
import StoreKit
import SwiftUI

/// Configuration for the email feedback feature.
///
/// This struct encapsulates all the necessary information for pre-filling
/// a feedback email when users select the feedback option in settings.
///
/// Example usage:
/// ```swift
/// let config = EmailConfiguration(
///     recipient: "support@example.com",
///     subject: "App Feedback",
///     body: "Please describe your feedback:"
/// )
/// ```
public struct EmailConfiguration: Equatable {
    /// The email address that will receive the feedback.
    ///
    /// This should typically be a support or feedback email address
    /// that is actively monitored.
    public var recipient: String

    /// The pre-filled subject line of the feedback email.
    ///
    /// Consider including the app name or specific feedback category
    /// to help with email organization.
    public var subject: String

    /// The pre-filled body content of the feedback email.
    ///
    /// This can include:
    /// - Instructions for the user
    /// - Template for feedback structure
    /// - Placeholder text
    /// - App version information
    public var body: String

    /// Creates a new email configuration.
    ///
    /// - Parameters:
    ///   - recipient: The email address to receive feedback
    ///   - subject: The pre-filled subject line
    ///   - body: The pre-filled email body content
    public init(
        recipient: String,
        subject: String,
        body: String
    ) {
        self.recipient = recipient
        self.subject = subject
        self.body = body
    }
}

/// Represents different sections in the settings view.
///
/// Used to organize settings items into logical groups.
public enum SettingsSection: String, CaseIterable {
    case appearance
    case feedback
    case purchase
    case legal
}

/// Represents a single item in the settings menu.
///
/// Each item has a type, section, and indicator state that determines
/// its appearance and behavior in the settings list.
public struct SettingsItem: Identifiable, Equatable, Hashable {
    /// Defines the different types of settings items available.
    public enum ItemType: Identifiable, Hashable {
        case sendFeedback
        case rateAndReview
        case restorePurchase
        case privacyPolicy
        case termsOfService

        public var id: Self { self }
    }

    /// Defines the different types of indicators that can appear
    /// next to a settings item.
    public enum Indicator: Equatable, Hashable {
        /// Shows a symbol (e.g., arrow, checkmark)
        case symbol(SFSymbol)
        /// Shows no indicator
        case none
        /// Shows a progress indicator
        case progress
    }

    public var id: ItemType { type.id }
    public let type: ItemType
    public let section: SettingsSection
    public var indicator: Indicator

    /// Creates a new settings item.
    /// - Parameters:
    ///   - type: The type of settings item
    ///   - section: The section this item belongs to
    ///   - indicator: The indicator to show next to the item
    public init(type: ItemType, section: SettingsSection, indicator: Indicator) {
        self.type = type
        self.section = section
        self.indicator = indicator
    }

    /// The localized title for the settings item.
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

    /// The SF Symbol to display for the settings item.
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

/// A reducer that manages settings functionality.
///
/// Handles user interactions with settings items, including:
/// - Sending feedback
/// - Rating the app
/// - Restoring purchases
/// - Viewing legal documents
@Reducer
public struct SettingsFeature: Sendable {
    /// Possible destinations (sheets/alerts) in the settings view.
    @Reducer
    public enum Destination {
        case alert(AlertState<SettingsFeature.Action.Alert>)
        case mailComposer(MailComposerFeature)
    }

    /// The state for the settings feature.
    @ObservableState
    public struct State {
        /// Array of all settings items
        public var settingsItems: IdentifiedArrayOf<SettingsItem> = [
            SettingsItem(type: .sendFeedback, section: .feedback, indicator: .none),
            SettingsItem(type: .rateAndReview, section: .feedback, indicator: .none),
            SettingsItem(type: .restorePurchase, section: .purchase, indicator: .none),
            SettingsItem(type: .privacyPolicy, section: .legal, indicator: .symbol(.arrowUpRight)),
            SettingsItem(type: .termsOfService, section: .legal, indicator: .symbol(.arrowUpRight))
        ]

        /// Whether the user has premium access
        public var isPremiumUser = false

        /// The identifier for the premium entitlement
        public let premiumEntitlement: String

        /// Configuration for the feedback email
        public let emailConfiguration: EmailConfiguration

        /// The App Store ID for ratings
        public let appID: String

        /// URL to the privacy policy
        public let privacyPolicyURL: URL

        /// URL to the terms of service
        public let termsOfServiceURL: URL

        /// The current destination being presented
        @Presents public var destination: Destination.State?

        /// Settings items grouped by section, filtered based on user status.
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

        public enum Delegate {
            case premiumUserStatusChanged(Bool)
        }

        case itemSelected(id: SettingsItem.ID)
        case mailComposerCheckCompleted(Bool)
        case purchaseRestored(Result<CustomerInfo, Error>)
        case destination(PresentationAction<Destination.Action>)
        case delegate(Delegate)
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
                var premiumUserStatusChangedEffect: Effect<Action> = .none
                if customerInfo.entitlements[state.premiumEntitlement]?.isActive == true {
                    state.isPremiumUser = true
                    premiumUserStatusChangedEffect = .send(.delegate(.premiumUserStatusChanged(true)))
                    state.destination = .alert(AlertState(
                        title: { TextState(.localizable(.success)) },
                        message: { TextState(.localizable(.purchasesRestored)) }
                    ))
                } else {
                    state.isPremiumUser = false
                    premiumUserStatusChangedEffect = .send(.delegate(.premiumUserStatusChanged(false)))
                    state.destination = .alert(.error(PurchaseError.failedToRestore))
                }
                return premiumUserStatusChangedEffect

            case .purchaseRestored(.failure(let error)):
                if let index = state.settingsItems.firstIndex(where: { $0.type == .restorePurchase }) {
                    state.settingsItems[index].indicator = .none
                }
                state.destination = .alert(.error(error))
                return .none

            case .destination, .delegate:
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

/// A view that displays the settings interface.
///
/// Presents a list of settings items organized by section, with support for:
/// - Item icons and indicators
/// - Section grouping
/// - Interactive feedback
/// - Sheet presentations
public struct SettingsView: View {
    /// The store managing the settings state and actions
    @Bindable public var store: StoreOf<SettingsFeature>

    /// Property wrapper for hot reload support
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
    /// The settings item to display
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
