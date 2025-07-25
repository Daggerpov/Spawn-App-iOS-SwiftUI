//
//  UserToS.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Steve on 7/12/25.
//

import SwiftUI

struct UserToS: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var userAuth = UserAuthViewModel.shared
    @State private var agreed: Bool = false
    @State private var isSubmitting: Bool = false
    @ObservedObject var themeService = ThemeService.shared
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            // Navigation Bar
            HStack {
                Button(action: {
                    // Clear any error states when going back
                    userAuth.clearAllErrors()
                    // Go back one step in the onboarding flow
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
                    Text("Just One More Thing")
                        .font(heading1)
                        .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
                        .multilineTextAlignment(.center)
                    
                    Text("By continuing, you agree to our Terms of Service and acknowledge our Privacy Policy.")
                        .font(body1)
                        .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 40)
                
                // Onboarding graphic
                Image("onboarding_terms")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 300)
                    .padding(.bottom, 20)
                
                // Checkbox and label
                HStack(alignment: .center, spacing: 12) {
                    Button(action: { agreed.toggle() }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(universalBackgroundColor(from: themeService, environment: colorScheme))
                                .frame(width: 36, height: 36)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 5)
                                        .stroke(universalPlaceHolderTextColor(from: themeService, environment: colorScheme), lineWidth: 1)
                                )
                            if agreed {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Text("I agree to the ")
                        .font(.onestMedium(size: 14))
                        .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
                    + Text("Terms")
                        .font(.onestMedium(size: 14))
                        .underline()
                        .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
                    + Text(" & ")
                        .font(.onestMedium(size: 14))
                        .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
                    + Text("Privacy Policy")
                        .font(.onestMedium(size: 14))
                        .underline()
                        .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
                }
                .padding(.horizontal, 40)
                
                // Error Message Display
                if let errorMessage = userAuth.errorMessage {
                    Text(errorMessage)
                        .font(.onestRegular(size: 14))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.top, 16)
                }
                
                // Continue Button
                Button(action: {
                    if agreed {
                        isSubmitting = true
                        Task {
                            await userAuth.acceptTermsOfService()
                            isSubmitting = false
                        }
                    }
                }) {
                    ZStack {
                        OnboardingButtonCoreView("Enter Spawn") {
                            agreed ? figmaIndigo : universalPlaceHolderTextColor(from: themeService, environment: colorScheme)
                        }
                        
                        if isSubmitting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(!agreed || isSubmitting)
                .padding(.horizontal, -22)
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .background(universalBackgroundColor(from: themeService, environment: colorScheme))
        .navigationBarHidden(true)
        .navigationDestination(
            isPresented: $userAuth.shouldNavigateToFeedView
        ) {
            if let loggedInSpawnUser = userAuth.spawnUser {
                ContentView(user: loggedInSpawnUser)
                    .navigationBarTitle("")
                    .navigationBarHidden(true)
            } else {
                EmptyView() // This should never happen
            }
        }
        .navigationDestination(isPresented: $userAuth.shouldShowOnboardingContinuation) {
            OnboardingContinuationView()
        }
        .navigationDestination(isPresented: $userAuth.shouldSkipAhead) {
            switch userAuth.skipDestination {
            case .userDetailsInput:
                UserDetailsInputView(isOAuthUser: true)
            case .userOptionalDetailsInput:
                UserOptionalDetailsInputView()
            case .contactImport:
                ContactImportView()
            case .userToS:
                UserToS()
            case .none:
                EmptyView()
            }
        }
        .onAppear {
            // Clear any previous error state when this view appears
            userAuth.clearAllErrors()
        }
    }
}

#Preview {
    UserToS()
}


