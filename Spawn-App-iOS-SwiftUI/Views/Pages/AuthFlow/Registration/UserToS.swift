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
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 40)
            // Title and Subtitle
            VStack(alignment: .center, spacing: 20) {
                Text("Just One More Thing")
                    .font(Font.custom("Onest-SemiBold", size: 32))
                    .foregroundColor(Color(red: 0.11, green: 0.11, blue: 0.11))
                    .multilineTextAlignment(.center)
                Text("By continuing, you agree to our Terms of Service and acknowledge our Privacy Policy.")
                    .font(Font.custom("Onest-Regular", size: 20))
                    .foregroundColor(Color(red: 0.11, green: 0.11, blue: 0.11))
                    .multilineTextAlignment(.center)
            }
            .frame(width: 364)
            .padding(.top, 40)
            Spacer()
            // Checkbox and label
            HStack(alignment: .center, spacing: 12) {
                Button(action: { agreed.toggle() }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color(red: 0.96, green: 0.96, blue: 0.96))
                            .frame(width: 36, height: 36)
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        if agreed {
                            Image(systemName: "checkmark")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.black)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                Text("I agree to the ")
                    .font(Font.custom("Onest-Medium", size: 14))
                    .foregroundColor(Color(red: 0.12, green: 0.12, blue: 0.12))
                + Text("Terms")
                    .font(Font.custom("Onest-Medium", size: 14))
                    .underline()
                    .foregroundColor(.black)
                + Text(" & ")
                    .font(Font.custom("Onest-Medium", size: 14))
                    .foregroundColor(Color(red: 0.12, green: 0.12, blue: 0.12))
                + Text("Privacy Policy")
                    .font(Font.custom("Onest-Medium", size: 14))
                    .underline()
                    .foregroundColor(.black)
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
                        .font(Font.custom("Onest-SemiBold", size: 20))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 63)
                        .background(agreed ? Color(red: 0.32, green: 0.42, blue: 0.93) : Color.gray.opacity(0.4))
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
        .background(Color.white)
        .cornerRadius(44)
        .navigationBarHidden(true)
        .onAppear {
            // Reset navigation state to prevent conflicts
            userAuth.shouldNavigateToUserToS = false
        }
    }
}

#Preview {
    UserToS()
}


