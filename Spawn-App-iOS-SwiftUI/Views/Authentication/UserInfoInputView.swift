//
//  UserInfoInputView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2024-12-30.
//

import SwiftUI

struct UserInfoInputView: View {
	@StateObject var userAuth = UserAuthViewModel.shared

	@State private var editedProfilePicture: String = ""  // TODO: use this variable meaningfully, instead of just grabbing from user auth view model

	// Validation flags
	@State private var isFirstNameValid: Bool = true
	@State private var isUsernameValid: Bool = true

	@State private var isFormValid: Bool = false

	@State private var username: String = ""

	@State private var email: String = ""
	@State private var isEmailValid: Bool = true

	fileprivate func ProfilePic() -> some View {
		Group {
			if userAuth.isLoggedIn, let pfpUrl = userAuth.profilePicUrl {
				AsyncImage(url: URL(string: pfpUrl)) { image in
					image
						.ProfileImageModifier(imageType: .profilePage)
				} placeholder: {
					Circle()
						.fill(Color.gray)
						.frame(width: 150, height: 150)
				}
			} else {
				Circle()
					.fill(.gray)
					.frame(width: 150, height: 150)
			}
		}
	}

	var body: some View {
		NavigationStack {
			VStack(spacing: 16) {
				if let unwrappedSpawnUser = userAuth.spawnUser {
					NavigationLink(
						destination: FeedView(user: unwrappedSpawnUser)
							.navigationBarTitle("")
							.navigationBarHidden(true),
						isActive: $userAuth.shouldNavigateToFeedView
					) {
						EmptyView()
					}
					.hidden()
				}

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
								get: { userAuth.givenName ?? "" },
								set: { userAuth.givenName = $0 }
							),
							isValid: $isFirstNameValid
						)
						InputFieldView(
							label: "Last Name",
							text: Binding(
								get: { userAuth.familyName ?? "" },
								set: { userAuth.familyName = $0 }
							),
							isValid: .constant(true)
						)
					}
					if userAuth.authProvider == .apple
						&& userAuth.email == nil
					{
						InputFieldView(
							label: "Email",
							text: $email,
							isValid: $isEmailValid
						)
					}
					InputFieldView(
						label: "Username",
						text: $username,
						isValid: $isUsernameValid
					)
				}
				.padding(.horizontal, 32)

				Button(action: {
					validateFields()  // Perform field validation
					if isFirstNameValid && isUsernameValid
						&& (!needsEmail || isEmailValid)
					{
						Task {
							await userAuth.spawnMakeUser(
								username: username,
								profilePicture: userAuth.profilePicUrl ?? "",
								firstName: userAuth.givenName ?? "",
								lastName: userAuth.familyName ?? "",
								email: userAuth.authProvider == .apple
									? email : userAuth.email ?? ""
							)
						}
						userAuth.isFormValid = true
					}
					userAuth.setShouldNavigateToFeedView()
				}) {
					HStack {
						Text("Enter Spawn")
							.font(.system(size: 20, weight: .semibold))

						Image(systemName: "arrow.right")
							.resizable()
							.frame(width: 20, height: 20)
					}
					.foregroundColor(.white)
				}
				.padding(.horizontal, 32)
				Spacer()
				Spacer()
				Spacer()
				Spacer()
			}
			.onAppear {
				userAuth.objectWillChange.send()  // Trigger initial UI update
				Task {
					await userAuth.spawnFetchUserIfAlreadyExists()
				}
				userAuth.setShouldNavigateToFeedView()
			}
			.padding()
			.background(authPageBackgroundColor)
			.ignoresSafeArea()
		}
	}

	private var needsEmail: Bool {
		return userAuth.authProvider == .apple && userAuth.email == nil
	}

	private func validateFields() {
		isFirstNameValid = !(userAuth.givenName ?? "").trimmingCharacters(
			in: .whitespaces
		).isEmpty
		isUsernameValid = !username.trimmingCharacters(in: .whitespaces).isEmpty
		if needsEmail {
			isEmailValid =
				!email.trimmingCharacters(in: .whitespaces).isEmpty
				&& email.contains("@")  // Simple email validation
		}
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

				if !isValid {
					Image(systemName: "star.fill")
						.foregroundColor(.red)
						.font(.system(size: 12))
				}
			}

			TextField("", text: $text)
				.padding()
				.background(.white)
				.cornerRadius(universalRectangleCornerRadius)
				.foregroundColor(.black)
		}
	}
}

@available(iOS 17.0, *)
#Preview {
	UserInfoInputView()
}
