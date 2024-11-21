import ComposableArchitecture
import SwiftUI

extension AlertState {
    static func error(_ error: Error) -> AlertState<Action> {
        AlertState(
            title: { TextState(.localizable(.error)) },
            message: { TextState(error.localizedDescription) }
        )
    }

    static func error(message: String) -> AlertState<Action> {
        AlertState(
            title: { TextState(.localizable(.error)) },
            message: { TextState(message) }
        )
    }
}
