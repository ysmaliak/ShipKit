import UIKit

extension UIScreen {
    static var current: UIScreen? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?
            .screen
    }

    static var size: CGSize {
        guard let screen = current else {
            return .zero
        }

        if #available(iOS 16.0, *) {
            return screen.bounds.size
        } else {
            return screen.fixedCoordinateSpace.bounds.size
        }
    }

    static var width: CGFloat {
        size.width
    }

    static var height: CGFloat {
        size.height
    }
}
