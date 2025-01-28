//
//  UserInfoInputView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2024-12-30.
//

import SwiftUI

struct UserInfoInputView: View {
	@EnvironmentObject var observableUser: ObservableUser

	@StateObject var userAuth: UserAuthViewModel = UserAuthViewModel(apiService: MockAPIService.isMocking ? MockAPIService() : APIService())

	@State private var editedFirstName: String = ""
	@State private var editedLastName: String = ""
	@State private var editedUsername: String = ""
	@State private var editedProfilePicture: String = "" // TODO: use this variable meaningfully, instead of just grabbing from user auth view model

	// Validation flags
	@State private var isFirstNameValid: Bool = true
	@State private var isUsernameValid: Bool = true

	@State private var isNavigationActive: Bool = false

	fileprivate func ProfilePic() -> some View {
		// TODO: make profile picture editable
		Group {
			if userAuth.isLoggedIn {
				if let pfpUrl = userAuth.profilePicUrl {
					AsyncImage(url: URL(string: pfpUrl))
						.frame(width: 100, height: 100)
				} else {
					Circle()
						.fill(.white)
						.frame(width: 100, height: 100)
				}
			} else {
				Circle()
					.fill(.white)
					.frame(width: 100, height: 100)
			}
		}
	}

	var body: some View {
		NavigationStack {
			VStack(spacing: 16) {
				Spacer()
				Spacer()

				Text("Help your friends recognize you")
					.font(.system(size: 30, weight: .semibold))
					.foregroundColor(.white)
					.multilineTextAlignment(.center)

				Spacer()

				ZStack {
					ProfilePic()

					Circle()
						.fill(.black)
						.frame(width: 24, height: 24)
						.overlay(
							Image(systemName: "plus")
								.foregroundColor(.white)
								.font(.system(size: 12, weight: .bold))
						)
						.offset(x: 35, y: 35)
				}

				Spacer()

				VStack(spacing: 16) {
					HStack {
						InputFieldView(
							label: "First Name",
							text: Binding(
								get: { editedFirstName },
								set: { editedFirstName = $0 }
							),
							isValid: $isFirstNameValid
						)
						InputFieldView(label: "Last Name", text: Binding(get: { editedLastName }, set: { editedLastName = $0 }), isValid: .constant(true))
					}
					InputFieldView(
						label: "Username",
						text: Binding(get: { editedUsername }, set: { editedUsername = $0 }),
						isValid: $isUsernameValid
					)
				}
				.padding(.horizontal, 32)

				HStack {
					Spacer()
					NavigationLink(
						destination: FeedView(user: observableUser.user)
							.navigationBarTitle("")
							.navigationBarHidden(true),
						isActive: $isNavigationActive
					) {
						Text("Enter Spawn >")
							.font(.system(size: 20, weight: .semibold))
							.foregroundColor(.white)
					}

					.simultaneousGesture(
						TapGesture().onEnded {
							validateFields() // Perform field validation
							if isFirstNameValid && isUsernameValid {
								Task {
									await userAuth.spawnSignIn(
										username: editedUsername,
										profilePicture: editedProfilePicture,
										firstName: editedFirstName,
										lastName: editedLastName
									)
									isNavigationActive = true // Activate navigation only if valid
								}
							}
						}
					)
				}
				.padding(.horizontal, 32)
				Spacer()
				Spacer()
				Spacer()
				Spacer()
			}
			.onAppear {
				populateFields() // Populate fields initially
			}
			.onReceive(userAuth.objectWillChange) { _ in
				populateFields() // Populate fields whenever userAuth updates
			}
			.padding()
			.background(Color(hex: "#8693FF"))
			.ignoresSafeArea()
		}
	}

	private func validateFields() {
		isFirstNameValid = !editedFirstName.trimmingCharacters(in: .whitespaces).isEmpty
		isUsernameValid = !editedUsername.trimmingCharacters(in: .whitespaces).isEmpty
	}

	private func populateFields() {
		// Dynamically update state variables from userAuth
		editedFirstName = userAuth.givenName ?? ""
		editedLastName = userAuth.familyName ?? ""
		editedProfilePicture = userAuth.profilePicUrl ?? ""
	}
}

struct InputFieldView: View {
	var label: String
	@Binding var text: String
	@Binding var isValid: Bool

	var body: some View {
		VStack(alignment: .leading, spacing: 4) {
			HStack {
				Text(label)
					.font(.system(size: 18))
					.foregroundColor(.white)

				if !isValid {
					Image(systemName: "star.fill")
						.foregroundColor(.red)
						.font(.system(size: 12))
				}
			}

			TextField("", text: $text)
				.padding()
				.background(Color.white)
				.cornerRadius(universalRectangleCornerRadius)
		}
	}
}


#Preview {
	UserInfoInputView()
}
