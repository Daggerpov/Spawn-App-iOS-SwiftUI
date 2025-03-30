//
//  ProfileView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/9/24.
//

import SwiftUI
import PhotosUI

struct ProfileView: View {
	let user: BaseUserDTO
	@State private var bio: String
	@State private var username: String
	@State private var firstName: String
	@State private var lastName: String
	@State private var editingState: ProfileEditText = .edit
	@State private var selectedImage: UIImage?
	@State private var showImagePicker: Bool = false
	@State private var isImageLoading: Bool = false
	@Environment(\.presentationMode) private var presentationMode
	@Environment(\.dismiss) private var dismiss

	@StateObject var userAuth = UserAuthViewModel.shared
	
	// Check if this is the current user's profile
	private var isCurrentUserProfile: Bool {
		guard let currentUser = userAuth.spawnUser else { return false }
		return currentUser.id == user.id
	}

	init(user: BaseUserDTO) {
		self.user = user
		bio = user.bio ?? ""
		username = user.username
		firstName = user.firstName ?? ""
		lastName = user.lastName ?? ""
	}

	var body: some View {
		NavigationStack {
			ScrollView {
				VStack(alignment: .center, spacing: 10) {
					// Profile Picture
					ProfilePictureSection(
						user: user,
						selectedImage: $selectedImage,
						showImagePicker: $showImagePicker,
						isImageLoading: $isImageLoading,
						isEditing: editingState == .save,
						isCurrentUserProfile: isCurrentUserProfile
					)
					.padding(.top, 5)

					// Profile information fields
					ProfileInfoSection(
						user: user,
						bio: $bio,
						username: $username,
						firstName: $firstName,
						lastName: $lastName,
						isCurrentUserProfile: isCurrentUserProfile,
						editingState: editingState
					)
					.padding(.horizontal)
					.padding(.vertical, 6)

					Divider().background(universalAccentColor)
						.padding(.vertical, 6)

					// Edit/Save/Cancel buttons
					if isCurrentUserProfile {
						ProfileEditButtonsSection(
							editingState: $editingState,
							bio: $bio,
							username: $username,
							firstName: $firstName,
							lastName: $lastName,
							selectedImage: $selectedImage,
							isImageLoading: $isImageLoading,
							userAuth: userAuth
						)
						.padding(.bottom, 10)
					}

					Spacer()

					// Bottom buttons
					if isCurrentUserProfile && editingState == .edit {
						ProfileActionButtonsSection(
							user: user,
							userAuth: userAuth
						)
						.padding(.bottom, 20)
					}
				}
				.padding(.horizontal)
				.padding(.top, 0)
			}
			.background(universalBackgroundColor.ignoresSafeArea())
			.navigationBarBackButtonHidden()
			.toolbarBackground(universalBackgroundColor, for: .navigationBar)
			.toolbar {
				ToolbarItem(placement: .principal) {
					Text("Profile")
						.font(.headline)
						.foregroundColor(universalAccentColor)
				}
				ToolbarItem(placement: .navigationBarLeading) {
					Button(action: {
						dismiss()
					}) {
						HStack {
							Image(systemName: "chevron.left")
							Text("Back")
						}
						.foregroundColor(universalAccentColor)
					}
					// Only show back button when in a navigation hierarchy
					.opacity(presentationMode.wrappedValue.isPresented ? 1 : 0)
				}
			}
			.alert(item: $userAuth.activeAlert) { alertType in
				switch alertType {
				case .deleteConfirmation:
					return Alert(
						title: Text("Delete Account"),
						message: Text(
							"Are you sure you want to delete your account? This action cannot be undone."
						),
						primaryButton: .destructive(Text("Delete")) {
							Task {
								await userAuth.deleteAccount()
							}
						},
						secondaryButton: .cancel()
					)
				case .deleteSuccess:
					return Alert(
						title: Text("Account Deleted"),
						message: Text(
							"Your account has been successfully deleted."),
						dismissButton: .default(Text("OK")) {
							userAuth.signOut()
						}
					)
				case .deleteError:
					return Alert(
						title: Text("Error"),
						message: Text(
							"Failed to delete your account. Please try again later."
						),
						dismissButton: .default(Text("OK"))
					)
				}
			}
			.onAppear {
				// Update local state from userAuth.spawnUser when view appears
				if isCurrentUserProfile, let currentUser = userAuth.spawnUser {
					bio = currentUser.bio ?? ""
					username = currentUser.username
					firstName = currentUser.firstName ?? ""
					lastName = currentUser.lastName ?? ""
				}
			}
			.onChange(of: userAuth.spawnUser) { newUser in
				// Update local state whenever spawnUser changes
				if isCurrentUserProfile, let currentUser = newUser {
					bio = currentUser.bio ?? ""
					username = currentUser.username
					firstName = currentUser.firstName ?? ""
					lastName = currentUser.lastName ?? ""
				}
			}
		}
		.accentColor(universalAccentColor)
	}
}

