//
//  WelcomeView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Shane on 7/1/25.
//

import SwiftUI

struct WelcomeView: View {
	@State private var animationCompleted = false
	@ObservedObject var themeService = ThemeService.shared
	@Environment(\.colorScheme) var colorScheme
	@ObservedObject private var userAuth = UserAuthViewModel.shared
	@State private var path = NavigationPath()

	var body: some View {
		NavigationStack(path: $path) {
			VStack {
				Spacer()
				if !animationCompleted {
					// Initial Rive animation for new users
					RiveAnimationView.logoAnimation(fileName: "spawn_logo_animation")
						.frame(width: 300, height: 300)
						.task {
							// Show content after animation completes
							try? await Task.sleep(for: .seconds(2.0))
							withAnimation(.easeInOut(duration: 0.5)) {
								animationCompleted = true
							}
						}
				} else {
					Spacer()
					Spacer()
					Spacer()
					Spacer()
					Spacer()
					// Static logo after animation
					Image("SpawnLogo")
						.scaledToFit()
						.transition(.opacity)
						.padding(.bottom, 12)
				}

				if animationCompleted {
					Text("Spontaneity made easy.")
						.font(.onestRegular(size: 20))
						.foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
						.transition(.opacity)

					// Skip onboarding for returning users
					if userAuth.hasCompletedOnboarding {
						Button(action: {
							// Haptic feedback
							let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
							impactGenerator.impactOccurred()

							// Use auth navigation system
							userAuth.navigateTo(.signIn)
						}) {
							OnboardingButtonCoreView("Get Started") {
								figmaIndigo
							}
						}
						.buttonStyle(OnboardingButtonStyle())
						.padding(.bottom, 12)
						.transition(.opacity)
					} else {
						Spacer()
						Button(action: {
							// Haptic feedback
							let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
							impactGenerator.impactOccurred()

							userAuth.getStarted()

						}) {
							OnboardingButtonCoreView("Get Started") {
								figmaIndigo
							}
						}
						.buttonStyle(OnboardingButtonStyle())
						.padding(.top, 12)
						.transition(.opacity)
					}
				}

				Spacer()
			}
			.background(universalBackgroundColor(from: themeService, environment: colorScheme))
			.ignoresSafeArea(.all)
			.onReceive(userAuth.$navigationState) { state in
				if state == .none {
					path = NavigationPath()
				} else {
					path.append(state)
				}

			}
			.withAuthNavigation(userAuth)
		}
	}
}

#Preview {
	WelcomeView()
}
