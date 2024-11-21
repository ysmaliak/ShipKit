import ComposableArchitecture

extension Sequence where Element: Identifiable {
    public var identified: IdentifiedArrayOf<Element> {
        IdentifiedArray(uniqueElements: self)
    }
}
