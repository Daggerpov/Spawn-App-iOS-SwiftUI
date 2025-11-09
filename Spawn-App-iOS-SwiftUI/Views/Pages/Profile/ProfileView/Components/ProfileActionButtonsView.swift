//
//  ProfileActionButtonsView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/9/24.
//

import SwiftUI

struct ProfileActionButtonsView: View {
	var user: BaseUserDTO
	@ObservedObject var profileViewModel: ProfileViewModel
	@Environment(\.colorScheme) private var colorScheme
	var shareProfile: () -> Void

	// Animation states for 3D effect
	@State private var editButtonPressed = false
	@State private var editButtonScale: CGFloat = 1.0
	@State private var shareButtonPressed = false
	@State private var shareButtonScale: CGFloat = 1.0

	// Computed property for current user profile
	private var isCurrentUserProfile: Bool {
		guard let currentUser = UserAuthViewModel.shared.spawnUser else { return false }
		return currentUser.id == user.id
	}

	private var buttonBackgroundColor: Color {
		switch colorScheme {
		case .dark:
			return Color(red: 0.15, green: 0.15, blue: 0.15)
		case .light:
			return Color.white
		@unknown default:
			return Color.white
		}
	}

	var body: some View {
		HStack(spacing: 8) {
			if isCurrentUserProfile {
				NavigationLink(
					destination: EditProfileView(
						userId: user.id,
						profileViewModel: profileViewModel
					)
				) {
					HStack(spacing: 8) {
						Image(systemName: "pencil.circle")
						Text("Edit Profile")
							.font(.onestSemiBold(size: 12))
					}
					.bold()
					.font(.caption)
					.foregroundColor(universalSecondaryColor)
					.frame(height: 30)
					.frame(width: 128)
					.background(buttonBackgroundColor)
					.cornerRadius(12)
					.overlay(
						RoundedRectangle(cornerRadius: 12)
							.stroke(universalSecondaryColor, lineWidth: 2)
					)
					.scaleEffect(editButtonScale)
					.shadow(
						color: Color.black.opacity(0.15),
						radius: editButtonPressed ? 2 : 8,
						x: 0,
						y: editButtonPressed ? 2 : 4
					)
				}
				.navigationBarBackButtonHidden(true)
				.animation(.easeInOut(duration: 0.15), value: editButtonScale)
				.animation(.easeInOut(duration: 0.15), value: editButtonPressed)
				.onLongPressGesture(
					minimumDuration: 0, maximumDistance: .infinity,
					pressing: { pressing in
						editButtonPressed = pressing
						editButtonScale = pressing ? 0.95 : 1.0

						// Haptic feedback for press down
						if pressing {
							let selectionGenerator = UISelectionFeedbackGenerator()
							selectionGenerator.selectionChanged()
						}
					},
					perform: {
						// Haptic feedback on tap
						let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
						impactGenerator.impactOccurred()
					})
			}

			// Share Profile button removed for other users - only show for current user
			if isCurrentUserProfile {
				Button(action: {
					// Haptic feedback
					let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
					impactGenerator.impactOccurred()

					// Execute action with slight delay for animation
					DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
						shareProfile()
					}
				}) {
					HStack(spacing: 8) {
						Image(systemName: "square.and.arrow.up")
						Text("Share Profile")
							.font(.onestSemiBold(size: 12))
					}
					.bold()
					.font(.caption)
					.foregroundColor(universalSecondaryColor)
					.frame(height: 30)
					.frame(width: 128)
					.background(buttonBackgroundColor)
					.cornerRadius(12)
					.overlay(
						RoundedRectangle(cornerRadius: 12)
							.stroke(universalSecondaryColor, lineWidth: 2)
					)
					.scaleEffect(shareButtonScale)
					.shadow(
						color: Color.black.opacity(0.15),
						radius: shareButtonPressed ? 2 : 8,
						x: 0,
						y: shareButtonPressed ? 2 : 4
					)
				}
				.buttonStyle(PlainButtonStyle())
				.animation(.easeInOut(duration: 0.15), value: shareButtonScale)
				.animation(.easeInOut(duration: 0.15), value: shareButtonPressed)
				.onLongPressGesture(
					minimumDuration: 0, maximumDistance: .infinity,
					pressing: { pressing in
						shareButtonPressed = pressing
						shareButtonScale = pressing ? 0.95 : 1.0

						// Additional haptic feedback for press down
						if pressing {
							let selectionGenerator = UISelectionFeedbackGenerator()
							selectionGenerator.selectionChanged()
						}
					}, perform: {})
			}
		}
	}
}

#Preview {
	ProfileActionButtonsView(
		user: BaseUserDTO.danielAgapov,
		profileViewModel: ProfileViewModel(userId: UUID()),
		shareProfile: {}
	)
}
