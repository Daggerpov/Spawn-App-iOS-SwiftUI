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
    @Environment(\.dismiss) private var dismiss
    @State private var showAuthButtons = false
    @State private var animationCompleted = false

	var body: some View {
		NavigationStack {
			VStack(spacing: 16) {
				Spacer()
				
				if !animationCompleted {
					// Initial Rive animation for new users
					RiveAnimationView.logoAnimation(fileName: "spawn_logo_animation")
						.frame(width: 200, height: 200)
						.background(
							// Fallback to static logo if Rive fails
							Image("spawn_branding_logo")
								.resizable()
								.scaledToFit()
								.frame(width: 200, height: 100)
								.opacity(0) // Hidden when Rive is working
						)
						.onAppear {
							// Show auth buttons after animation completes
							DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
								withAnimation(.easeInOut(duration: 0.5)) {
									animationCompleted = true
									showAuthButtons = true
								}
							}
						}
				} else {
					// Static logo after animation
					Image("spawn_branding_logo")
						.resizable()
						.scaledToFit()
						.frame(width: 200, height: 100)
						.transition(.opacity)
				}
				
				if showAuthButtons {
					Image("spontaneity_made_easy")
						.resizable()
						.scaledToFit()
						.frame(width: 300, height: 100)
						.transition(.opacity)
					
					Spacer().frame(height: 32)
				}

				// Google Sign-In Button
				if showAuthButtons {
					Button(action: {
						Task {
							await userAuth.signInWithGoogle()
						}
					}) {
						AuthProviderButtonView(authProviderType: .google)
					}
					.transition(.opacity)

					// Apple Sign-In Button
					Button(action: {
						userAuth.signInWithApple()
					}) {
						AuthProviderButtonView(authProviderType: .apple)
					}
					.transition(.opacity)
				}

				Spacer()
			}
			.background(Color.white) // Changed from authPageBackgroundColor to white
			.ignoresSafeArea()
			.preferredColorScheme(.light)
			.navigationDestination(
				isPresented: $userAuth.shouldNavigateToUserInfoInputView
			) {
				UserInfoInputView()
					.navigationBarTitle("")
					.navigationBarHidden(true)
			}
			.navigationDestination(
				isPresented: $userAuth.shouldNavigateToFeedView
			) {
				if let loggedInSpawnUser = userAuth.spawnUser {
					ContentView(user: loggedInSpawnUser)
						.navigationBarTitle("")
						.navigationBarHidden(true)
				} else {
					EmptyView() // This should never happen
				}
			}
		}
	}
}

@available(iOS 17, *)
#Preview {
    @Previewable @StateObject var appCache = AppCache.shared
	LaunchView().environmentObject(appCache)
}
