//
//  OnboardingButton.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Shane on 7/1/25.
//

import SwiftUI

struct OnboardingButtonView<Destination: View>: View {
    let buttonText: String
    let destination: Destination
    @State private var isPressed = false
    
    
    init(_ buttonText: String, destination: Destination) {
        self.buttonText = buttonText
        self.destination = destination
    }
    
    var body: some View {
        NavigationLink(destination: destination) {
            OnboardingButtonCoreView(buttonText)
                .opacity(isPressed ? 0.4 : 1.0)
        }
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
            if pressing {
                // Haptic feedback on press
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
            }
        }, perform: {})
    }
}

#Preview {
    OnboardingButtonView("Get Started", destination: LaunchView())
}
