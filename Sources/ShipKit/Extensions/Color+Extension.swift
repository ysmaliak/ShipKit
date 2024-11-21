import SwiftUI

#if canImport(AppKit)
    import AppKit
#endif

#if canImport(UIKit)
    import UIKit
#endif

extension Color {
    public init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        (a, r, g, b) = switch hex.count {
        case 3: (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

@available(macOS 12.0, *)
extension Color {
    public init(light: Color, dark: Color) {
        #if canImport(UIKit)
            self.init(light: UIColor(light), dark: UIColor(dark))
        #else
            self.init(light: NSColor(light), dark: NSColor(dark))
        #endif
    }

    #if canImport(UIKit)
        public init(light: UIColor, dark: UIColor) {
            #if os(watchOS)
                self.init(uiColor: dark)
            #else
                self.init(uiColor: UIColor(dynamicProvider: { traits in
                    switch traits.userInterfaceStyle {
                    case .light, .unspecified: return light
                    case .dark: return dark
                    @unknown default:
                        assertionFailure("Unknown userInterfaceStyle: \(traits.userInterfaceStyle)")
                        return light
                    }
                }))
            #endif
        }
    #endif

    #if canImport(AppKit)
        public init(light: NSColor, dark: NSColor) {
            self.init(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
                switch appearance.name {
                case .aqua,
                     .vibrantLight,
                     .accessibilityHighContrastAqua,
                     .accessibilityHighContrastVibrantLight:
                    return light
                case .darkAqua,
                     .vibrantDark,
                     .accessibilityHighContrastDarkAqua,
                     .accessibilityHighContrastVibrantDark:
                    return dark
                default:
                    assertionFailure("Unknown appearance: \(appearance.name)")
                    return light
                }
            }))
        }
    #endif
}

extension UIColor {
    public convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        (a, r, g, b) = switch hex.count {
        case 3: (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (1, 1, 1, 0)
        }

        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
}
