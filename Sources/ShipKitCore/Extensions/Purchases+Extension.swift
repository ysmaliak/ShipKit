import ComposableArchitecture
import RevenueCat

extension Purchases: @retroactive DependencyKey {
    public static let liveValue: Purchases = .shared
}

extension DependencyValues {
    public var purchases: Purchases {
        get { self[Purchases.self] }
        set { self[Purchases.self] = newValue }
    }
}
