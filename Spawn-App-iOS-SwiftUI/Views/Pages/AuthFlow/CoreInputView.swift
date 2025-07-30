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
    @ObservedObject var themeService = ThemeService.shared
    @Environment(\.colorScheme) var colorScheme
    
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
        NavigationStack {
            VStack(spacing: 0) {
                // Navigation Bar
                HStack {
                    Button(action: {
                        // Back action
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
                        Text(heading)
                            .font(heading1)
                            .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
                        
                        Text(subtitle)
                            .font(.onestRegular(size: 16))
                            .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme).opacity(0.7))
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
                                .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
                            
                            TextField(inputText1, text: $input1)
                                .textFieldStyle(CustomTextFieldStyle())
                        }
                        
                        // Password Field
                        if let label2 = self.label2, let inputText2 = self.inputText2 {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(label2)
                                    .font(.onestRegular(size: 16))
                                    .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
                                
                                SecureField(inputText2, text: $input2)
                                    .textFieldStyle(CustomTextFieldStyle())
                            }
                            // Continue Button
                            Button(action: {
                                // Haptic feedback
                                let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
                                impactGenerator.impactOccurred()
                                
                                // Execute action with slight delay for animation
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    continueAction()
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
                            
                            viewModel.appleRegister()
                        }) {
                            AuthProviderButtonView(.apple)
                        }
                        .buttonStyle(AuthProviderButtonStyle())
                       
                        
                        // Continue with Google
                        Button(action: {
                            // Haptic feedback
                            let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
                            impactGenerator.impactOccurred()
                            
                            Task{
                                await viewModel.googleRegister()
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
            .background(universalBackgroundColor(from: themeService, environment: colorScheme))
        }
        .navigationBarHidden(true)
        .navigationDestination(for: NavigationState.self) { state in
            switch state {
            case .welcome:
                LaunchView()
            case .signIn:
                SignInView()
                    .onAppear {
                        viewModel.resetAuthFlow()
                    }
            case .register:
                RegisterInputView()
                    .onAppear {
                        viewModel.resetAuthFlow()
                    }
            case .loginInput:
                SignInView()
            case .accountNotFound:
                AccountNotFoundView()
                    .navigationBarTitle("")
                    .navigationBarHidden(true)
            case .onboardingContinuation:
                OnboardingContinuationView()
            case .userDetailsInput(let isOAuthUser):
                UserDetailsInputView(isOAuthUser: isOAuthUser)
                    .navigationBarTitle("")
                    .navigationBarHidden(true)
            case .userOptionalDetailsInput:
                UserOptionalDetailsInputView()
                    .navigationBarTitle("")
                    .navigationBarHidden(true)
            case .contactImport:
                ContactImportView()
                    .navigationBarTitle("")
                    .navigationBarHidden(true)
            case .userTermsOfService:
                UserToS()
                    .navigationBarTitle("")
                    .navigationBarHidden(true)
            case .phoneNumberInput:
                UserDetailsInputView(isOAuthUser: false)
            case .verificationCode:
                VerificationCodeView(viewModel: viewModel)
            case .feedView:
                if let loggedInSpawnUser = viewModel.spawnUser {
                    ContentView(user: loggedInSpawnUser)
                        .navigationBarTitle("")
                        .navigationBarHidden(true)
                } else {
                    EmptyView() // This should never happen
                }
            case .none:
                EmptyView()
            }
        }
    }
}

struct CustomTextFieldStyle: TextFieldStyle {
    @ObservedObject var themeService = ThemeService.shared
    @Environment(\.colorScheme) var colorScheme
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
            .background(getInputFieldBackgroundColor())
            .cornerRadius(16)
            .font(.onestRegular(size: 16))
            .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
            .accentColor(universalAccentColor(from: themeService, environment: colorScheme))
    }
    
    private func getInputFieldBackgroundColor() -> Color {
        // Use a theme-aware background color for input fields
        let currentScheme = themeService.colorScheme
        switch currentScheme {
        case .light:
            return figmaAuthButtonGrey
        case .dark:
            return Color(hex: "#2C2C2C")
        case .system:
            return colorScheme == .dark ? Color(hex: "#2C2C2C") : figmaAuthButtonGrey
        }
    }
}

// Error-aware text field component with red borders
struct ErrorTextFieldStyle: TextFieldStyle {
    let hasError: Bool
    @ObservedObject var themeService = ThemeService.shared
    @Environment(\.colorScheme) var colorScheme
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
            .background(getInputFieldBackgroundColor())
            .cornerRadius(16)
            .font(.onestRegular(size: 16))
            .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
            .accentColor(universalAccentColor(from: themeService, environment: colorScheme))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .inset(by: 1)
                    .stroke(hasError ? Color(red: 0.77, green: 0.19, blue: 0.19) : Color.clear, lineWidth: 1)
            )
    }
    
    private func getInputFieldBackgroundColor() -> Color {
        // Use a theme-aware background color for input fields
        let currentScheme = themeService.colorScheme
        switch currentScheme {
        case .light:
            return figmaAuthButtonGrey
        case .dark:
            return Color(hex: "#2C2C2C")
        case .system:
            return colorScheme == .dark ? Color(hex: "#2C2C2C") : figmaAuthButtonGrey
        }
    }
}

// Error-aware secure field component with red borders
struct ErrorSecureFieldStyle: TextFieldStyle {
    let hasError: Bool
    @ObservedObject var themeService = ThemeService.shared
    @Environment(\.colorScheme) var colorScheme
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
            .background(getInputFieldBackgroundColor())
            .cornerRadius(16)
            .font(.onestRegular(size: 16))
            .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
            .accentColor(universalAccentColor(from: themeService, environment: colorScheme))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .inset(by: 1)
                    .stroke(hasError ? Color(red: 0.77, green: 0.19, blue: 0.19) : Color.clear, lineWidth: 1)
            )
    }
    
    private func getInputFieldBackgroundColor() -> Color {
        // Use a theme-aware background color for input fields
        let currentScheme = themeService.colorScheme
        switch currentScheme {
        case .light:
            return figmaAuthButtonGrey
        case .dark:
            return Color(hex: "#2C2C2C")
        case .system:
            return colorScheme == .dark ? Color(hex: "#2C2C2C") : figmaAuthButtonGrey
        }
    }
}
