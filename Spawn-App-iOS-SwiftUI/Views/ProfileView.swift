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
			VStack {
				VStack(alignment: .center, spacing: 16) {
					// Profile Picture
					ZStack(alignment: .bottomTrailing) {
						if let selectedImage = selectedImage {
							Image(uiImage: selectedImage)
								.ProfileImageModifier(imageType: .profilePage)
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
					.padding(.top, 20)
					.sheet(isPresented: $showImagePicker) {
						ImagePicker(selectedImage: $selectedImage)
					}

					VStack(alignment: .leading, spacing: 20) {
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
					.padding(.vertical, 10)

					Divider().background(universalAccentColor)
						.padding(.vertical, 10)

					// Only show edit button for current user's profile
					if isCurrentUserProfile {
						Button(action: {
							switch editingState {
							case .edit:
								editingState = .save
							case .save:
								Task {
									// Update profile info first
									await userAuth.spawnEditProfile(
										username: username,
										firstName: firstName,
										lastName: lastName,
										bio: bio
									)
									
									// Update profile picture if selected
									if let newImage = selectedImage {
										await userAuth.updateProfilePicture(newImage)
										// Don't clear selectedImage so it keeps showing in the UI
									}
								}
								editingState = .edit
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
						.padding(.bottom, 20)
					}

					Spacer()

					// Only show log out and delete account buttons for current user's profile
					if isCurrentUserProfile {
						VStack(spacing: 15) {
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
						.padding(.bottom, 30)
					}
				}
				.padding(.horizontal)
			}
			.background(universalBackgroundColor)
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
