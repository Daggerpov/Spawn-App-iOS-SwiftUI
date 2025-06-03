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
    
    // Show/hide password toggles
    @State private var showCurrentPassword = false
    @State private var showNewPassword = false
    @State private var showConfirmPassword = false
    
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
                // Current Password field with toggle
                HStack {
                    Group {
                        if showCurrentPassword {
                            TextField("Current Password", text: $currentPassword)
                        } else {
                            SecureField("Current Password", text: $currentPassword)
                        }
                    }
                    .padding()
                    .foregroundColor(universalAccentColor)
                    .font(.subheadline)
                    
                    Button(action: {
                        showCurrentPassword.toggle()
                    }) {
                        Image(systemName: showCurrentPassword ? "eye.slash" : "eye")
                            .foregroundColor(universalAccentColor)
                    }
                    .padding(.trailing)
                }
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(
                        cornerRadius: universalNewRectangleCornerRadius
                    )
                    .stroke(universalAccentColor, lineWidth: 1)
                )
                
                // New Password field with toggle
                HStack {
                    Group {
                        if showNewPassword {
                            TextField("New Password", text: $newPassword)
                        } else {
                            SecureField("New Password", text: $newPassword)
                        }
                    }
                    .padding()
                    .foregroundColor(universalAccentColor)
                    .font(.subheadline)
                    
                    Button(action: {
                        showNewPassword.toggle()
                    }) {
                        Image(systemName: showNewPassword ? "eye.slash" : "eye")
                            .foregroundColor(universalAccentColor)
                    }
                    .padding(.trailing)
                }
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(
                        cornerRadius: universalNewRectangleCornerRadius
                    )
                    .stroke(universalAccentColor, lineWidth: 1)
                )
                
                // Confirm Password field with toggle
                HStack {
                    Group {
                        if showConfirmPassword {
                            TextField("Confirm New Password", text: $confirmPassword)
                        } else {
                            SecureField("Confirm New Password", text: $confirmPassword)
                        }
                    }
                    .padding()
                    .foregroundColor(universalAccentColor)
                    .font(.subheadline)
                    
                    Button(action: {
                        showConfirmPassword.toggle()
                    }) {
                        Image(systemName: showConfirmPassword ? "eye.slash" : "eye")
                            .foregroundColor(universalAccentColor)
                    }
                    .padding(.trailing)
                }
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

@available(iOS 17.0, *)
#Preview {
    ChangePasswordView()
}