// MARK: - Profile Picture Section
struct ProfilePictureSection: View {
	let user: BaseUserDTO
	@Binding var selectedImage: UIImage?
	@Binding var showImagePicker: Bool
	@Binding var isImageLoading: Bool
	let isEditing: Bool
	let isCurrentUserProfile: Bool
	
	var body: some View {
		ZStack(alignment: .bottomTrailing) {
			if isImageLoading {
				ProgressView()
					.frame(width: 150, height: 150)
			} else if let selectedImage = selectedImage {
				Image(uiImage: selectedImage)
					.ProfileImageModifier(imageType: .profilePage)
					.transition(.opacity)
					.id("selectedImage-\(UUID().uuidString)")
					.onAppear {
						print("🔶 Displaying selected image with hash: \(selectedImage.hashValue)")
					}
			} else if let profilePictureString = user.profilePicture {
				if MockAPIService.isMocking {
					Image(profilePictureString)
						.ProfileImageModifier(imageType: .profilePage)
				} else {
					AsyncImage(url: URL(string: profilePictureString)) { phase in
						switch phase {
						case .empty:
							ProgressView()
								.frame(width: 150, height: 150)
						case .success(let image):
							image
								.ProfileImageModifier(imageType: .profilePage)
								.transition(.opacity.animation(.easeInOut))
						case .failure:
							Image(systemName: "person.crop.circle.fill")
								.ProfileImageModifier(imageType: .profilePage)
						@unknown default:
							Image(systemName: "person.crop.circle.fill")
								.ProfileImageModifier(imageType: .profilePage)
						}
					}
					.id("profilePicture-\(profilePictureString)")
				}
			} else {
				Image(systemName: "person.crop.circle.fill")
					.ProfileImageModifier(imageType: .profilePage)
			}

			// Only show the plus button for current user's profile when in edit mode
			if isCurrentUserProfile && isEditing {
				Circle()
					.fill(profilePicPlusButtonColor)
					.frame(width: 25, height: 25)
					.overlay(
						Image(systemName: "plus")
							.foregroundColor(universalBackgroundColor)
					)
					.offset(x: -10, y: -10)
					.onTapGesture {
						print("🔍 Opening image picker...")
						showImagePicker = true
					}
			}
		}
		.animation(.easeInOut, value: selectedImage != nil)
		.animation(.easeInOut, value: isImageLoading)
		.sheet(isPresented: $showImagePicker, onDismiss: {
			print("🔍 Image picker dismissed, selectedImage: \(selectedImage != nil ? "exists" : "nil")")
			// Only show loading if we actually have a new image
			if selectedImage != nil {
				DispatchQueue.main.async {
					isImageLoading = true
					DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
						isImageLoading = false
					}
				}
			}
		}) {
			SwiftUIImagePicker(selectedImage: $selectedImage)
				.ignoresSafeArea()
		}
		.onChange(of: selectedImage) { newImage in
			print("🔍 selectedImage binding changed to: \(newImage != nil ? "new image" : "nil")")
			if newImage != nil {
				// Force UI update when image changes
				DispatchQueue.main.async {
					print("🔍 Profile image changed, updating UI...")
					isImageLoading = true
					DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
						isImageLoading = false
						print("🔍 Profile image loading complete")
					}
				}
			}
		}
		.id("profilePicture-\(selectedImage != nil ? "selected" : "none")-\(isImageLoading ? "loading" : "ready")")
	}
}

