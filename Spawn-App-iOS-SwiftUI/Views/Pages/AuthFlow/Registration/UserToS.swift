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
            Spacer(minLength: 40)
            // Title and Subtitle
            VStack(alignment: .center, spacing: 20) {
                Text("Just One More Thing")
                    .font(heading1)
                    .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
                    .multilineTextAlignment(.center)
                Text("By continuing, you agree to our Terms of Service and acknowledge our Privacy Policy.")
                    .font(body1)
                    .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
                    .multilineTextAlignment(.center)
            }
            .frame(width: 364)
            .padding(.top, 40)
            
            // Onboarding graphic
            Image("onboarding_terms")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 300)
                .padding(.vertical, 40)
            
            Spacer()
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
            .padding(.top, 8)
            .padding(.bottom, 8)
            .frame(width: 364, alignment: .leading)
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
                    Text("Enter Spawn")
                        .font(.onestSemiBold(size: 20))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 63)
                        .background(agreed ? figmaIndigo : universalPlaceHolderTextColor(from: themeService, environment: colorScheme))
                        .cornerRadius(16)
                    
                    if isSubmitting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                }
            }
            .disabled(!agreed || isSubmitting)
            .frame(width: 364)
            .padding(.bottom, 16)
        }
        .frame(width: 428, height: 926)
        .background(universalBackgroundColor(from: themeService, environment: colorScheme))
        .cornerRadius(44)
        .navigationBarHidden(true)
    }
}

#Preview {
    UserToS()
}


