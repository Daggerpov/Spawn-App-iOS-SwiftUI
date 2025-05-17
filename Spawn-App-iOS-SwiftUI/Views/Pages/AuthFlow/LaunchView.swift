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
import UserNotifications // Add this import for notifications

struct LaunchView: View {
	@StateObject var userAuth = UserAuthViewModel.shared

	var body: some View {
		NavigationStack {
			VStack(spacing: 16) {
				Spacer()
				Image("spawn_new_logo")
					.resizable()
					.scaledToFit()
					.frame(width: 200, height: 100)
                Image("spontaneity_made_easy")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300, height: 100)
                Spacer().frame(height: 32)

				// Google Sign-In Button
				Button(action: {
					Task {
						await userAuth.signInWithGoogle()
					}
				}) {
					AuthProviderButtonView(authProviderType: .google)
				}

				// Apple Sign-In Button
				Button(action: {
					userAuth.signInWithApple()
				}) {
					AuthProviderButtonView(authProviderType: .apple)
				}

				Spacer()
			}
			.background(authPageBackgroundColor)
			.ignoresSafeArea()
			.navigationDestination(
				isPresented: $userAuth.hasCheckedSpawnUserExistence
			) {
				getAuthNavDestinationView()
					.navigationBarTitle("")
					.navigationBarHidden(true)
			}
		}
	}

	private func getAuthNavDestinationView() -> some View {
		Group {
			if userAuth.shouldNavigateToUserInfoInputView {
				UserInfoInputView()
			} else if let loggedInSpawnUser = userAuth.spawnUser {
				ContentView(user: loggedInSpawnUser)
			} else {
				// Fallback: Stay on LaunchView
				EmptyView()
			}
		}
	}
}

@available(iOS 17, *)
#Preview {
    @Previewable @StateObject var appCache = AppCache.shared
	LaunchView().environmentObject(appCache)
}