// MARK: - Profile Information Section
struct ProfileInfoSection: View {
	let user: BaseUserDTO
	@Binding var bio: String
	@Binding var username: String
	@Binding var firstName: String
	@Binding var lastName: String
	let isCurrentUserProfile: Bool
	let editingState: ProfileEditText
	
	var body: some View {
		VStack(alignment: .leading, spacing: 14) {
			// Name field
			if isCurrentUserProfile && editingState == .save {
				HStack {
					Text("First Name")
						.font(.headline)
						.frame(width: 100, alignment: .leading)
					Spacer()
					TextField("First Name", text: $firstName)
						.multilineTextAlignment(.trailing)
						.font(.body)
				}
				.foregroundColor(universalAccentColor)
				
				HStack {
					Text("Last Name")
						.font(.headline)
						.frame(width: 100, alignment: .leading)
					Spacer()
					TextField("Last Name", text: $lastName)
						.multilineTextAlignment(.trailing)
						.font(.body)
				}
				.foregroundColor(universalAccentColor)
			} else {
				ProfileField(
					label: "Name",
					value: "\(user.firstName ?? "") \(user.lastName ?? "")"
				)
			}
			
			// Username field - editable when in edit mode
			if isCurrentUserProfile && editingState == .save {
				HStack {
					Text("Username")
						.font(.headline)
						.frame(width: 100, alignment: .leading)
					Spacer()
					TextField("Username", text: $username)
						.multilineTextAlignment(.trailing)
						.font(.body)
				}
				.foregroundColor(universalAccentColor)
			} else {
				ProfileField(label: "Username", value: user.username)
			}
			
			// Only show email for current user's profile
			if isCurrentUserProfile {
				ProfileField(label: "Email", value: user.email)
			}
			
			// Bio field is editable only for current user's profile
			if isCurrentUserProfile {
				if editingState == .save {
					BioField(
						label: "Bio",
						bio: $bio)
				} else {
					ProfileField(label: "Bio", value: bio)
				}
			} else {
				ProfileField(label: "Bio", value: bio)
			}
		}
	}
}

// MARK: - Profile Edit Buttons Section
struct ProfileEditButtonsSection: View {
	@Binding var editingState: ProfileEditText
	@Binding var bio: String
	@Binding var username: String
	@Binding var firstName: String
	@Binding var lastName: String
	@Binding var selectedImage: UIImage?
	@Binding var isImageLoading: Bool
	let userAuth: UserAuthViewModel
	
