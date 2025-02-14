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
					isActive: $userAuth.hasCheckedSpawnUserExistence
				) {
					AuthProviderButtonView(authProviderType: .google)
				}
				.simultaneousGesture(
					TapGesture().onEnded {
						if !userAuth.isLoggedIn {
							userAuth.signInWithGoogle()
							Task {
								await userAuth.spawnFetchUserIfAlreadyExists()
							}
						}
					})

				SignInWithAppleButton(.signUp) { request in
					request.requestedScopes = [.fullName, .email]
				} onCompletion: { result in
					userAuth.handleAppleSignInResult(result)
				}
				.frame(height: 50)
				.frame(maxWidth: .infinity)
				.cornerRadius(8)
				.foregroundColor(.white)
				.background(
					RoundedRectangle(cornerRadius: universalRectangleCornerRadius)
						.fill(.black)
				)
				.padding(.horizontal, 32)
				Spacer()
			}
			.background(Color(hex: "#8693FF"))
			.ignoresSafeArea()
			.onAppear {
				User.setupFriends()
			}
		}
	}

	private func getAuthNavDestinationView() -> AnyView {
		if userAuth.shouldNavigateToUserInfoInputView {
			return AnyView(UserInfoInputView())
		} else if let loggedInSpawnUser = userAuth.spawnUser {
			return AnyView(FeedView(user: loggedInSpawnUser))
		} else {
			return AnyView(EmptyView()) // Fallback, though this should not happen
		}
	}
}

#Preview {
	LaunchView()
}
