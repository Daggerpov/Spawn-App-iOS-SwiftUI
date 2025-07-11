//
//  RegisterInputView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Shane on 7/2/25.
//

import SwiftUI

struct RegisterInputView: View {
    @ObservedObject var viewModel: UserAuthViewModel
    @State private var emailInput: String = ""
    var placeholder: String = "yourname@email.com"
    private var isFormValid: Bool {
        !emailInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
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
                        Text("Create Your Account")
                            .font(heading1)
                            .foregroundColor(.primary)
                        
                        Text("Choose how you'd like to set up your account.")
                            .font(.onestRegular(size: 16))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    .padding(.horizontal, 40)
                    
                    // Form Fields
                    VStack(spacing: 24) {
                        // Email Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.onestRegular(size: 16))
                                .foregroundColor(.primary)
                            
                            TextField(placeholder, text: $emailInput)
                                .textFieldStyle(CustomTextFieldStyle())
                                .textContentType(.emailAddress)
                        }
                        
                        // Continue Button
                        Button(action: {
                            Task {
                                await viewModel.register(email: emailInput, idToken: nil, provider: nil)
                            }
                        }) {
                            OnboardingButtonCoreView("Continue") {
                                isFormValid ? figmaIndigo : Color.gray.opacity(0.6)
                            }
                        }
                        .padding(.top, -16)
                        .padding(.bottom, -30)
                        .padding(.horizontal, -22)
                        .disabled(!isFormValid)
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
                    
                    // External Login Buttons
                    VStack(spacing: 16) {
                        // Continue with Apple
                        Button(action: {
                            viewModel.appleRegister()
                        }) {
                            AuthProviderButtonView(.apple)
                        }
                       
                        
                        // Continue with Google
                        Button(action: {
                            Task{
                                await viewModel.googleRegister()
                            }
                        }) {
                            AuthProviderButtonView(.google)
                        }
                    }
                    .padding(.horizontal, 40)
                }
                
                Spacer()
            }
            .background(Color(.systemBackground))
            .navigationDestination(isPresented: $viewModel.shouldNavigateToPhoneNumberView, destination: {PhoneNumberView(viewModel: viewModel)})
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    RegisterInputView(viewModel: UserAuthViewModel.shared)
}
