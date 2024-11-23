//
//  CapsuleButtonStyle.swift
//  MyQuote
//
//  Created by Yan Smaliak on 11/10/2024.
//

import SwiftUI

struct CapsuleButtonStyle: ButtonStyle {
    @State private var isPressed = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title3)
            .fontWeight(.semibold)
            .multilineTextAlignment(.center)
            .foregroundStyle(.background)
            .frame(maxWidth: .infinity)
            .padding(.horizontal)
            .padding(.vertical, 20)
            .background(
                Capsule()
                    .fill(Color.primary)
            )
            .opacity(isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isPressed)
            .onChange(of: configuration.isPressed) { _, newValue in
                isPressed = newValue
            }
    }
}

extension ButtonStyle where Self == CapsuleButtonStyle {
    static var capsule: CapsuleButtonStyle {
        CapsuleButtonStyle()
    }
}

struct ReversedCapsuleButtonStyle: ButtonStyle {
    @State private var isPressed = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title3)
            .fontWeight(.semibold)
            .multilineTextAlignment(.center)
            .foregroundStyle(Color.primary)
            .frame(maxWidth: .infinity)
            .padding(.horizontal)
            .padding(.vertical, 20)
            .background(
                Capsule()
                    .fill(Color.primary)
                    .overlay(
                        Capsule()
                            .strokeBorder(Color.primary, lineWidth: 2)
                    )
            )
            .opacity(isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isPressed)
            .onChange(of: configuration.isPressed) { _, newValue in
                isPressed = newValue
            }
    }
}

extension ButtonStyle where Self == ReversedCapsuleButtonStyle {
    static var reversedCapsule: ReversedCapsuleButtonStyle {
        ReversedCapsuleButtonStyle()
    }
}
