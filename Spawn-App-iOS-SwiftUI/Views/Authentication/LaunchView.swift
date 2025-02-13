//
//  LaunchView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2024-12-30.
//

import AuthenticationServices  // apple auth
import GoogleSignIn
import GoogleSignInSwift
import SwiftUI

struct LaunchView: View {
	@StateObject var userAuth = UserAuthViewModel.shared

	var body: some View {
		NavigationStack {
			VStack(spacing: 16) {
				Spacer()
				Image("spawn_launch_logo")
					.resizable()
					.scaledToFit()
					.frame(width: 300, height: 300)

				NavigationLink(
					destination:
						getAuthNavDestinationView()
						.navigationBarTitle("")
						.navigationBarHidden(true),
					isActive: $userAuth.hasCheckedSpawnUserExistance
				) {
					AuthProviderButtonView(authProviderType: .google)
				}
				.simultaneousGesture(
					TapGesture().onEnded {
						if !userAuth.isLoggedIn {
							userAuth.signIn()
							Task {
								await userAuth.spawnFetchUserIfAlreadyExists()
							}
						}
					})

				SignInWithAppleButton(.signUp) { request in
					// authorization request for an Apple ID
					request.requestedScopes = [.email, .fullName]
				} onCompletion: { result in
					// completion handler that is called when the sign-in completes
				}

				NavigationLink(
					destination:
						getAuthNavDestinationView()
						.navigationBarTitle("")
						.navigationBarHidden(true),
					isActive: $userAuth.hasCheckedSpawnUserExistance
				) {
					AuthProviderButtonView(authProviderType: .apple)
				}
				.simultaneousGesture(
					TapGesture().onEnded {
						if !userAuth.isLoggedIn {
							userAuth.signIn()
							Task {
								await userAuth.spawnFetchUserIfAlreadyExists()
							}
						}
					})
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
