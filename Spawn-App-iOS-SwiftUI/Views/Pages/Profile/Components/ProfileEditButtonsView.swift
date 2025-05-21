//
//  ProfileEditButtonsView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Lee on 11/09/24.
//

import SwiftUI

struct ProfileEditButtonsView: View {
    @Binding var editingState: ProfileEditText
    let onCancel: () -> Void
    let onSave: () -> Void
    let isImageLoading: Bool
    
    var body: some View {
        HStack(spacing: 20) {
            // Cancel Button
            Button(action: onCancel) {
                Text("Cancel")
                    .font(.headline)
                    .foregroundColor(universalAccentColor)
                    .frame(maxWidth: 135)
                    .padding()
                    .background(
                        RoundedRectangle(
                            cornerRadius: universalRectangleCornerRadius
                        )
                        .stroke(universalAccentColor, lineWidth: 1)
                    )
            }

            // Save Button
            Button(action: onSave) {
                Text("Save")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: 135)
                    .padding()
                    .background(
                        RoundedRectangle(
                            cornerRadius: universalRectangleCornerRadius
                        )
                        .fill(profilePicPlusButtonColor)
                    )
            }
            .disabled(isImageLoading)
        }
    }
}

#Preview {
    ProfileEditButtonsView(
        editingState: .constant(.save),
        onCancel: {},
        onSave: {},
        isImageLoading: false
    )
} 