	var body: some View {
		if editingState == .save {
			HStack(spacing: 20) {
				// Cancel Button
				Button(action: {
					// Revert to original values from userAuth.spawnUser
					if let currentUser = userAuth.spawnUser {
						username = currentUser.username
						firstName = currentUser.firstName ?? ""
						lastName = currentUser.lastName ?? ""
						bio = currentUser.bio ?? ""
						selectedImage = nil
					}
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
					saveProfile()
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
		} else {
			Button(action: {
				print("🔍 Starting profile edit mode")
				editingState = .save
			}) {
				Text("Edit")
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
		}
	}
	
	private func saveProfile() {
		print("🔍 Saving profile changes...")
		
		// Set loading state immediately if there's an image
		isImageLoading = selectedImage != nil
		
		Task {
			// Create a local copy of the selected image before starting async task
			let imageToUpload = selectedImage
			
			// Update profile info first
			print("🔍 Updating profile text information...")
			print("Updating profile with: username=\(username), firstName=\(firstName), lastName=\(lastName), bio=\(bio)")
			await userAuth.spawnEditProfile(
				username: username,
				firstName: firstName,
				lastName: lastName,
				bio: bio
			)
			
			// Small delay before processing image update to ensure the text updates are complete
			try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
			
			// Update profile picture if selected
			if let newImage = imageToUpload {
				print("🔍 Uploading new profile picture...")
				await userAuth.updateProfilePicture(newImage)
				
				// Small delay after image upload to ensure the server has processed it
				try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
			}
			
			// Update local state with the latest data from the user object
			await MainActor.run {
				if let updatedUser = userAuth.spawnUser {
					username = updatedUser.username
					firstName = updatedUser.firstName ?? ""
					lastName = updatedUser.lastName ?? ""
					bio = updatedUser.bio ?? ""
				}
				
				// Clear the selected image to force the view to refresh from the server
				selectedImage = nil
				isImageLoading = false
				editingState = .edit
			}
		}
	}
}

// MARK: - Profile Action Buttons Section
struct ProfileActionButtonsSection: View {
	let user: BaseUserDTO
	let userAuth: UserAuthViewModel
	
	var body: some View {
		VStack(spacing: 15) {
			// Notification Settings Button
			NavigationLink(destination: NotificationSettingsView()) {
				HStack {
					Image(systemName: "bell.fill")
						.foregroundColor(.white)
					Text("Notifications")
						.font(.headline)
						.foregroundColor(.white)
				}
				.padding()
				.frame(maxWidth: 170)
				.background(universalAccentColor)
				.cornerRadius(20)
			}
			
			// Feedback Button
			NavigationLink(destination: FeedbackView(userId: user.id, email: user.email)) {
				HStack {
					Image(systemName: "message.fill")
						.foregroundColor(.white)
					Text("Feedback")
						.font(.headline)
						.foregroundColor(.white)
				}
				.padding()
				.frame(maxWidth: 170)
				.background(universalAccentColor)
				.cornerRadius(20)
			}
		
			NavigationLink(destination: {
				LaunchView()
					.navigationBarTitle("")
					.navigationBarHidden(true)
			}) {
				Text("Log Out")
					.font(.headline)
					.foregroundColor(.white)
					.padding()
					.frame(maxWidth: 170)
					.background(profilePicPlusButtonColor)
					.cornerRadius(20)
			}
			.simultaneousGesture(
				TapGesture().onEnded {
					if userAuth.isLoggedIn {
						userAuth.signOut()
					}
				})

			// Delete Account Button
			Button(action: {
				userAuth.activeAlert = .deleteConfirmation
			}) {
				Text("Delete Account")
					.font(.headline)
					.foregroundColor(.white)
					.padding()
					.frame(maxWidth: 170)
					.background(Color.red)
					.cornerRadius(20)
			}
		}
	}
}

struct ProfileField: View {
	let label: String
	let value: String

	var body: some View {
		HStack {
			Text(label)
				.font(.headline)
				.frame(width: 100, alignment: .leading)
			Spacer()
			Text(value)
				.font(.body)
				.multilineTextAlignment(.trailing)
		}
		.foregroundColor(universalAccentColor)
	}
}

struct BioField: View {
	let label: String
	@Binding var bio: String

	var body: some View {
		HStack {
			Text(label)
				.font(.headline)
				.frame(width: 80, alignment: .leading)
			Spacer()
			TextField(
				"",
				text: $bio,
				prompt: Text("Bio")
			)
			.multilineTextAlignment(.trailing)
			.font(.body)
		}
		.foregroundColor(universalAccentColor)
	}
}

#Preview {
	ProfileView(user: BaseUserDTO.danielAgapov)
}
