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

	fileprivate func ProfilePic() -> some View {
		// TODO: make profile picture editable
		Group{
			if (userAuth.isLoggedIn) {
				if let pfpUrl = userAuth.profilePicUrl{
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
					HStack{
						InputFieldView(
							label: "First Name",
							text: Binding(
								get: { userAuth.givenName ?? editedFirstName
								},
								set: { editedFirstName = $0})
						)
						InputFieldView(label: "Last Name", text: Binding(get: { userAuth.familyName ?? editedLastName}, set: { editedLastName = $0}))
					}
					InputFieldView(label: "Username", text: Binding(get: { editedUsername}, set: { editedUsername = $0}))
				}
				.padding(.horizontal, 32)

				HStack {
					Spacer()
					NavigationLink(destination: {
						FeedView(user: observableUser.user)
							.navigationBarTitle("")
							.navigationBarHidden(true)
					}) {
						Text("Enter Spawn >")
							.font(.system(size: 20, weight: .semibold))
							.foregroundColor(.white)
					}
					.simultaneousGesture(
						TapGesture().onEnded {
							Task{
								await userAuth.spawnSignIn(username: editedUsername, profilePicture: editedProfilePicture, firstName: editedFirstName, lastName: editedLastName)
							}
						})
				}
				.padding(.horizontal, 32)
				Spacer()
				Spacer()
				Spacer()
				Spacer()
			}
			.onAppear {
				editedFirstName = userAuth.givenName ?? ""
				editedLastName = userAuth.familyName ?? ""
				editedProfilePicture = userAuth.profilePicUrl ?? ""
			}
			.padding()
			.background(Color(hex: "#8693FF"))
			.ignoresSafeArea()
		}
	}
}

struct InputFieldView: View {
	var label: String

	@Binding var text: String

	var body: some View {
		VStack(alignment: .leading, spacing: 4) {
			Text(label)
				.font(.system(size: 18))
				.foregroundColor(.white)

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
