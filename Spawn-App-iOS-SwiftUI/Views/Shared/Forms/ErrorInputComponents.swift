//
//  ErrorInputComponents.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Assistant on 2025-01-09.
//

import SwiftUI

// MARK: - Error Input Field Styling
struct ErrorInputField: View {
    let placeholder: String
    @Binding var text: String
    let hasError: Bool
    let errorMessage: String?
    let isSecure: Bool
    
    init(placeholder: String, text: Binding<String>, hasError: Bool = false, errorMessage: String? = nil, isSecure: Bool = false) {
        self.placeholder = placeholder
        self._text = text
        self.hasError = hasError
        self.errorMessage = errorMessage
        self.isSecure = isSecure
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Input field with error styling
            HStack(spacing: 10) {
                if isSecure {
                    SecureField(placeholder, text: $text)
                        .font(Font.custom("Onest", size: 16).weight(.medium))
                        .foregroundColor(Color(red: 0.11, green: 0.11, blue: 0.11))
                } else {
                    TextField(placeholder, text: $text)
                        .font(Font.custom("Onest", size: 16).weight(.medium))
                        .foregroundColor(Color(red: 0.11, green: 0.11, blue: 0.11))
                }
            }
            .padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
            .frame(height: 63)
            .background(Color(hex: colorsGrayInput))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .inset(by: 1)
                    .stroke(hasError ? Color(red: 0.99, green: 0.31, blue: 0.30) : Color.clear, lineWidth: 1)
            )
            
            // Error message
            if hasError, let errorMessage = errorMessage {
                ErrorMessageView(message: errorMessage)
            }
        }
    }
}

// MARK: - Error Message View
struct ErrorMessageView: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 8) {
            // Error icon
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 12))
                .foregroundColor(Color(red: 0.92, green: 0.26, blue: 0.21))
            
            // Error message text
            Text(message)
                .font(Font.custom("Onest", size: 14).weight(.medium))
                .foregroundColor(Color(red: 0.92, green: 0.26, blue: 0.21))
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding(.leading, 16)
    }
}

// MARK: - Custom Phone Number Input
struct PhoneNumberInputField: View {
    @Binding var phoneNumber: String
    let hasError: Bool
    let errorMessage: String?
    @FocusState private var isPhoneFieldFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Phone number input field
            HStack(spacing: 10) {
                Text("+1")
                    .font(Font.custom("Onest", size: 16).weight(.medium))
                    .foregroundColor(Color(red: 0.11, green: 0.11, blue: 0.11))
                
                TextField("778-100-1000", text: $phoneNumber)
                    .font(Font.custom("Onest", size: 16).weight(.medium))
                    .foregroundColor(Color(red: 0.11, green: 0.11, blue: 0.11))
                    .keyboardType(.numberPad)
                    .focused($isPhoneFieldFocused)
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("Done") {
                                isPhoneFieldFocused = false
                                // Force dismiss keyboard for number pad
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            }
                            .font(.onestMedium(size: 16))
                            .foregroundColor(.blue)
                        }
                    }
                    .onSubmit {
                        isPhoneFieldFocused = false
                    }
            }
            .padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
            .frame(height: 63)
            .background(Color(hex: colorsGrayInput))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .inset(by: 1)
                    .stroke(hasError ? Color(red: 0.99, green: 0.31, blue: 0.30) : Color.clear, lineWidth: 1)
            )
            
            // Error message
            if hasError, let errorMessage = errorMessage {
                ErrorMessageView(message: errorMessage)
            }
        }
    }
}

// MARK: - Input Field Validation States
struct InputFieldState {
    var hasError: Bool = false
    var errorMessage: String? = nil
    
    mutating func setError(_ message: String) {
        hasError = true
        errorMessage = message
    }
    
    mutating func clearError() {
        hasError = false
        errorMessage = nil
    }
}

// MARK: - Input Field Validation Helper
extension View {
    func validateInput(condition: Bool, errorMessage: String, state: Binding<InputFieldState>) -> some View {
        self.onChange(of: condition) { _, isValid in
            if !isValid {
                state.wrappedValue.setError(errorMessage)
            } else {
                state.wrappedValue.clearError()
            }
        }
    }
} 