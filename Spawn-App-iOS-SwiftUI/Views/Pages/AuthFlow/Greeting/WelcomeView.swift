//
//  WelcomeView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Shane on 7/1/25.
//

import SwiftUI

struct WelcomeView: View {
    @State private var animationCompleted = false
    @ObservedObject var themeService = ThemeService.shared
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var userAuth = UserAuthViewModel.shared
    
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
					Spacer()
					Spacer()
					Spacer()
					Spacer()
					Spacer()
                    // Static logo after animation
                    Image("SpawnLogo")
                        .scaledToFit()
                        .transition(.opacity)
						.padding(.bottom, 12)
                }
                
                if animationCompleted {
                    Text("Spontaneity made easy.")
						.font(.onestRegular(size: 20))
                        .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
                        .transition(.opacity)

                    // Skip onboarding for returning users
                    if userAuth.hasCompletedOnboarding {
                        OnboardingButtonView("Get Started", destination: SignInView())
                            .padding(.bottom, 12)
                            .transition(.opacity)
                    } else {
						Spacer()
                        OnboardingButtonView("Get Started", destination: SpawnIntroView())
							.padding(.top, 12)
                            .transition(.opacity)
                    }
                }
                
                Spacer()
            }
            .background(universalBackgroundColor(from: themeService, environment: colorScheme))
            .ignoresSafeArea(.all)
        }
    }
}

#Preview {
    WelcomeView()
}
