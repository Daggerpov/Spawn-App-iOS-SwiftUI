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
		NavigationStack(path: Binding(
			get: {
				if userAuth.navigationState != .none {
					return NavigationPath([userAuth.navigationState])
				}
				return NavigationPath()
			},
			set: { (path: NavigationPath) in
				if path.isEmpty {
					userAuth.navigationState = .none
				}
			}
		)) {
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
							.progressViewStyle(CircularProgressViewStyle(tint: universalAccentColor(from: themeService, environment: colorScheme)))
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
			.navigationBarHidden(true)
			// Main navigation destinations using new NavigationState system
			.navigationDestination(for: NavigationState.self) { state in
				switch state {
				case .welcome:
					LaunchView()
				case .signIn:
					SignInView()
						.onAppear {
							userAuth.resetAuthFlow()
						}
				case .register:
					RegisterInputView()
						.onAppear {
							userAuth.resetAuthFlow()
						}
				case .loginInput:
					SignInView()
				case .accountNotFound:
					AccountNotFoundView()
						.navigationBarTitle("")
						.navigationBarHidden(true)
				case .onboardingContinuation:
					OnboardingContinuationView()
				case .userDetailsInput(let isOAuthUser):
					UserDetailsInputView(isOAuthUser: isOAuthUser)
						.navigationBarTitle("")
						.navigationBarHidden(true)
				case .userOptionalDetailsInput:
					UserOptionalDetailsInputView()
				case .contactImport:
					ContactImportView()
				case .userTermsOfService:
					UserToS()
				case .phoneNumberInput:
					UserDetailsInputView(isOAuthUser: false)
				case .verificationCode:
					VerificationCodeView(viewModel: userAuth)
				case .feedView:
					if let loggedInSpawnUser = userAuth.spawnUser {
						ContentView(user: loggedInSpawnUser)
							.navigationBarTitle("")
							.navigationBarHidden(true)
					} else {
						EmptyView() // This should never happen
					}
				case .none:
					EmptyView()
				}
			}
			// Legacy navigation destinations for backward compatibility
			.navigationDestination(
				isPresented: $userAuth.shouldNavigateToUserInfoInputView
			) {
				UserInfoInputView()
					.navigationBarTitle("")
					.navigationBarHidden(true)
			}
			.navigationDestination(isPresented: $userAuth.shouldSkipAhead) {
				switch userAuth.skipDestination {
				case .userDetailsInput:
					UserDetailsInputView(isOAuthUser: true)
				case .userOptionalDetailsInput:
					UserOptionalDetailsInputView()
				case .contactImport:
					ContactImportView()
				case .userToS:
					UserToS()
				case .none:
					EmptyView()
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
