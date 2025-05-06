//
//  ChangePasswordView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 5/5/25.
//


import SwiftUI

struct ChangePasswordView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isSuccess = false
    @StateObject var userAuth = UserAuthViewModel.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(universalAccentColor)
                        .font(.title3)
                }
                
                Spacer()
                
                Text("Change Password")
                    .font(.headline)
                    .foregroundColor(.black)
                
                Spacer()
                
                // Empty view for balance
                Color.clear.frame(width: 24, height: 24)
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 16)
            
            VStack(spacing: 24) {
                SecureField("Current Password", text: $currentPassword)
                    .padding()
                    .foregroundColor(universalAccentColor)
                    .font(.subheadline)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(
                            cornerRadius: universalNewRectangleCornerRadius
                        )
                            .stroke(universalAccentColor, lineWidth: 1)
                    )
                
                SecureField("New Password", text: $newPassword)
                    .padding()
                    .foregroundColor(universalAccentColor)
                    .font(.subheadline)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(
                            cornerRadius: universalNewRectangleCornerRadius
                        )
                            .stroke(universalAccentColor, lineWidth: 1)
                    )
                
                SecureField("Confirm New Password", text: $confirmPassword)
                    .padding()
                    .foregroundColor(universalAccentColor)
                    .font(.subheadline)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(
                            cornerRadius: universalNewRectangleCornerRadius
                        )
                            .stroke(universalAccentColor, lineWidth: 1)
                    )
                
                Button(action: {
                    if newPassword.isEmpty || confirmPassword.isEmpty || currentPassword.isEmpty {
                        alertMessage = "Please fill in all fields"
                        showAlert = true
                        return
                    }
                    
                    if newPassword != confirmPassword {
                        alertMessage = "New passwords don't match"
                        showAlert = true
                        return
                    }
                    
                    Task {
                        do {
                            try await userAuth.changePassword(currentPassword: currentPassword, newPassword: newPassword)
                            alertMessage = "Password successfully changed"
                            isSuccess = true
                            showAlert = true
                        } catch {
                            alertMessage = "Failed to change password: \(error.localizedDescription)"
                            isSuccess = false
                            showAlert = true
                        }
                    }
                }) {
                    Text("Update Password")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(universalAccentColor)
                        .cornerRadius(10)
                }
            }
            .padding()
            
            Spacer()
        }
        .background(universalBackgroundColor)
        .navigationBarHidden(true)
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(isSuccess ? "Success" : "Error"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK")) {
                    if isSuccess {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            )
        }
    }
}
