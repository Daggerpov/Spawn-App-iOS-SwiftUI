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
import UserNotifications  // Add this import for notifications

struct LaunchView: View {
	@ObservedObject var userAuth = UserAuthViewModel.shared
	@ObservedObject var themeService = ThemeService.shared
	@Environment(\.colorScheme) var colorScheme
	@Environment(\.dismiss) private var dismiss
	@State private var showAuthButtons = false
	@State private var animationCompleted = false
	@State private var navigationPath = NavigationPath()

	var body: some View {
		NavigationStack(path: $navigationPath) {
			VStack(spacing: 16) {
				Spacer()

				if !animationCompleted {
					// Initial Rive animation for new users
					RiveAnimationView.logoAnimation(fileName: "spawn_logo_animation")
						.frame(width: 300, height: 300)
						.task {
							// Show auth buttons after animation completes
							try? await Task.sleep(for: .seconds(2.0))
							withAnimation(.easeInOut(duration: 0.5)) {
								animationCompleted = true
								showAuthButtons = true
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
				if showAuthButtons && !userAuth.isAutoSigningIn {
					Button(action: {
						// Haptic feedback
						let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
						impactGenerator.impactOccurred()

						Task {
							await userAuth.googleRegister()
						}
					}) {
						AuthProviderButtonView(authProviderType: .google)
					}
					.buttonStyle(AuthProviderButtonStyle())
					.transition(.opacity)

					// Apple Sign-In Button
					Button(action: {
						// Haptic feedback
						let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
						impactGenerator.impactOccurred()

						userAuth.appleRegister()
					}) {
						AuthProviderButtonView(authProviderType: .apple)
					}
					.buttonStyle(AuthProviderButtonStyle())
					.transition(.opacity)
				}

				// Auto Sign-In Loading State
				if userAuth.isAutoSigningIn {
					VStack(spacing: 16) {
						ProgressView()
							.progressViewStyle(
								CircularProgressViewStyle(
									tint: universalAccentColor(from: themeService, environment: colorScheme))
							)
							.scaleEffect(1.2)

						Text("Account found! Signing you in...")
							.font(.onestMedium(size: 16))
							.foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
							.multilineTextAlignment(.center)
					}
					.padding(.horizontal, 40)
					.transition(.opacity)
				}

				Spacer()
			}
			.background(universalBackgroundColor(from: themeService, environment: colorScheme))
			.ignoresSafeArea(.all)
			.onAppear {
				print("🔄 DEBUG: LaunchView appeared")
			}
		}
		.withAuthNavigation(userAuth)
		.onReceive(userAuth.$navigationState) { newState in
			if newState != .none {
				navigationPath.append(newState)
				print("📍 DEBUG: Appending navigation state to path: \(newState.description)")
			} else {
				// Clear navigation path when state is reset to none
				navigationPath = NavigationPath()
				print("📍 DEBUG: Clearing navigation path")
			}
		}
	}
}

@available(iOS 17, *)
#Preview {
	@Previewable @ObservedObject var appCache = AppCache.shared
	LaunchView().environmentObject(appCache)
}
