import PhotosUI
import SwiftUI

struct EditProfileView: View {
	@Environment(\.presentationMode) var presentationMode
	@ObservedObject var userAuth = UserAuthViewModel.shared
	var profileViewModel: ProfileViewModel

	@State private var name: String
	@State private var username: String
	@State private var selectedImage: UIImage?
	@State private var showImagePicker: Bool = false
	@State private var isImageLoading: Bool = false
	@State private var newInterest: String = ""
	@State private var whatsappLink: String
	@State private var instagramLink: String
	@State private var isSaving: Bool = false
	@State private var showAlert: Bool = false
	@State private var alertMessage: String = ""

	// User ID to edit
	let userId: UUID

	// Maximum number of interests allowed
	private let maxInterests = 7

	init(userId: UUID, profileViewModel: ProfileViewModel) {
		self.userId = userId
		self.profileViewModel = profileViewModel

		var initialName = ""

		// Use a local variable to get the name
		if let spawnUser = UserAuthViewModel.shared.spawnUser {
			initialName = FormatterService.shared.formatName(user: spawnUser)
		}
		let initialUsername = UserAuthViewModel.shared.spawnUser?.username ?? ""

		// Initialize with raw values instead of links
		let initialWhatsapp = profileViewModel.userSocialMedia?.whatsappNumber ?? ""
		let initialInstagram = profileViewModel.userSocialMedia?.instagramUsername ?? ""

		_name = State(initialValue: initialName)
		_username = State(initialValue: initialUsername)
		_whatsappLink = State(initialValue: initialWhatsapp)
		_instagramLink = State(initialValue: initialInstagram)
	}

	var body: some View {
		VStack(spacing: 0) {
			// Custom Header with Cancel and Save buttons
			HStack {
				// Cancel Button
				Button("Cancel") {
					// Restore original interests
					profileViewModel.restoreOriginalInterests()
					presentationMode.wrappedValue.dismiss()
				}
				.font(.system(size: 16, weight: .medium))
				.foregroundColor(figmaBittersweetOrange)
				.padding(.horizontal, 16)
				.padding(.vertical, 8)
				.background(
					RoundedRectangle(cornerRadius: 8)
						.stroke(figmaBittersweetOrange, lineWidth: 1)
				)

				Spacer()

				// Title
				Text("Edit Profile")
					.font(.system(size: 18, weight: .semibold))
					.foregroundColor(universalAccentColor)

				Spacer()

				// Save Button
				Button("Save") {
					saveProfile()
				}
				.font(.system(size: 16, weight: .medium))
				.foregroundColor(isSaving ? .gray : .white)
				.padding(.horizontal, 16)
				.padding(.vertical, 8)
				.background(
					RoundedRectangle(cornerRadius: 8)
						.fill(isSaving ? Color.gray.opacity(0.3) : figmaSoftBlue)
				)
				.disabled(isSaving)
			}
			.padding(.horizontal, 16)
			.padding(.top, 8)
			.padding(.bottom, 16)
			.background(universalBackgroundColor)

			// Content
			ScrollView {
				VStack(alignment: .leading, spacing: 18) {
					// Profile picture section
					ProfileImageSection(
						selectedImage: $selectedImage,
						showImagePicker: $showImagePicker,
						isImageLoading: $isImageLoading
					)

					// Name and username fields
					PersonalInfoSection(
						name: $name,
						username: $username
					)

					// Interests section
					InterestsSection(
						profileViewModel: profileViewModel,
						userId: userId,
						newInterest: $newInterest,
						maxInterests: maxInterests,
						showAlert: $showAlert,
						alertMessage: $alertMessage
					)

					// Third party apps section
					SocialMediaSection(
						whatsappLink: $whatsappLink,
						instagramLink: $instagramLink
					)
				}
				.padding(.bottom, 120)  // Extra padding to scroll past tab bar
			}
			.scrollIndicators(.hidden)
		}
		.background(universalBackgroundColor)
		.navigationBarHidden(true)
		.navigationBarBackButtonHidden(true)
		.ignoresSafeArea(.keyboard, edges: .bottom)  // Prevent keyboard from pushing header up
		.sheet(isPresented: $showImagePicker) {
			SwiftUIImagePicker(selectedImage: $selectedImage)
				.ignoresSafeArea()
		}
		.alert(isPresented: $showAlert) {
			Alert(
				title: Text("Profile Update"),
				message: Text(alertMessage),
				dismissButton: .default(Text("OK"))
			)
		}
		.onAppear {
			// Save original interests for cancel functionality
			profileViewModel.saveOriginalInterests()

			// Update text fields with current social media data if available
			// This handles the case where data loads after view initialization
			if let socialMedia = profileViewModel.userSocialMedia {
				whatsappLink = socialMedia.whatsappNumber ?? ""
				instagramLink = socialMedia.instagramUsername ?? ""
			}
		}
		.onChange(of: profileViewModel.userSocialMedia) { _, newSocialMedia in
			// Update text fields whenever social media data changes
			if let socialMedia = newSocialMedia {
				whatsappLink = socialMedia.whatsappNumber ?? ""
				instagramLink = socialMedia.instagramUsername ?? ""
			}
		}
	}

