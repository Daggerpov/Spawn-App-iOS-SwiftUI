//
//  OnboardingButton.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Shane on 7/1/25.
//

import SwiftUI

struct OnboardingButtonStyle: ButtonStyle {
	func makeBody(configuration: Configuration) -> some View {
		configuration.label
			.scaleEffect(configuration.isPressed ? 0.95 : 1.0)
			.animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
	}
}

/// Onboarding button that uses centralized navigation through UserAuthViewModel
struct OnboardingButtonView: View {
	let buttonText: String
	let navigationState: NavigationState
	@ObservedObject private var userAuth = UserAuthViewModel.shared

	init(_ buttonText: String, navigateTo navigationState: NavigationState) {
		self.buttonText = buttonText
		self.navigationState = navigationState
	}

	var body: some View {
		Button(action: {
			print("🔘 DEBUG: '\(buttonText)' button tapped")
			// Unified haptic feedback
			HapticFeedbackService.shared.medium()

			// Use centralized navigation system
			userAuth.navigateTo(navigationState)
		}) {
			OnboardingButtonCoreView(buttonText)
		}
		.buttonStyle(OnboardingButtonStyle())
		.onAppear {
			print("🔘 DEBUG: OnboardingButtonView appeared with text: '\(buttonText)'")
		}
	}
}

#Preview {
	OnboardingButtonView("Get Started", navigateTo: .spawnIntro)
}
