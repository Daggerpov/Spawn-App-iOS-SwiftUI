//
//  OnboardingButtonCoreView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Shane on 7/1/25.
//

import SwiftUI

struct OnboardingButtonCoreView: View {
    let buttonText: String
    
    init(_ buttonText: String) {
        self.buttonText = buttonText
    }
    
    var body: some View {
        HStack {
            Spacer()
            Text(buttonText)
                .font(body1)
                .foregroundColor(.white)
                .padding(.vertical, 16)
                .padding(.horizontal, 22)
            Spacer()
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(figmaIndigo)
        )
        .padding(.horizontal, 22)
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    OnboardingButtonCoreView("Sign in with username or email")
}
