//
//  PhoneNumberView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Shane on 7/8/25.
//

import SwiftUI

struct PhoneNumberView: View {
    @ObservedObject var viewModel: UserAuthViewModel
    @State private var phoneNumber: String = ""
    var placeholder: String = "+1 123-456-7890"
    private var isFormValid: Bool {
        !phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Navigation Bar
                Spacer()
                HStack {
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
                                Text("Phone Number")
                                    .font(.onestRegular(size: 16))
                                    .foregroundColor(.primary)
                                
                                TextField(placeholder, text: $phoneNumber)
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .textContentType(.telephoneNumber)
                            }
                            
                            // Continue Button
                            Button(action: {
                                Task {
                                    await viewModel.requestVerification(number: phoneNumber)
                                }
                            }) {
                                OnboardingButtonCoreView("Send Code") {
                                    isFormValid ? figmaIndigo : Color.gray.opacity(0.6)
                                }
                            }
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
                .navigationDestination(isPresented: $viewModel.shouldNavigateToVerificationCodeView, destination: {LaunchView()})
                Spacer()
            }
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    PhoneNumberView(viewModel: UserAuthViewModel.shared)
}
