//
//  WelcomeView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Shane on 7/1/25.
//

import SwiftUI

struct WelcomeView: View {
    var body: some View {
        VStack {
            Spacer()
            Image("SpawnLogo")
                .scaledToFit()
            Text("Welcome to Spawn")
                .font(heading1)
            Text("Spontaneity made easy.")
                .font(body1)
            Spacer()
            OnboardingButtonView("Get Started", destination: LaunchView())
                .padding(.bottom, 12)
        }
    }
}

#Preview {
    WelcomeView()
}
