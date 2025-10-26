//
//  ErrorInputComponents.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Assistant on 2025-01-09.
//

import SwiftUI

// MARK: - All component views have been moved to separate files in ErrorInputComponents/
// - ErrorInputField.swift
// - ErrorMessageView.swift
// - PhoneNumberInputField.swift
// - InputFieldState.swift

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
