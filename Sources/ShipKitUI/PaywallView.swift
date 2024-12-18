import ComposableArchitecture
import RevenueCat
import RevenueCatUtilities
import ShipKitCore
import SwiftUI

// Environment keys for paywall colors
private struct PaywallForegroundColorKey: EnvironmentKey {
    static let defaultValue: Color = .primary
}

private struct PaywallBackgroundColorKey: EnvironmentKey {
    static let defaultValue: Color = .clear
}

extension EnvironmentValues {
    var paywallForegroundColor: Color {
        get { self[PaywallForegroundColorKey.self] }
        set { self[PaywallForegroundColorKey.self] = newValue }
    }

    var paywallBackgroundColor: Color {
        get { self[PaywallBackgroundColorKey.self] }
        set { self[PaywallBackgroundColorKey.self] = newValue }
    }
}

extension PaywallView {
    /// Sets the foreground color for the paywall content
    /// - Parameter color: The color to use for text and icons
    /// - Returns: A view with the modified foreground color
    public func paywallForegroundColor(_ color: Color) -> PaywallView<Content> {
        var view = self
        view._foregroundColor = color
        return view
    }

    /// Sets the background color for the paywall view
    /// - Parameter color: The color to use for the background
    /// - Returns: A view with the modified background color
    public func paywallBackgroundColor(_ color: Color) -> PaywallView<Content> {
        var view = self
        view._backgroundColor = color
        return view
    }
}

/// A feature that manages the paywall functionality for in-app purchases.
///
/// This reducer handles:
/// - Loading and displaying available subscription packages
/// - Processing purchases and restores
/// - Managing loading states and errors
/// - Handling user selection and purchase flow
///
/// Example usage:
/// ```swift
/// let store = Store(initialState: PaywallFeature.State(
///     premiumEntitlement: "premium",
///     privacyPolicyURL: privacyURL,
///     termsOfServiceURL: termsURL
/// )) {
///     PaywallFeature()
/// }
/// ```
@Reducer
public struct PaywallFeature: Sendable {
    /// Possible destinations (alerts) that can be presented in the paywall
    @Reducer
    public enum Destination {
        case alert(AlertState<PaywallFeature.Action.Alert>)
    }

    /// The state for the paywall feature
    @ObservableState
    public struct State {
        /// The identifier for the premium entitlement in RevenueCat
        public let premiumEntitlement: String?

        /// URL to the privacy policy
        public let privacyPolicyURL: URL?

        /// URL to the terms of service
        public let termsOfServiceURL: URL?

        /// Whether to show the save percentage badge on packages
        public var showSavePercentBadge = true

        /// The current RevenueCat offering being displayed
        public var currentOffering: Offering?

        /// The currently selected package
        public var selectedPackage: Package?

        /// Loading state for the offering
        public var isLoadingOffering = false

        /// Loading state for the subscribe button
        public var isSubscribeButtonLoading = false

        /// Loading state for the restore button
        public var isRestoreButtonLoading = false

        /// Whether there are any packages available to display
        public var isPackagesEmpty: Bool {
            currentOffering?.availablePackages.isEmpty == true || currentOffering == nil
        }

        /// The current destination (alert) being presented
        @Presents public var destination: Destination.State?

        /// Creates a new paywall state with the specified values.
        ///
        /// - Parameters:
        ///   - premiumEntitlement: The identifier for the premium entitlement in RevenueCat
        ///   - privacyPolicyURL: URL to the privacy policy
        ///   - termsOfServiceURL: URL to the terms of service
        ///   - showSavePercentBadge: Whether to show the save percentage badge on packages
        ///   - currentOffering: The current RevenueCat offering being displayed
        ///   - selectedPackage: The currently selected package
        ///   - isLoadingOffering: Whether the offering is currently loading
        ///   - isSubscribeButtonLoading: Whether the subscribe button is currently loading
        ///   - isRestoreButtonLoading: Whether the restore button is currently loading
        ///   - destination: The current destination (alert) being presented
        public init(
            premiumEntitlement: String? = ShipKitUIManager.configuration.premiumEntitlement,
            privacyPolicyURL: URL? = ShipKitUIManager.configuration.privacyPolicyURL,
            termsOfServiceURL: URL? = ShipKitUIManager.configuration.termsOfServiceURL,
            showSavePercentBadge: Bool = true,
            currentOffering: Offering? = nil,
            selectedPackage: Package? = nil,
            isLoadingOffering: Bool = false,
            isSubscribeButtonLoading: Bool = false,
            isRestoreButtonLoading: Bool = false,
            destination: Destination.State? = nil
        ) {
            self.premiumEntitlement = premiumEntitlement
            self.privacyPolicyURL = privacyPolicyURL
            self.termsOfServiceURL = termsOfServiceURL
            self.showSavePercentBadge = showSavePercentBadge
            self.currentOffering = currentOffering
            self.selectedPackage = selectedPackage
            self.isLoadingOffering = isLoadingOffering
            self.isSubscribeButtonLoading = isSubscribeButtonLoading
            self.isRestoreButtonLoading = isRestoreButtonLoading
            self.destination = destination
        }
    }

