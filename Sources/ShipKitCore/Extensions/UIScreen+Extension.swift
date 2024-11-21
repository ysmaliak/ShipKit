import UIKit

extension UIScreen {
    public static var current: UIScreen? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?
            .screen
    }

    public static var size: CGSize {
        guard let screen = current else {
            return .zero
        }

        if #available(iOS 16.0, *) {
            return screen.bounds.size
        } else {
            return screen.fixedCoordinateSpace.bounds.size
        }
    }

    public static var width: CGFloat {
        size.width
    }

    public static var height: CGFloat {
        size.height
    }
}
