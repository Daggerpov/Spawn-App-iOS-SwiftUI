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
	@ObservedObject var themeService = ThemeService.shared
	@Environment(\.colorScheme) var colorScheme
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
						.frame(width: 300, height: 300)
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
                            await userAuth.loginWithGoogle()
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
			.background(universalBackgroundColor(from: themeService, environment: colorScheme))
			.navigationBarHidden(true)
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
