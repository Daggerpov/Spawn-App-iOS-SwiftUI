//
//  LaunchView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2024-12-30.
//

import SwiftUI

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
					AuthProviderButtonView(authProviderType: .google)
				}.simultaneousGesture(
					TapGesture().onEnded {
						loginWithGoogle()
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
		.environmentObject(observableUser)
	}

	private func loginWithGoogle() {
		guard
			let url = URL(
				string: APIService.baseURL + "/oauth2/authorization/google")
		else {
			print("Invalid URL")
			return
		}
		UIApplication.shared.open(url)
	}

	private func loginWithApple() {
		// TODO: implement later
	}
}

#Preview {
	LaunchView()
}