	private func saveProfile() {
		isSaving = true

		Task {
			// Check if there's a new profile picture
			_ = selectedImage != nil

			// Update profile info first
			await userAuth.spawnEditProfile(
				username: username,
				name: name
			)

			// Force UI update by triggering objectWillChange
			await MainActor.run {
				userAuth.objectWillChange.send()
			}

			// Explicitly fetch updated user data
			await userAuth.fetchUserData()

			// Format social media links properly before saving
			let formattedWhatsapp = FormatterService.shared.formatWhatsAppLink(whatsappLink)
			let formattedInstagram = FormatterService.shared.formatInstagramLink(instagramLink)

			print("Saving whatsapp: \(formattedWhatsapp), instagram: \(formattedInstagram)")

			// Update social media links
			await profileViewModel.updateSocialMedia(
				userId: userId,
				whatsappLink: formattedWhatsapp.isEmpty ? nil : formattedWhatsapp,
				instagramLink: formattedInstagram.isEmpty ? nil : formattedInstagram
			)

			// Handle interest changes
			await saveInterestChanges()

			// Add an explicit delay and refresh to ensure data is properly updated
			try? await Task.sleep(nanoseconds: 500_000_000)  // 0.5 seconds delay

			// Specifically fetch social media again to ensure it's updated
			await profileViewModel.fetchUserSocialMedia(userId: userId)

			// Update profile picture if selected
			if let newImage = selectedImage {
				await userAuth.updateProfilePicture(newImage)
				// Invalidate the cached profile picture since we have a new one
				await ProfilePictureCache.shared.removeCachedImage(for: userId)
			}

			// Refresh all profile data
			await profileViewModel.loadAllProfileData(userId: userId)

			// Ensure the user object is fully refreshed
			if let spawnUser = userAuth.spawnUser {
				print("Updated profile: \(spawnUser.name ?? "Unknown"), @\(spawnUser.username ?? "unknown")")
				await MainActor.run {
					userAuth.objectWillChange.send()
				}
			}

			await MainActor.run {
				isSaving = false
				alertMessage = "Profile updated successfully"
				showAlert = true

				// Dismiss after a short delay
				Task { @MainActor in
					try? await Task.sleep(for: .seconds(1.5))
					presentationMode.wrappedValue.dismiss()
				}
			}
		}
	}

	private func saveInterestChanges() async {
		let currentInterests = Set(profileViewModel.userInterests)
		let originalInterests = Set(profileViewModel.originalUserInterests)

		// Find interests to add (in current but not in original)
		let interestsToAdd = currentInterests.subtracting(originalInterests)

		// Find interests to remove (in original but not in current)
		let interestsToRemove = originalInterests.subtracting(currentInterests)

		// Add new interests
		for interest in interestsToAdd {
			_ = await profileViewModel.addUserInterest(userId: userId, interest: interest)
		}

		// Remove old interests using the edit-specific method that handles 404 as success
		for interest in interestsToRemove {
			await profileViewModel.removeUserInterestForEdit(userId: userId, interest: interest)
		}

		// Update the original interests to match current state after saving
		await MainActor.run {
			profileViewModel.originalUserInterests = profileViewModel.userInterests
		}
	}
}

@available(iOS 17.0, *)
#Preview {
	@Previewable @State var profileViewModel = ProfileViewModel(
		userId: BaseUserDTO.danielAgapov.id,
		dataService: DataService.shared
	)

	EditProfileView(
		userId: BaseUserDTO.danielAgapov.id,
		profileViewModel: profileViewModel
	)
}
