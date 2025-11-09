//
//  SignInView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Shane on 7/1/25.
//

import SwiftUI

struct SignInView: View {
	@ObservedObject var themeService = ThemeService.shared
	@Environment(\.colorScheme) var colorScheme
	@ObservedObject private var userAuth = UserAuthViewModel.shared

	var body: some View {
		ZStack {
			// Background
			universalBackgroundColor(from: themeService, environment: colorScheme)
				.ignoresSafeArea()

			VStack(spacing: 0) {
				Spacer()

				// Logo
				Image("SpawnLogo")
					.resizable()
					.scaledToFit()
					.frame(width: 120)
					.padding(.top, 24)
					.padding(.bottom, 80)

				// Main content
				GetInTextView()
					.padding(.horizontal, 40)

				Spacer()

				// Buttons
				VStack {
					// Create Account Button
					Button(action: {
						print("🔘 DEBUG: Create Account button tapped")
						// Haptic feedback
						let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
						impactGenerator.impactOccurred()

						// Use auth navigation system
						userAuth.navigateTo(.register)
					}) {
						OnboardingButtonCoreView("Create an Account") {
							figmaIndigo
						}
					}
					.buttonStyle(OnboardingButtonStyle())
					.padding(.bottom, -16)

					// Log in text
					HStack(spacing: 4) {
						Text("Have an account already?")
							.font(.onestRegular(size: 14))
							.foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))

						Button(action: {
							print("🔘 DEBUG: Log in button tapped")
							// Haptic feedback
							HapticFeedbackService.shared.medium()

							// Use auth navigation system
							userAuth.navigateTo(.loginInput)
						}) {
							Text("Log in")
								.font(.onestSemiBold(size: 14))
								.foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
								.underline()
						}
					}
				}
				.padding(.horizontal, 16)
				.padding(.bottom, 60)
			}
			.padding(.horizontal)
		}
		.background(universalBackgroundColor(from: themeService, environment: colorScheme))
		.ignoresSafeArea(.all)
		.navigationBarHidden(true)
		.onAppear {
			// Clear any previous error state when returning to main auth screen
			userAuth.clearAllErrors()
		}
	}
}

// Preview
#Preview {
	SignInView()
}
