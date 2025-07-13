//
//  UserDetailsView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Shane on 2025-07-11.
//

import SwiftUI

struct UserDetailsInputView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: UserAuthViewModel = .shared
    @State private var username: String = ""
    @State private var phoneNumber: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var usernameError: String? = nil
    @State private var passwordError: String? = nil
    @State private var isUsernameTaken: Bool = false
    @State private var isPasswordMismatch: Bool = false
    
    // New: Indicate if this is an OAuth user (passed in or set from view model)
    var isOAuthUser: Bool = false
    
    private var isFormValid: Bool {
        let usernameValid = !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isUsernameTaken
        let phoneValid = !phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        if isOAuthUser {
            return usernameValid && phoneValid
        } else {
            return usernameValid && phoneValid && !password.isEmpty && !confirmPassword.isEmpty && password == confirmPassword
        }
    }
    
    // Phone number formatter (US style: (XXX) XXX-XXXX)
    private func formatPhoneNumber(_ number: String) -> String {
        let digits = number.filter { $0.isNumber }
        var result = ""
        let count = digits.count
        if count == 0 { return "" }
        if count < 4 {
            result = digits
        } else if count < 7 {
            let area = digits.prefix(3)
            let prefix = digits.suffix(count - 3)
            result = "(\(area)) \(prefix)"
        } else {
            let area = digits.prefix(3)
            let prefix = digits.dropFirst(3).prefix(3)
            let line = digits.dropFirst(6).prefix(4)
            result = "(\(area)) \(prefix)-\(line)"
        }
        return result
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Navigation Bar
            HStack {
                Button(action: { dismiss() }) {
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
                    Text(isOAuthUser ? "Complete Your Profile" : "Create Your Account")
                        .font(heading1)
                        .foregroundColor(.primary)
                    Text(isOAuthUser ? "Add a username and phone number to complete your account." : "Just a few details to get started.")
                        .font(.onestRegular(size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 40)
                
                // Form Fields
                VStack(spacing: 24) {
                    // Username Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Username")
                            .font(.onestRegular(size: 16))
                            .foregroundColor(.primary)
                        TextField("Create a unique nickname", text: $username)
                            .textFieldStyle(CustomTextFieldStyle())
                            .autocapitalization(.none)
                            .textContentType(.username)
                            .disableAutocorrection(true)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(isUsernameTaken ? Color.red : Color.clear, lineWidth: 2)
                            )
                            .onChange(of: username) { newValue in
                                // Simulate username taken error for demo (replace with real check)
                                if newValue == "dagapov" {
                                    isUsernameTaken = true
                                    usernameError = "This username is taken. Existing users need to Sign In."
                                } else {
                                    isUsernameTaken = false
                                    usernameError = nil
                                }
                            }
                    }
                    // Phone Number Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Phone Number")
                            .font(.onestRegular(size: 16))
                            .foregroundColor(.primary)
                        TextField("Enter your phone number", text: $phoneNumber)
                            .textFieldStyle(CustomTextFieldStyle())
                            .keyboardType(.phonePad)
                            .onChange(of: phoneNumber) { newValue in
                                let formatted = formatPhoneNumber(newValue)
                                if formatted != newValue {
                                    phoneNumber = formatted
                                }
                            }
                            .textContentType(.telephoneNumber)
                    }
                    // Password Fields (only if not OAuth)
                    if !isOAuthUser {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.onestRegular(size: 16))
                                .foregroundColor(.primary)
                            SecureField("Enter a strong password", text: $password)
                                .textFieldStyle(CustomTextFieldStyle())
                                .autocapitalization(.none)
                                .textContentType(.newPassword)
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm Password")
                                .font(.onestRegular(size: 16))
                                .foregroundColor(.primary)
                            SecureField("Re-enter password", text: $confirmPassword)
                                .textFieldStyle(CustomTextFieldStyle())
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(isPasswordMismatch ? Color.red : Color.clear, lineWidth: 2)
                                )
                                .onChange(of: confirmPassword) { newValue in
                                    isPasswordMismatch = password != newValue
                                    passwordError = isPasswordMismatch ? "Please ensure that your passwords match." : nil
                                }
                                .onChange(of: password) { newValue in
                                    isPasswordMismatch = confirmPassword != newValue
                                    passwordError = isPasswordMismatch ? "Please ensure that your passwords match." : nil
                                }
                                .autocapitalization(.none)
                                .textContentType(.newPassword)
                        }
                    }
                    // Error Messages
                    if let usernameError = usernameError, isUsernameTaken {
                        HStack(spacing: 4) {
                            Text(usernameError)
                                .font(.onestRegular(size: 15))
                                .foregroundColor(.red)
                            Button(action: { /* Navigate to sign in */ }) {
                                Text("Sign In.")
                                    .underline()
                                    .font(.onestRegular(size: 15))
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    if let passwordError = passwordError, isPasswordMismatch && !isOAuthUser {
                        Text(passwordError)
                            .font(.onestRegular(size: 15))
                            .foregroundColor(.red)
                    }
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.onestRegular(size: 15))
                            .foregroundColor(.red)
                    }
                    // Continue Button
                    Button(action: {
                        // Haptic feedback
                        let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
                        impactGenerator.impactOccurred()
                        
                        // Execute action with slight delay for animation
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            Task {
                                guard let user = viewModel.spawnUser else { return }
                                await viewModel.updateUserDetails(
                                    id: user.id.uuidString,
                                    username: username,
                                    phoneNumber: phoneNumber,
                                    password: isOAuthUser ? nil : password
                                )
                            }
                        }
                    }) {
                        OnboardingButtonCoreView("Continue") {
                            isFormValid ? figmaIndigo : Color.gray.opacity(0.6)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.top, -16)
                    .padding(.bottom, -30)
                    .padding(.horizontal, -22)
                    .disabled(!isFormValid)
                }
                .padding(.horizontal, 40)
            }
            Spacer()
        }
        .background(Color(.systemBackground))
        .navigationDestination(isPresented: $viewModel.shouldNavigateToUserOptionalDetailsInputView) {
            UserSetupView()
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    UserDetailsInputView()
}
