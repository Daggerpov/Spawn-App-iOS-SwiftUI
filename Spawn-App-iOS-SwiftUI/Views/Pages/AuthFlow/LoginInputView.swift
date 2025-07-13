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
    @State private var hasLoginError = false
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var themeService = ThemeService.shared
    @Environment(\.colorScheme) var colorScheme
    
    // Animation states
    @State private var isPressed = false
    @State private var scale: CGFloat = 1.0
    
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
                        .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
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
                        .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
                    
                    Text("Your plans are waiting - time to spawn.")
                        .font(.onestRegular(size: 16))
                        .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme).opacity(0.7))
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
                            .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
                        
                        TextField("Enter your email or username", text: $usernameOrEmail)
                            .textFieldStyle(ErrorTextFieldStyle(hasError: hasLoginError))
                            .onChange(of: usernameOrEmail) { _ in
                                hasLoginError = false
                            }
                    }
                    
                    // Password Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.onestRegular(size: 16))
                            .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
                        
                        SecureField("Enter your password", text: $password)
                            .textFieldStyle(ErrorSecureFieldStyle(hasError: hasLoginError))
                            .onChange(of: password) { _ in
                                hasLoginError = false
                            }
                    }
                    
                    // Continue Button
                    Button(action: {
                        // Haptic feedback
                        let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
                        impactGenerator.impactOccurred()
                        
                        // Execute action with slight delay for animation
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            Task {
                                await performLogin()
                            }
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
                    .buttonStyle(PlainButtonStyle())
                    .disabled(!isFormValid || isLoading)
                    .scaleEffect(scale)
                    .shadow(
                        color: (isFormValid && !isLoading) ? Color.black.opacity(0.15) : Color.clear,
                        radius: isPressed ? 2 : 8,
                        x: 0,
                        y: isPressed ? 2 : 4
                    )
                    .animation(.easeInOut(duration: 0.15), value: scale)
                    .animation(.easeInOut(duration: 0.15), value: isPressed)
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                guard isFormValid && !isLoading && !isPressed else { return }
                                isPressed = true
                                scale = 0.95
                            }
                            .onEnded { _ in
                                guard isFormValid && !isLoading else { return }
                                isPressed = false
                                scale = 1.0
                            }
                    )
                }
                .padding(.horizontal, 40)
                
                // Error Message
                if hasLoginError {
                    Text(errorMessage)
                        .font(Font.custom("Onest", size: 14).weight(.medium))
                        .foregroundColor(Color(red: 0.92, green: 0.26, blue: 0.21))
                        .padding(.horizontal, 40)
                        .padding(.top, -16)
                }
                
                // Divider with "or"
                HStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 1)
                    
                    Text("or")
                        .font(.system(size: 16))
                        .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme).opacity(0.7))
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
                        // Haptic feedback
                        let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
                        impactGenerator.impactOccurred()
                        
                        userAuth.signInWithApple()
                    }) {
                        AuthProviderButtonView(.apple)
                    }
                    .buttonStyle(AuthProviderButtonStyle())
                   
                    // Continue with Google
                    Button(action: {
                        // Haptic feedback
                        let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
                        impactGenerator.impactOccurred()
                        
                        Task {
                            await userAuth.loginWithGoogle()
                        }
                    }) {
                        AuthProviderButtonView(.google)
                    }
                    .buttonStyle(AuthProviderButtonStyle())
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
                hasLoginError = false
                print("Login successful")
            } else {
                // Login failed - show error message
                errorMessage = userAuth.errorMessage ?? "Login failed. Please check your credentials and try again."
                hasLoginError = true
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
