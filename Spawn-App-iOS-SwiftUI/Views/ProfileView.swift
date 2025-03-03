//
//  ProfileView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/9/24.
//

import SwiftUI

struct ProfileView: View {
	// TODO DANIEL: make a real API call here, using a new view model -> for editing bio and maybe other user details
	let user: UserDTO
	@State private var bio: String
	@State private var editingState: ProfileEditText = .edit

	@StateObject var userAuth = UserAuthViewModel.shared

	init(user: UserDTO) {
		self.user = user
		bio = user.bio ?? ""
	}

	var body: some View {
		NavigationStack {
			VStack {
				VStack(alignment: .center, spacing: 20) {
					Spacer()
					// Profile Picture

					if let profilePictureString = user.profilePicture {
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
							}
						}
					} else {
						Image(systemName: "person.crop.circle.fill")
							.ProfileImageModifier(imageType: .profilePage)
					}

					Circle()
						.fill(profilePicPlusButtonColor)
						.frame(width: 30, height: 30)
						.overlay(
							Image(systemName: "plus")
								.foregroundColor(universalBackgroundColor)
						)
						.offset(x: 45, y: -45)

					VStack(alignment: .leading, spacing: 25) {
						ProfileField(
							label: "Name",
							value:
								"\(user.firstName ?? "") \(user.lastName ?? "")"
						)
						ProfileField(label: "Username", value: user.username)
						ProfileField(label: "Email", value: user.email)
						BioField(
							label: "Bio",
							bio: Binding(
								get: { bio },
								set: { bio = $0 }
							))
					}
					.padding(.horizontal)

					Spacer()
					Divider().background(universalAccentColor)
					Spacer()

					Button(action: {
						switch editingState {
						case .edit:
							editingState = .save
						case .save:
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
					.padding(.horizontal)

					Spacer()
					Spacer()
					Spacer()
					Spacer()

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

					Spacer()
				}
				.padding()
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
