//
//  SpawnIntroButtonView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Shane on 7/1/25.
//

import SwiftUI

struct SpawnIntroButtonView: View {
    let buttonText: String
    let action: () -> Void
    
    init(_ buttonText: String, action: @escaping () -> Void) {
        self.buttonText = buttonText
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            // Haptic feedback
            let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
            impactGenerator.impactOccurred()
            
            // Execute action with slight delay for animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                action()
            }
        }) {
            OnboardingButtonCoreView(buttonText)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SpawnIntroButtonView("Get Started", action: {})
}
