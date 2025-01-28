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

	@State private var editedProfilePicture: String = "" // TODO: use this variable meaningfully, instead of just grabbing from user auth view model

	// Validation flags
	@State private var isFirstNameValid: Bool = true
	@State private var isUsernameValid: Bool = true

	@State private var isNavigationActive: Bool = false

	@State private var username: String = ""

	fileprivate func ProfilePic() -> some View {
		Group {
			if userAuth.isLoggedIn {
				if let pfpUrl = userAuth.profilePicUrl {
					AsyncImage(url: URL(string: pfpUrl)) { image in
						image
							.ProfileImageModifier(imageType: .profilePage)
					} placeholder: {
						Circle()
							.fill(Color.gray)
					}
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
					InputFieldView(
						label: "Username",
						text: $username,
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
										username: username,
										profilePicture: userAuth.profilePicUrl ?? "",
										firstName: userAuth.givenName ?? "",
										lastName: userAuth.familyName ?? ""
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
				userAuth.objectWillChange.send() // Trigger initial UI update
			}
			.padding()
			.background(Color(hex: "#8693FF"))
			.ignoresSafeArea()
		}
	}

	private func validateFields() {
		isFirstNameValid = !(userAuth.givenName ?? "").trimmingCharacters(in: .whitespaces).isEmpty
		isUsernameValid = !(username)
			.trimmingCharacters(in: .whitespaces).isEmpty
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

@available(iOS 17.0, *)
#Preview {
	@Previewable
	@StateObject var observableUser = ObservableUser(user: .danielLee)

	UserInfoInputView()
		.environmentObject(observableUser)
}
