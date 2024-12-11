//
//  CapsuleButtonStyle.swift
//  MyQuote
//
//  Created by Yan Smaliak on 11/10/2024.
//

import SwiftUI

/// Configuration options for customizing button appearance.
///
/// This struct provides a centralized way to configure the visual aspects of a button,
/// including font, colors, and interaction feedback.
///
/// Example usage:
/// ```swift
/// let config = ButtonConfiguration(
///     font: .headline,
///     background: .blue,
///     foreground: .white,
///     pressedOpacity: 0.7
/// )
///
/// Button("Tap me") { }
///     .buttonStyle(.capsule(config))
/// ```
public struct ButtonConfiguration {
    /// The font used for the button's text.
    public let font: Font

    /// The background color of the button.
    public let background: Color

    /// The foreground (text) color of the button.
    public let foreground: Color

    /// The opacity applied to the button when pressed (0.0 - 1.0).
    public let pressedOpacity: Double

    /// Creates a new button configuration.
    ///
    /// - Parameters:
    ///   - font: The font for the button text. Defaults to semibold title3.
    ///   - background: The background color of the button.
    ///   - foreground: The color of the button text and any icons.
    ///   - pressedOpacity: The opacity when the button is pressed. Defaults to 0.8.
    public init(
        font: Font = .title3.weight(.semibold),
        background: Color,
        foreground: Color,
        pressedOpacity: Double = 0.8
    ) {
        self.font = font
        self.background = background
        self.foreground = foreground
        self.pressedOpacity = pressedOpacity
    }
}

/// A button style that creates a capsule-shaped button with press animation.
///
/// This style creates a button with rounded ends and supports:
/// - Custom fonts and colors
/// - Press animation with configurable opacity
/// - Centered multiline text
/// - Full width layout
///
/// Example usage:
/// ```swift
/// Button("Press Me") { }
///     .buttonStyle(.capsule(.init(
///         background: .blue,
///         foreground: .white
///     )))
/// ```
struct CapsuleButtonStyle: ButtonStyle {
    /// The configuration for the button's appearance.
    public let buttonConfiguration: ButtonConfiguration

    /// Creates a new capsule button style with the specified configuration.
    ///
    /// - Parameter buttonConfiguration: The configuration for the button's appearance.
    public init(buttonConfiguration: ButtonConfiguration) {
        self.buttonConfiguration = buttonConfiguration
    }

    /// Tracks the pressed state of the button for animation.
    @State private var isPressed = false

    /// Creates the styled button view.
    ///
    /// - Parameter configuration: The button's configuration provided by SwiftUI.
    /// - Returns: A styled view containing the button's label.
    func makeBody(configuration: ButtonStyle.Configuration) -> some View {
        configuration.label
            .font(buttonConfiguration.font)
            .multilineTextAlignment(.center)
            .foregroundStyle(buttonConfiguration.foreground)
            .frame(maxWidth: .infinity)
            .padding(.horizontal)
            .padding(.vertical, 20)
            .background(
                Capsule()
                    .fill(buttonConfiguration.background)
            )
            .opacity(isPressed ? buttonConfiguration.pressedOpacity : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isPressed)
            .onChange(of: configuration.isPressed) { _, newValue in
                isPressed = newValue
            }
    }
}

/// Convenience extension to use the capsule button style with the dot syntax.
extension ButtonStyle where Self == CapsuleButtonStyle {
    /// Creates a capsule button style with the specified configuration.
    ///
    /// - Parameter configuration: The configuration for the button's appearance.
    /// - Returns: A CapsuleButtonStyle instance.
    static func capsule(_ configuration: ButtonConfiguration) -> CapsuleButtonStyle {
        CapsuleButtonStyle(buttonConfiguration: configuration)
    }
}
