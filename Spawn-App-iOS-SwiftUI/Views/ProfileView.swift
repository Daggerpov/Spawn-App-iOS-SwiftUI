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
					ZStack(alignment: .bottomTrailing) {
						if isImageLoading {
							ProgressView()
								.frame(width: 150, height: 150)
						} else if let selectedImage = selectedImage {
							Image(uiImage: selectedImage)
								.ProfileImageModifier(imageType: .profilePage)
								.transition(.opacity)
								.id("selectedImage") // Force refresh when image changes
						} else if let profilePictureString = user.profilePicture {
							if MockAPIService.isMocking {
								Image(profilePictureString)
									.ProfileImageModifier(imageType: .profilePage)
							} else {
								AsyncImage(url: URL(string: profilePictureString)) {
									image in
									image
										.ProfileImageModifier(
											imageType: .profilePage)
								} placeholder: {
									Circle()
										.fill(Color.gray)
										.frame(width: 150, height: 150)
								}
							}
						} else {
							Image(systemName: "person.crop.circle.fill")
								.ProfileImageModifier(imageType: .profilePage)
						}

						// Only show the plus button for current user's profile when in edit mode
						if isCurrentUserProfile && editingState == .save {
							Circle()
								.fill(profilePicPlusButtonColor)
								.frame(width: 25, height: 25)
								.overlay(
									Image(systemName: "plus")
										.foregroundColor(universalBackgroundColor)
								)
								.offset(x: -10, y: -10)
								.onTapGesture {
									showImagePicker = true
								}
						}
					}
					.padding(.top, 5)
					.sheet(isPresented: $showImagePicker, onDismiss: {
						print("Image picker dismissed. Selected image exists: \(selectedImage != nil)")
					}) {
						ImagePicker(selectedImage: $selectedImage)
							.ignoresSafeArea()
					}
					.onChange(of: selectedImage) { newImage in
						print("Selected image changed: \(newImage != nil)")
					}

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
					.padding(.horizontal)
					.padding(.vertical, 6)

					Divider().background(universalAccentColor)
						.padding(.vertical, 6)

					// Only show edit button for current user's profile
					if isCurrentUserProfile {
						Button(action: {
							switch editingState {
							case .edit:
								print("🔍 Starting profile edit mode")
								editingState = .save
							case .save:
								print("🔍 Saving profile changes...")
								print("🔍 Current values - username: \(username), firstName: \(firstName), lastName: \(lastName), bio: \(bio)")
								print("🔍 Has new image: \(selectedImage != nil)")
								
								isImageLoading = selectedImage != nil
								Task {
									// Create a local copy of the selected image before starting async task
									let imageToUpload = selectedImage
									
									// Update profile info first
									print("🔍 Updating profile text information...")
									await userAuth.spawnEditProfile(
										username: username,
										firstName: firstName,
										lastName: lastName,
										bio: bio
									)
									
									// Update profile picture if selected
									if let newImage = imageToUpload {
										print("🔍 Uploading new profile picture...")
										await userAuth.updateProfilePicture(newImage)
										print("🔍 Profile picture upload completed")
									}
									
									// Update local state with the latest data from the user object
									if let updatedUser = userAuth.spawnUser {
										print("🔍 Retrieved updated user data:")
										print("  - Username: \(updatedUser.username)")
										print("  - Name: \(updatedUser.firstName ?? "nil") \(updatedUser.lastName ?? "nil")")
										print("  - Bio: \(updatedUser.bio ?? "nil")")
										print("  - Profile Picture: \(updatedUser.profilePicture ?? "nil")")
										
										username = updatedUser.username
										firstName = updatedUser.firstName ?? ""
										lastName = updatedUser.lastName ?? ""
										bio = updatedUser.bio ?? ""
										
										// Force view update
										Task { @MainActor in
											print("🔍 Forcing UI refresh with updated data")
										}
									} else {
										print("❌ ERROR: Updated user data is nil after profile update")
									}
									
									isImageLoading = false
									editingState = .edit
									print("🔍 Profile edit complete")
								}
							}
						}) {
							Text(editingState.displayText())
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
						.padding(.bottom, 10)
						.disabled(isImageLoading)
					}

					Spacer()

					// Only show log out and delete account buttons for current user's profile
					if isCurrentUserProfile {
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
		}
		.accentColor(universalAccentColor)
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
