//
//  TutorialActivityPreConfirmationView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Assistant on 1/21/25.
//

import SwiftUI

struct TutorialActivityPreConfirmationView: View {
	let activityType: String
	let onContinue: () -> Void
	let onCancel: () -> Void

	@Environment(\.colorScheme) var colorScheme
	@State private var isVisible = false
	@ObservedObject private var tutorialViewModel = TutorialViewModel.shared

	private var adaptiveBackgroundColor: Color {
		colorScheme == .dark ? Color(red: 0.13, green: 0.13, blue: 0.13) : Color.white
	}

	private var adaptiveTextColor: Color {
		colorScheme == .dark ? Color.white : Color.black
	}

	/// Convert activity type to proper English phrase
	private var activityPhrase: String {
		switch activityType.lowercased() {
		case "food", "eat":
			return "eat"
		case "chill":
			return "chill"
		case "active", "gym":
			return "get active"
		case "study":
			return "study"
		default:
			return "do \(activityType.lowercased())"
		}
	}

	/// Generate the appropriate message based on whether user has friends
	private var tutorialMessage: String {
		if tutorialViewModel.userHasFriends() {
			return "You're about to \(activityPhrase), who do you want to let know?"
		} else {
			return "You're about to \(activityPhrase)! Let's set this up."
		}
	}

	var body: some View {
		ZStack {
			// Semi-transparent background
			Color.black.opacity(0.6)
				.ignoresSafeArea()
				.onTapGesture {
					// Allow tapping outside to continue
					withAnimation(.easeInOut(duration: 0.3)) {
						isVisible = false
					}
					Task { @MainActor in
						try? await Task.sleep(for: .seconds(0.3))
						onContinue()
					}
				}

			// Popup content
			VStack(spacing: 24) {
				// Title
				Text(tutorialMessage)
					.font(.onestSemiBold(size: 22))
					.foregroundColor(adaptiveTextColor)
					.multilineTextAlignment(.center)
					.padding(.horizontal, 24)

				// Instruction text
				Text("*Tap anywhere to continue*")
					.font(.onestMedium(size: 16))
					.foregroundColor(adaptiveTextColor.opacity(0.7))
					.padding(.bottom, 8)
			}
			.padding(.vertical, 32)
			.padding(.horizontal, 24)
			.background(
				RoundedRectangle(cornerRadius: 20)
					.fill(adaptiveBackgroundColor)
					.shadow(
						color: Color.black.opacity(0.2),
						radius: 20,
						x: 0,
						y: 10
					)
			)
			.padding(.horizontal, 32)
			.scaleEffect(isVisible ? 1.0 : 0.8)
			.opacity(isVisible ? 1.0 : 0.0)
		}
		.onAppear {
			withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
				isVisible = true
			}
		}
	}
}

#Preview {
	TutorialActivityPreConfirmationView(
		activityType: "Chill",
		onContinue: {},
		onCancel: {}
	)
}
