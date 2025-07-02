//
//  LoginInputView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Shane on 7/1/25.
//

import SwiftUI

struct LoginInputView: View {
    @State private var username = ""
    @State private var password = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Navigation Bar
                HStack {
                    Button(action: {
                        // Back action
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.primary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                Spacer()
                
                // Main Content
                VStack(spacing: 32) {
                    // Title and Subtitle
                    VStack(spacing: 16) {
                        Text("Welcome Back")
                            .font(heading1)
                            .foregroundColor(.primary)
                        
                        Text("Your plans are waiting — time to spawn.")
                            .font(.onestRegular(size: 16))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }   
                    .padding(.horizontal, 40)
                    
                    // Form Fields
                    VStack(spacing: 24) {
                        // Username Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email or Username")
                                .font(.onestRegular(size: 16))
                                .foregroundColor(.primary)
                            
                            TextField("Enter your email or username", text: $username)
                                .textFieldStyle(CustomTextFieldStyle())
                        }
                        
                        // Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.onestRegular(size: 16))
                                .foregroundColor(.primary)
                            
                            SecureField("Enter your password", text: $password)
                                .textFieldStyle(CustomTextFieldStyle())
                        }
                        // Continue Button
                        OnboardingButtonView("Continue", destination: LaunchView())
                            .padding(.top, -16)
                            .padding(.bottom, -30)
                            .padding(.horizontal, -22)
                    }
                    .padding(.horizontal, 40)
                    
                    
                    // Divider with "or"
                    HStack {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)
                        
                        Text("or")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 16)
                        
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)
                    }
                    .padding(.horizontal, 40)
                    
                    // Social Login Buttons
                    VStack(spacing: 16) {
                        // Continue with Apple
                        Button(action: {}) {
                            AuthProviderButtonView(.apple)
                        }
                       
                        
                        // Continue with Google
                        Button(action: {}) {
                            AuthProviderButtonView(.google)
                        }
                    }
                    .padding(.horizontal, 40)
                }
                
                Spacer()
            }
            .background(Color(.systemBackground))
        }
        .navigationBarHidden(true)
    }
}

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .font(.system(size: 16))
    }
}

struct WelcomeBackView_Previews: PreviewProvider {
    static var previews: some View {
        LoginInputView()
    }
}
