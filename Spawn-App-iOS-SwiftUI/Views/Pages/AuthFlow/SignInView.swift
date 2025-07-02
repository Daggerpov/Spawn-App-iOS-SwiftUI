//
//  SignInView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Shane on 7/1/25.
//

import SwiftUI

struct SignInView: View {
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
                
                // Buttons
                VStack {
                    // Create Account Button
                    OnboardingButtonView("Create an Account", destination: LaunchView())
                        .padding(.bottom, -16)
                    
                    // Log in text
                    HStack(spacing: 4) {
                        Text("Have an account already?")
                            .font(.onestRegular(size: 14))
                            
                        
                        NavigationLink(destination: LaunchView()) {
                            // Handle log in action
                            Text("Log in")
                                .font(.onestSemiBold(size: 14))
                                .foregroundColor(.black)
                                .underline()
                        }
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 60)
            }
        }
    }
}

// Preview
#Preview {
    SignInView()
}
