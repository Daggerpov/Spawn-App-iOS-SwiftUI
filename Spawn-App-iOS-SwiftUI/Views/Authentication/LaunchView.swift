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
	@StateObject var userAuth: UserAuthViewModel =  UserAuthViewModel(apiService: MockAPIService.isMocking ? MockAPIService() : APIService())

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

				NavigationLink(destination: {
					UserInfoInputView()
						.navigationBarTitle("")
						.navigationBarHidden(true)
				}) {
					AuthProviderButtonView(authProviderType: .google)
				}
				.simultaneousGesture(
					TapGesture().onEnded {
						if !userAuth.isLoggedIn {
							userAuth.signIn()
						}
					})

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
	}

	private func loginWithApple() {
		// TODO: implement later
	}
}

#Preview {
	LaunchView()
}

