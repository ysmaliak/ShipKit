import ComposableArchitecture
import Inject
import RevenueCat
import RevenueCatUtilities
import SwiftUI

@Reducer
public struct PaywallFeature: Sendable {
    @Reducer
    public enum Destination {
        case alert(AlertState<PaywallFeature.Action.Alert>)
    }

    @ObservableState
    public struct State {
        public var isPremiumUser: Bool
        public let premiumEntitlement: String
        public let privacyPolicyURL: URL
        public let termsOfServiceURL: URL
        public var showSavePercentBadge = true
        public var currentOffering: Offering?
        public var selectedPackage: Package?
        public var isLoadingOffering = false
        public var isSubscribeButtonLoading = false
        public var isRestoreButtonLoading = false

        public var isPackagesEmpty: Bool {
            currentOffering?.availablePackages.isEmpty == true || currentOffering == nil
        }

        @Presents public var destination: Destination.State?
    }

    public enum Action {
        public enum Alert {}

        public enum Delegate {
            case purchaseCompleted
            case premiumUserStatusChanged(Bool)
        }

        case onAppear
        case packageSelected(Package)
        case subscribeButtonTapped
        case restoreButtonTapped
        case offeringLoaded(Result<Offering?, Error>)
        case purchaseCompleted(Result<CustomerInfo, Error>)
        case restoreCompleted(Result<CustomerInfo, Error>)
        case destination(PresentationAction<Destination.Action>)
        case delegate(Delegate)
    }

    @Dependency(\.purchases) private var purchases

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoadingOffering = true
                return loadOffering()

            case .packageSelected(let package):
                state.selectedPackage = package
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
                var premiumUserStatusChangedEffect: Effect<Action> = .none
                if customerInfo.entitlements[state.premiumEntitlement]?.isActive == true {
                    state.isPremiumUser = true
                    premiumUserStatusChangedEffect = .send(.delegate(.premiumUserStatusChanged(true)))
                } else {
                    state.isPremiumUser = false
                    premiumUserStatusChangedEffect = .send(.delegate(.premiumUserStatusChanged(false)))
                    state.destination = .alert(.error(PurchaseError.noActiveEntitlement))
                }
                return .concatenate(premiumUserStatusChangedEffect, .send(.delegate(.purchaseCompleted)))

            case .restoreCompleted(.success(let customerInfo)):
                state.isSubscribeButtonLoading = false
                state.isRestoreButtonLoading = false
                var premiumUserStatusChangedEffect: Effect<Action> = .none
                if customerInfo.entitlements[state.premiumEntitlement]?.isActive == true {
                    state.isPremiumUser = true
                    premiumUserStatusChangedEffect = .send(.delegate(.premiumUserStatusChanged(true)))
                } else {
                    state.isPremiumUser = false
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

    private func loadOffering() -> Effect<Action> {
        .run { send in
            await send(.offeringLoaded(Result {
                try await purchases.offerings().current
            }))
        }
    }

    private func purchase(package: Package) -> Effect<Action> {
        .run { send in
            await send(.purchaseCompleted(Result {
                let resultData = try await purchases.purchase(package: package)
                return resultData.customerInfo
            }))
        }
    }

    private func restore() -> Effect<Action> {
        .run { send in
            await send(.restoreCompleted(Result {
                try await purchases.restorePurchases()
            }))
        }
    }
}

public struct PaywallView<Content: View>: View {
    @Bindable public var store: StoreOf<PaywallFeature>
    public var content: (() -> Content)?

    @ObserveInjection private var inject

    public var body: some View {
        _content
            .toolbar { toolbar }
            .onAppear { store.send(.onAppear) }
            .alert($store.scope(state: \.destination?.alert, action: \.destination.alert))
            .enableInjection()
    }

    @ViewBuilder
    private var _content: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    if store.isLoadingOffering {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .primary))
                            .controlSize(.regular)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if store.isPackagesEmpty {
                        Text(.localizable(.subscriptionPackagesLoadingError))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.top, 16)
                            .padding(.bottom, 64)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        VStack {
                            if let content {
                                content()
                            }

                            packagesView
                        }
                    }

                    subscribeButton
                        .padding(.top, 16)

                    if let package = store.selectedPackage, let intro = package.storeProduct.introductoryDiscount, intro.price == 0 {
                        Text(.localizable(.noPaymentDueNow))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.top, 6)
                    }

                    LinksView(privacyPolicyURL: store.privacyPolicyURL, termsOfServiceURL: store.termsOfServiceURL)
                        .padding(.top, 20)
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
                    .progressViewStyle(CircularProgressViewStyle(tint: .primary))
            } else {
                Button(.localizable(.restore)) {
                    store.send(.restoreButtonTapped)
                }
                .foregroundStyle(Color.primary)
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
            let mostExpensivePrice = packages
                .map(\.pricePerDay)
                .max() ?? 0

            VStack(spacing: 10) {
                ForEach(packages) { package in
                    let currentPrice = package.pricePerDay
                    let discount = mostExpensivePrice > 0
                        ? ((mostExpensivePrice - currentPrice) / mostExpensivePrice) * 100
                        : 0

                    PackageOptionView(
                        package: package,
                        isSelected: store.selectedPackage == package,
                        discountPercentage: store.showSavePercentBadge ? (discount > 0 ? discount : nil) : nil
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

                    if let description = package.localizedPriceDescription {
                        Text(description)
                            .font(.caption)
                            .fontWeight(.regular)
                            .foregroundStyle(Color.primary.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                }
                .opacity(store.isSubscribeButtonLoading ? 0 : 1)
                .overlay {
                    if store.isSubscribeButtonLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .primary))
                    }
                }
            }
            .buttonStyle(.capsule)
            .opacity(store.isLoadingOffering || store.isPackagesEmpty || store.isRestoreButtonLoading ? 0.8 : 1.0)
            .disabled(store.isSubscribeButtonLoading || store.isLoadingOffering || store.isPackagesEmpty || store.isRestoreButtonLoading)
        }
    }
}
