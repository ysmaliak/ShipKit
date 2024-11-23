//
//  CapsuleButtonStyle.swift
//  MyQuote
//
//  Created by Yan Smaliak on 11/10/2024.
//

import SwiftUI

public struct ButtonConfiguration {
    public let font: Font
    public let background: Color
    public let foreground: Color
    public let pressedOpacity: Double
    
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

struct CapsuleButtonStyle: ButtonStyle {
    public let buttonConfiguration: ButtonConfiguration
    @State private var isPressed = false

    func makeBody(configuration: Configuration) -> some View {
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

extension ButtonStyle where Self == CapsuleButtonStyle {
    static func capsule(_ configuration: ButtonConfiguration) -> CapsuleButtonStyle {
        CapsuleButtonStyle(buttonConfiguration: configuration)
    }
}
