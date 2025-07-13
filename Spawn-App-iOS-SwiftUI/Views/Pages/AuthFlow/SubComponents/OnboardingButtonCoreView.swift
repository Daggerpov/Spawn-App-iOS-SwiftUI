//
//  OnboardingButtonCoreView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Shane on 7/1/25.
//

import SwiftUI

struct OnboardingButtonCoreView: View {
    let buttonText: String
    var fill: () -> Color = { return figmaIndigo}
    
    // Animation states
    @State private var isPressed = false
    @State private var scale: CGFloat = 1.0
    
    init(_ buttonText: String) {
        self.buttonText = buttonText
    }
    
    init(_ buttonText: String, fill: @escaping () -> Color) {
        self.buttonText = buttonText
        self.fill = fill
    }
    
    var body: some View {
        HStack {
            Spacer()
            Text(buttonText)
				.font(.onestSemiBold(size: 20))
                .foregroundColor(.white)
                .padding(.vertical, 16)
                .padding(.horizontal, 22)
            Spacer()
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(fill())
        )
        .padding(.horizontal, 22)
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity)
        .scaleEffect(scale)
        .shadow(
            color: Color.black.opacity(0.15),
            radius: isPressed ? 2 : 8,
            x: 0,
            y: isPressed ? 2 : 4
        )
        .animation(.easeInOut(duration: 0.15), value: scale)
        .animation(.easeInOut(duration: 0.15), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        isPressed = true
                        scale = 0.95
                    }
                }
                .onEnded { _ in
                    isPressed = false
                    scale = 1.0
                }
        )
    }
}

#Preview {
    OnboardingButtonCoreView("Sign in with username or email")
}
