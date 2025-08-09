//
//  SignInView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Shane on 7/1/25.
//

import SwiftUI

struct SignInView: View {
    @ObservedObject var themeService = ThemeService.shared
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var userAuth = UserAuthViewModel.shared
    
    var body: some View {
        ZStack {
            // Background
            universalBackgroundColor(from: themeService, environment: colorScheme)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Logo
                Image("SpawnLogo")
                    .padding(.bottom, 120)
                
                // Main content
                GetInTextView()
                .padding(.horizontal, 40)
                
                Spacer()
                
                // Buttons
                VStack {
                    // Create Account Button
                    Button(action: {
                        print("🔘 DEBUG: Create Account button tapped")
                        // Haptic feedback
                        let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
                        impactGenerator.impactOccurred()
                        
                        // Use auth navigation system
                        userAuth.navigateTo(.register)
                    }) {
                        OnboardingButtonCoreView("Create an Account") {
                            figmaIndigo
                        }
                    }
                    .buttonStyle(OnboardingButtonStyle())
                    .padding(.bottom, -16)
                    
                    // Log in text
                    HStack(spacing: 4) {
                        Text("Have an account already?")
                            .font(.onestRegular(size: 14))
                            .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
                            
                        
                        NavigationLink(destination: LoginInputView()) {
                            // Handle log in action
                            Text("Log in")
                                .font(.onestSemiBold(size: 14))
                                .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
                                .underline()
                        }
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 60)
            }
            .padding(.horizontal)
        }
        .background(universalBackgroundColor(from: themeService, environment: colorScheme))
        .ignoresSafeArea(.all)
        .navigationBarHidden(true)
		.onAppear {
            // Clear any previous error state when returning to main auth screen
            userAuth.clearAllErrors()
		}
    }
}

// Preview
#Preview {
    SignInView()
}
