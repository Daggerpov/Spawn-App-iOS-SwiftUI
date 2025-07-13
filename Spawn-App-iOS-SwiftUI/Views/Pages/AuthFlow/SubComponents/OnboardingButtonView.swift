//
//  OnboardingButton.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Shane on 7/1/25.
//

import SwiftUI

struct OnboardingButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

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
            print("🔘 DEBUG: '\(buttonText)' button tapped")
            // Haptic feedback
            let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
            impactGenerator.impactOccurred()
            
            // Execute navigation with slight delay for animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isNavigating = true
                print("🔘 DEBUG: Setting isNavigating to true for '\(buttonText)'")
            }
        }) {
            OnboardingButtonCoreView(buttonText)
        }
        .buttonStyle(OnboardingButtonStyle())
        .navigationDestination(isPresented: $isNavigating) {
            destination
                .onAppear {
                    print("🔘 DEBUG: Navigation destination appeared for '\(buttonText)'")
                }
        }
        .onAppear {
            print("🔘 DEBUG: OnboardingButtonView appeared with text: '\(buttonText)'")
        }
    }
}

#Preview {
    OnboardingButtonView("Get Started", destination: LaunchView())
}
