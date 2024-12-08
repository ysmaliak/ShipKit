import Foundation
import SwiftUI

extension String {
    public static let emptyString: Self = ""
    public static let blankSpace: Self = " "
}

extension LocalizedStringKey: @unchecked @retroactive Sendable {
    public static let emptyString: Self = ""
    public static let blankSpace: Self = " "
}