    /// Actions that can be performed in the paywall
    public enum Action {
        /// Alert-related actions
        public enum Alert {}

        /// Delegate actions for communicating with parent features
        public enum Delegate {
            /// Notifies that a purchase was completed
            case purchaseCompleted
            /// Notifies of changes to premium user status
            case premiumUserStatusChanged(Bool)
        }

        /// View appeared
        case onAppear
        /// Package was selected by user
        case packageSelected(Package)
        /// Subscribe button was tapped
        case subscribeButtonTapped
        /// Restore button was tapped
        case restoreButtonTapped
        /// Offering was loaded from RevenueCat
        case offeringLoaded(Result<Offering?, Error>)
        /// Purchase was completed
        case purchaseCompleted(Result<CustomerInfo, Error>)
        /// Restore was completed
        case restoreCompleted(Result<CustomerInfo, Error>)
        /// Destination (alert) action
        case destination(PresentationAction<Destination.Action>)
        /// Delegate action
        case delegate(Delegate)
    }

    /// Creates a new paywall reducer.
    public init() {}

    @Dependency(\.purchases) private var purchases

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoadingOffering = true
                return loadOffering()

            case .packageSelected(let package):
                withAnimation(.smooth) {
                    state.selectedPackage = package
                }
                return .none

            case .subscribeButtonTapped:
                guard let package = state.selectedPackage else { return .none }
                state.isSubscribeButtonLoading = true
                return purchase(package: package)

            case .restoreButtonTapped:
                state.isRestoreButtonLoading = true
                return restore()

            case .offeringLoaded(.success(let offering)):
                state.isLoadingOffering = false
                state.currentOffering = offering
                if let package = offering?.availablePackages.first {
                    state.selectedPackage = package
                }
                return .none

            case .offeringLoaded(.failure(let error)):
                state.isLoadingOffering = false
                state.destination = .alert(.error(error))
                return .none

            case .purchaseCompleted(.success(let customerInfo)):
                state.isSubscribeButtonLoading = false
                state.isRestoreButtonLoading = false

                guard let premiumEntitlement = state.premiumEntitlement else { return .none }

                var premiumUserStatusChangedEffect: Effect<Action> = .none
                if customerInfo.entitlements[premiumEntitlement]?.isActive == true {
                    premiumUserStatusChangedEffect = .send(.delegate(.premiumUserStatusChanged(true)))
                } else {
                    premiumUserStatusChangedEffect = .send(.delegate(.premiumUserStatusChanged(false)))
                    state.destination = .alert(.error(PurchaseError.noActiveEntitlement))
                }
                return .concatenate(premiumUserStatusChangedEffect, .send(.delegate(.purchaseCompleted)))

            case .restoreCompleted(.success(let customerInfo)):
                state.isSubscribeButtonLoading = false
                state.isRestoreButtonLoading = false

                guard let premiumEntitlement = state.premiumEntitlement else { return .none }

                var premiumUserStatusChangedEffect: Effect<Action> = .none
                if customerInfo.entitlements[premiumEntitlement]?.isActive == true {
                    premiumUserStatusChangedEffect = .send(.delegate(.premiumUserStatusChanged(true)))
                } else {
                    premiumUserStatusChangedEffect = .send(.delegate(.premiumUserStatusChanged(false)))
                    state.destination = .alert(.error(PurchaseError.noActiveEntitlement))
                }
                return .concatenate(premiumUserStatusChangedEffect, .send(.delegate(.purchaseCompleted)))

            case .purchaseCompleted(.failure(let error)), .restoreCompleted(.failure(let error)):
                state.isSubscribeButtonLoading = false
                state.isRestoreButtonLoading = false
                state.destination = .alert(.error(error))
                return .none

            case .destination, .delegate:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }

    /// Loads the current offering from RevenueCat.
    /// - Returns: An effect that loads and dispatches the offering result
    private func loadOffering() -> Effect<Action> {
        .run { send in
            await send(.offeringLoaded(Result {
                try await purchases.offerings().current
            }))
        }
    }

    /// Processes a purchase for the specified package.
    /// - Parameter package: The package to purchase
    /// - Returns: An effect that processes and dispatches the purchase result
    private func purchase(package: Package) -> Effect<Action> {
        .run { send in
            await send(.purchaseCompleted(Result {
                let resultData = try await purchases.purchase(package: package)
                return resultData.customerInfo
            }))
        }
    }

    /// Restores previous purchases from RevenueCat.
    /// - Returns: An effect that restores and dispatches the result
    private func restore() -> Effect<Action> {
        .run { send in
            await send(.restoreCompleted(Result {
                try await purchases.restorePurchases()
            }))
        }
    }
}

