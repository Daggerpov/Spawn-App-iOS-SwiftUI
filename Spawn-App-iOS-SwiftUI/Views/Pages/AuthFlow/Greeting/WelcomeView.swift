//
//  WelcomeView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Shane on 7/1/25.
//

import SwiftUI

struct WelcomeView: View {
    @State private var animationCompleted = false
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                
                if !animationCompleted {
                    // Initial Rive animation for new users
                    RiveAnimationView.logoAnimation(fileName: "spawn_logo_animation")
                        .frame(width: 300, height: 300)
                        .onAppear {
                            // Show content after animation completes
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    animationCompleted = true
                                }
                            }
                        }
                } else {
                    // Static logo after animation
                    Image("SpawnLogo")
                        .scaledToFit()
                        .transition(.opacity)
                }
                
                if animationCompleted {
                    Text("Welcome to Spawn")
                        .font(heading1)
                        .transition(.opacity)
                    Text("Spontaneity made easy.")
                        .font(body1)
                        .transition(.opacity)
                    
                    Spacer()
                    
                    OnboardingButtonView("Get Started", destination: SpawnIntroView())
                        .padding(.bottom, 12)
                        .transition(.opacity)
                }
                
                Spacer()
            }
            .background(Color.white)
            .ignoresSafeArea(.all)
            .preferredColorScheme(.light)
        }
    }
}

#Preview {
    WelcomeView()
}
