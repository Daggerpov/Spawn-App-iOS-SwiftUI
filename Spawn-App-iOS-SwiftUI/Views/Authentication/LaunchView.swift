//
//  LaunchView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2024-12-30.
//

import SwiftUI
import GoogleSignInSwift
import GoogleSignIn

import UIKit

func getRootViewController() -> UIViewController? {
	guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
		  let rootViewController = windowScene.windows.first?.rootViewController else {
		return nil
	}
	return rootViewController
}

struct LaunchView: View {
	@StateObject var viewModel: LaunchViewModel = LaunchViewModel(
		apiService: MockAPIService.isMocking ? MockAPIService() : APIService())
	@StateObject var observableUser: ObservableUser = ObservableUser(
		user: .danielAgapov)

	var body: some View {
		NavigationStack {
			VStack(spacing: 16) {
				Spacer()
				Image("spawn_launch_logo")
					.resizable()
					.scaledToFit()
					.frame(width: 300, height: 300)

				NavigationLink(destination: {
					UserInfoInputView()
						.navigationBarTitle("")
						.navigationBarHidden(true)
				}) {
					GoogleSignInButton {
						if let rootViewController = getRootViewController() {
							GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { signInResult, error in
//								if let error = error as? NSError {
//									if error.code == GIDSignInErrorCode.canceled.rawValue {
//										print("Sign-In was canceled by the user.")
//									} else {
//										print("Google Sign-In Error: \(error.localizedDescription)")
//									}
//									return
//								}

								// Handle successful sign-in
								if let user = signInResult?.user {
									print("Signed in as: \(user.profile?.name ?? "Unknown")")
								}
							}
						} else {
							print("Unable to find root view controller for sign-in.")
						}
					}
				}
//				.simultaneousGesture(
//					TapGesture().onEnded {
//						loginWithGoogle()
//					})

				NavigationLink(destination: {
					UserInfoInputView()
						.navigationBarTitle("")
						.navigationBarHidden(true)
				}) {
					AuthProviderButtonView(authProviderType: .apple)
				}
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
		.environmentObject(observableUser)
	}

	private func loginWithApple() {
		// TODO: implement later
	}
}

#Preview {
	LaunchView()
}
