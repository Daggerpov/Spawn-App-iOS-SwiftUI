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
        Button(action: {action()}) {
            OnboardingButtonCoreView(buttonText)
        }
    }
}

#Preview {
    SpawnIntroButtonView("Get Started", action: {})
}
