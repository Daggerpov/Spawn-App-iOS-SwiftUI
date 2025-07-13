//
//  CoreInputView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Shane on 7/2/25.
//

import SwiftUI

struct CoreInputView: View {
    @ObservedObject private var viewModel: UserAuthViewModel = UserAuthViewModel.shared
    @State var input1 = ""
    @State var input2 = ""
    
    var heading: String
    var subtitle: String
    
    var label1: String
    var label2: String?
    
    var inputText1: String
    var inputText2: String?
    
    var labelSubtitle: String?
    
    var continueAction: () -> Void
    
    private var isFormValid: Bool {
        !input1.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !input2.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
                        Text(heading)
                            .font(heading1)
                            .foregroundColor(.primary)
                        
                        Text(subtitle)
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
                            Text(label1)
                                .font(.onestRegular(size: 16))
                                .foregroundColor(.primary)
                            
                            TextField(inputText1, text: $input1)
                                .textFieldStyle(CustomTextFieldStyle())
                        }
                        
                        // Password Field
                        if let label2 = self.label2, let inputText2 = self.inputText2 {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(label2)
                                    .font(.onestRegular(size: 16))
                                    .foregroundColor(.primary)
                                
                                SecureField(inputText2, text: $input2)
                                    .textFieldStyle(CustomTextFieldStyle())
                            }
                            // Continue Button
                            Button(action: {
                                continueAction()
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
                    }
                    .padding(.horizontal, 40)
                    
                    if let buttonSubtitle = labelSubtitle {
                        Text(buttonSubtitle)
                            .font(.onestRegular(size: 16))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    
                    
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
                            viewModel.signInWithApple()
                        }) {
                            AuthProviderButtonView(.apple)
                        }
                       
                        
                        // Continue with Google
                        Button(action: {
                            Task{
                                await viewModel.loginWithGoogle()
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
        }
        .navigationBarHidden(true)
    }
}

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
            .background(figmaAuthButtonGrey)
            .cornerRadius(16)
            .font(.onestRegular(size: 16))
    }
}
