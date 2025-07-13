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
    @State private var isNavigating = false
    
    init(_ buttonText: String, destination: Destination) {
        self.buttonText = buttonText
        self.destination = destination
    }
    
    var body: some View {
        Button(action: {
            // Haptic feedback
            let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
            impactGenerator.impactOccurred()
            
            // Execute navigation with slight delay for animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isNavigating = true
            }
        }) {
            OnboardingButtonCoreView(buttonText)
        }
        .buttonStyle(PlainButtonStyle())
        .navigationDestination(isPresented: $isNavigating) {
            destination
        }
    }
}

#Preview {
    OnboardingButtonView("Get Started", destination: LaunchView())
}
