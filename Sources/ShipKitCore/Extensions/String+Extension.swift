import Foundation
import SwiftUI

extension String {
    public static let emptyString: Self = ""
}

extension LocalizedStringKey: @unchecked @retroactive Sendable {
    public static let emptyString: Self = ""
}
