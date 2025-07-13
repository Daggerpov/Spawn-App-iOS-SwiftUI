//
//  LoginInputView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Shane on 7/1/25.
//

import SwiftUI

struct LoginInputView: View {
    @StateObject private var userAuth = UserAuthViewModel.shared
    @State private var usernameOrEmail = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @Environment(\.dismiss) private var dismiss
    
    private var isFormValid: Bool {
        !usernameOrEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        
        VStack(spacing: 0) {
            // Navigation Bar
            HStack {
                Button(action: {
                    // Back action
                    dismiss()
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
                    
                    Text("Your plans are waiting - time to spawn.")
                        .font(.onestRegular(size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .padding(.horizontal, 40)
                
                // Form Fields
                VStack(spacing: 24) {
                    // Username/Email Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email or Username")
                            .font(.onestRegular(size: 16))
                            .foregroundColor(.primary)
                        
                        TextField("Enter your email or username", text: $usernameOrEmail)
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
                    Button(action: {
                        Task {
                            await performLogin()
                        }
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(isFormValid ? figmaIndigo : Color.gray.opacity(0.6))
                                .frame(height: 55)
                            
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Continue")
                                    .font(.onestMedium(size: 16))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .disabled(!isFormValid || isLoading)
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
                        userAuth.signInWithApple()
                    }) {
                        AuthProviderButtonView(.apple)
                    }
                   
                    // Continue with Google
                    Button(action: {
                        Task {
                            await userAuth.loginWithGoogle()
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
        .navigationBarHidden(true)
        .onAppear {
            // Reset any previous error state
            userAuth.errorMessage = nil
        }
        .alert("Login Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func performLogin() async {
        isLoading = true
        
        await userAuth.signInWithEmailOrUsername(
            usernameOrEmail: usernameOrEmail,
            password: password
        )
        
        await MainActor.run {
            isLoading = false
            
            // Check if login was successful
            if userAuth.spawnUser != nil {
                // Login successful - navigation will be handled by the view model
                print("Login successful")
            } else {
                // Login failed - show error message
                errorMessage = userAuth.errorMessage ?? "Login failed. Please check your credentials and try again."
                showErrorAlert = true
            }
        }
    }
}

struct WelcomeBackView_Previews: PreviewProvider {
    static var previews: some View {
        LoginInputView()
    }
}
