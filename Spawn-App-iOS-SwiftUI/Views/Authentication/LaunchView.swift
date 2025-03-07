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
	let notificationCenter = UNUserNotificationCenter.current()

	var body: some View {
		NavigationStack {
			VStack(spacing: 16) {
				Spacer()
				Image("spawn_launch_logo")
					.resizable()
					.scaledToFit()
					.frame(width: 300, height: 300)

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

				// Add a button for explicit notification permission
				Button(action: {
					requestNotificationPermission()
				}) {
					Text("Enable Notifications")
						.foregroundColor(.white)
						.padding()
						.frame(maxWidth: .infinity)
						.background(Color.blue)
						.cornerRadius(10)
				}
				.padding(.horizontal, 32)
				.padding(.top, 16)

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
		.onAppear {
			// Request notification permissions when the view appears
			requestNotificationPermission()
		}
	}

	private func requestNotificationPermission() {
		Task {
			do {
				try await notificationCenter.requestAuthorization(options: [.alert, .badge, .sound])
				print("Notification permission granted")
			} catch {
				print("Failed to request notification permission: \(error.localizedDescription)")
			}
		}
	}

	private func getAuthNavDestinationView() -> some View {
		Group {
			if userAuth.shouldNavigateToUserInfoInputView {
				UserInfoInputView()
			} else if let loggedInSpawnUser = userAuth.spawnUser {
				FeedView(user: loggedInSpawnUser)
			} else {
				// Fallback: Stay on LaunchView
				EmptyView()
			}
		}
	}
}

#Preview {
	LaunchView()
}