/// A view that displays the paywall interface for in-app purchases.
///
/// This view presents:
/// - Custom content (header/description)
/// - Available subscription packages
/// - Subscribe button
/// - Restore purchases button
/// - Terms and privacy policy links
///
/// Example usage:
/// ```swift
/// PaywallView(store: store, subscribeButtonStyle: .capsule) {
///     PaywallHeaderView()
/// }
/// ```
public struct PaywallView<Content: View>: View {
    /// The store managing the paywall's state and actions
    @Bindable public var store: StoreOf<PaywallFeature>

    /// The content to display above the packages
    public let content: () -> Content

    private var _foregroundColor: Color = PaywallForegroundColorKey.defaultValue
    private var _backgroundColor: Color = PaywallBackgroundColorKey.defaultValue

    /// Creates a new paywall view
    /// - Parameters:
    ///   - store: The store managing the paywall's state and actions
    ///   - content: The content to display above the packages
    public init(
        store: StoreOf<PaywallFeature>,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.store = store
        self.content = content
    }

    public var body: some View {
        _content
            .toolbar { toolbar }
            .alert($store.scope(state: \.destination?.alert, action: \.destination.alert))
            .onAppear { store.send(.onAppear) }
    }

    @ViewBuilder
    private var _content: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    if store.isLoadingOffering {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: _foregroundColor))
                            .controlSize(.regular)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if store.isPackagesEmpty {
                        Text(.localizable(.subscriptionPackagesLoadingError))
                            .font(.subheadline)
                            .foregroundStyle(_foregroundColor.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.top, 16)
                            .padding(.bottom, 64)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        VStack {
                            content()

                            Spacer()

                            packagesView
                        }
                    }

                    subscribeButton
                        .padding(.top, 16)

                    Text(.localizable(.noPaymentDueNow))
                        .font(.footnote)
                        .foregroundStyle(_foregroundColor.opacity(0.7))
                        .padding(.top, 6)
                        .opacity(store.selectedPackage?.storeProduct.introductoryDiscount?.price == 0 ? 1 : 0)
                        .animation(.easeInOut, value: store.selectedPackage?.storeProduct.introductoryDiscount?.price)

                    if let privacyPolicyURL = store.privacyPolicyURL, let termsOfServiceURL = store.termsOfServiceURL {
                        LinksView(privacyPolicyURL: privacyPolicyURL, termsOfServiceURL: termsOfServiceURL)
                            .padding(.top, 20)
                    }
                }
                .padding(.top, 8)
                .padding(.horizontal)
                .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? 0 : 16)
                .frame(minHeight: geometry.size.height)
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)
        }
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            if store.isRestoreButtonLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: _foregroundColor))
            } else {
                Button(.localizable(.restore)) {
                    store.send(.restoreButtonTapped)
                }
                .foregroundStyle(_foregroundColor)
                .disabled(
                    store.isSubscribeButtonLoading
                        || store.isLoadingOffering
                        || store.isPackagesEmpty
                        || store.isRestoreButtonLoading
                )
            }
        }
    }

    @ViewBuilder
    private var packagesView: some View {
        if let offering = store.currentOffering {
            let packages = offering.availablePackages
            let mostExpensivePrice: Double = packages.compactMap(\.pricePerDay).max() ?? 0.0

            VStack(spacing: 10) {
                ForEach(packages) { package in
                    let currentPrice = package.pricePerDay ?? 0.0
                    let discount = mostExpensivePrice > 0.0
                        ? ((mostExpensivePrice - currentPrice) / mostExpensivePrice) * 100.0
                        : 0.0

                    PackageOptionView(
                        package: package,
                        isSelected: store.selectedPackage == package,
                        discountPercentage: store.showSavePercentBadge && package.packageType != .lifetime
                            ? (discount > 0.0 ? discount : nil)
                            : nil,
                        foregroundColor: _foregroundColor,
                        backgroundColor: _backgroundColor
                    )
                    .onTapGesture {
                        store.send(.packageSelected(package))
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var subscribeButton: some View {
        if let package = store.selectedPackage {
            Button(action: { store.send(.subscribeButtonTapped) }) {
                VStack(spacing: 2) {
                    Text(package.localizedActionTitle)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(_backgroundColor)

                    if let description = package.localizedPriceDescription {
                        Text(description)
                            .font(.caption)
                            .fontWeight(.regular)
                            .foregroundStyle(_backgroundColor.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                }
                .opacity(store.isSubscribeButtonLoading ? 0 : 1)
                .overlay {
                    if store.isSubscribeButtonLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: _backgroundColor))
                    }
                }
            }
            .buttonStyle(.capsule(ButtonConfiguration(background: _foregroundColor, foreground: _backgroundColor)))
            .opacity(store.isLoadingOffering || store.isPackagesEmpty || store.isRestoreButtonLoading ? 0.8 : 1.0)
            .disabled(store.isSubscribeButtonLoading || store.isLoadingOffering || store.isPackagesEmpty || store.isRestoreButtonLoading)
        }
    }
}
