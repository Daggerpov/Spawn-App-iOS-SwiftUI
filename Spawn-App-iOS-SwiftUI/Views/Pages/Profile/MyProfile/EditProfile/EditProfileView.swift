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
						maxInterests: maxInterests
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
			let currentName = await MainActor.run {
				userAuth.spawnUser.flatMap { FormatterService.shared.formatName(user: $0) } ?? ""
			}
			let currentUsername = await MainActor.run { userAuth.spawnUser?.username ?? "" }
			if username != currentUsername || name != currentName {
				let errorMessage = await userAuth.spawnEditProfile(
					username: username,
					name: name
				)
				if let errorMessage {
					await MainActor.run {
						isSaving = false
						InAppNotificationService.shared.showErrorMessage(
							errorMessage,
							title: "Profile Update Failed"
						)
					}
					return
				}
				await MainActor.run { userAuth.objectWillChange.send() }
				await userAuth.fetchUserData()
			}

			let formattedWhatsapp = FormatterService.shared.formatWhatsAppLink(whatsappLink)
			let formattedInstagram = FormatterService.shared.formatInstagramLink(instagramLink)
			let newWhatsapp = formattedWhatsapp.isEmpty ? nil : formattedWhatsapp
			let newInstagram = formattedInstagram.isEmpty ? nil : formattedInstagram
			let oldWhatsapp = profileViewModel.userSocialMedia?.whatsappNumber
			let oldInstagram = profileViewModel.userSocialMedia?.instagramUsername
			let socialMediaChanged =
				(newWhatsapp ?? "") != (oldWhatsapp ?? "") || (newInstagram ?? "") != (oldInstagram ?? "")

			if socialMediaChanged {
				await profileViewModel.updateSocialMedia(
					userId: userId,
					whatsappLink: newWhatsapp,
					instagramLink: newInstagram
				)
			}

			await saveInterestChanges()

			try? await Task.sleep(nanoseconds: 500_000_000)

			if let newImage = selectedImage {
				await userAuth.updateProfilePicture(newImage)
				await ProfilePictureCache.shared.removeCachedImage(for: userId)
			}

			await profileViewModel.loadAllProfileData(userId: userId)

			if let spawnUser = userAuth.spawnUser {
				print("Updated profile: \(spawnUser.name ?? "Unknown"), @\(spawnUser.username ?? "unknown")")
				await MainActor.run {
					userAuth.objectWillChange.send()
				}
			}

			await MainActor.run {
				isSaving = false
				InAppNotificationService.shared.showSuccess(.profileUpdated)
				presentationMode.wrappedValue.dismiss()
			}
		}
	}

	private func saveInterestChanges() async {
		let currentInterests = profileViewModel.userInterests
		let changed = Set(currentInterests) != Set(profileViewModel.originalUserInterests)
		guard changed else { return }

		let success = await profileViewModel.replaceAllInterests(userId: userId, interests: currentInterests)
		if success {
			await MainActor.run {
				profileViewModel.originalUserInterests = profileViewModel.userInterests
			}
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
