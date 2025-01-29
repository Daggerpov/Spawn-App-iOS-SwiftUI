//
//  LaunchView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2024-12-30.
//

import SwiftUI
import GoogleSignInSwift
import GoogleSignIn

struct LaunchView: View {
	@StateObject var viewModel: LaunchViewModel = LaunchViewModel(
		apiService: MockAPIService.isMocking ? MockAPIService() : APIService())
	@StateObject var userAuth = UserAuthViewModel.shared

	fileprivate func SignOutButton() -> Button<Text> {
		Button(action: {
			userAuth.signOut()
		}) {
			Text("Sign Out")
		}
	}

	var body: some View {
		NavigationStack {
			VStack(spacing: 16) {
				Spacer()
				Image("spawn_launch_logo")
					.resizable()
					.scaledToFit()
					.frame(width: 300, height: 300)

				NavigationLink(destination:
					getAuthNavDestinationView()
						.navigationBarTitle("")
						.navigationBarHidden(true)
				, isActive: $userAuth.hasCheckedSpawnUserExistance) {
					AuthProviderButtonView(authProviderType: .google)
				}
				.simultaneousGesture(
					TapGesture().onEnded {
						if !userAuth.isLoggedIn {
							userAuth.signIn()
							Task{
								await userAuth.spawnFetchUserIfAlreadyExists()
							}
						}
					})

				// TODO: implement later
//				NavigationLink(destination: {
//					UserInfoInputView()
//						.navigationBarTitle("")
//						.navigationBarHidden(true)
//				}) {
//					AuthProviderButtonView(authProviderType: .apple)
//				}
				// TODO: implement later
//				.simultaneousGesture(
//					TapGesture().onEnded {
//						loginWithApple()
//					})
				Spacer()
			}
			.background(Color(hex: "#8693FF"))
			.ignoresSafeArea()
			.onAppear {
				User.setupFriends()
			}
		}
	}

	private func loginWithApple() {
		// TODO: implement later
	}

	private func getAuthNavDestinationView() -> AnyView {
		if let loggedInSpawnUser = userAuth.spawnUser {
			return AnyView(FeedView(user: loggedInSpawnUser))
		} else {
			return AnyView(UserInfoInputView())
		}
	}
}

#Preview {
	LaunchView()
}

