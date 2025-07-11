//
//  LogInView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Shane on 7/1/25.
//

import SwiftUI

struct LoginView: View {
    @ObservedObject private var viewModel: UserAuthViewModel = UserAuthViewModel.shared
    
    var body: some View {
        ZStack {
            // Background
            Color.white
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
                
                // Login options
                VStack(spacing: 16) {
                    // Continue with Apple
                    Button(action: {
                        viewModel.signInWithApple()
                    }) {
                        AuthProviderButtonView(.apple)
                    }
                   
                    
                    // Continue with Google
                    Button(action: {
                        Task {
                            await viewModel.loginWithGoogle()
                        }
                    }) {
                        AuthProviderButtonView(.google)
                    }
                    
                    
                    // Sign in with Username/Email
                    OnboardingButtonView("Sign in with Username or Email", destination: LaunchView())
                    
                    
                }
                .padding(.bottom, 60)
            }
        }
    }
}

// Preview
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
