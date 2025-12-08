//
//  ProfileEditButtonsView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/9/24.
//

import SwiftUI

struct ProfileEditButtonsView: View {
	let user: Nameable
	@ObservedObject var userAuth = UserAuthViewModel.shared
	var profileViewModel: ProfileViewModel

	@Binding var editingState: ProfileEditText
	@Binding var username: String
	@Binding var name: String
	@Binding var selectedImage: UIImage?
	@Binding var whatsappLink: String
	@Binding var instagramLink: String
	@Binding var isImageLoading: Bool

	var saveProfile: () async -> Void

	var body: some View {
		HStack(spacing: 20) {
			// Cancel Button
			Button(action: {
				// Revert to original values from userAuth.spawnUser
				if let currentUser = userAuth.spawnUser {
					username = currentUser.username ?? ""
					name = currentUser.name ?? ""
					selectedImage = nil

					// Revert social media links
					if let socialMedia = profileViewModel.userSocialMedia {
						whatsappLink = socialMedia.whatsappLink ?? ""
						instagramLink = socialMedia.instagramLink ?? ""
					}
				}

				// Restore original interests
				profileViewModel.restoreOriginalInterests()

				editingState = .edit
			}) {
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
			Button(action: {
				Task {
					await saveProfile()
				}
			}) {
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
		user: BaseUserDTO.danielAgapov,
		profileViewModel: ProfileViewModel(userId: UUID()),
		editingState: .constant(.save),
		username: .constant("johndoe"),
		name: .constant("John Doe"),
		selectedImage: .constant(nil),
		whatsappLink: .constant(""),
		instagramLink: .constant(""),
		isImageLoading: .constant(false),
		saveProfile: {}
	)
}
