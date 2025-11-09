//
//  ParticipationButtonView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Shane on 5/18/25.
//
import SwiftUI

struct ParticipationButtonView: View {
	@ObservedObject private var activity: FullFeedActivityDTO
	@ObservedObject private var cardViewModel: ActivityCardViewModel

	// Optional binding to control tab selection for current user navigation
	@Binding var selectedTab: TabType?

	// Animation states for 3D effect
	@State private var scale: CGFloat = 1.0
	@State private var isPressed: Bool = false
	@State private var showingEditFlow = false

	init(
		activity: FullFeedActivityDTO,
		cardViewModel: ActivityCardViewModel,
		selectedTab: Binding<TabType?> = .constant(nil)
	) {
		self.activity = activity
		self.cardViewModel = cardViewModel
		self._selectedTab = selectedTab
	}

	private var isUserCreator: Bool {
		guard let currentUserId = UserAuthViewModel.shared.spawnUser?.id else {
			return false
		}
		return activity.creatorUser.id == currentUserId
	}

	private var participationText: String {
		if isUserCreator {
			return "Edit"
		} else {
			return cardViewModel.isParticipating ? "Going" : "Spawn In!"
		}
	}

	private var participationColor: Color {
		if isUserCreator {
			return figmaBittersweetOrange
		} else {
			return cardViewModel.isParticipating ? figmaGreen : figmaSoftBlue
		}
	}

	private var participationIcon: String {
		if isUserCreator {
			return "pencil.circle"
		} else {
			return cardViewModel.isParticipating
				? "checkmark.circle" : "star.circle"
		}
	}

	var body: some View {
		HStack {
			Button(action: {
				// Simple haptic feedback
				let impactGenerator = UIImpactFeedbackGenerator(style: .light)
				impactGenerator.impactOccurred()

				// Visual feedback
				withAnimation(.easeInOut(duration: 0.1)) {
					scale = 0.95
				}
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
					withAnimation(.easeInOut(duration: 0.1)) {
						scale = 1.0
					}
				}

				handleParticipationAction()
			}) {
				HStack {
					Image(systemName: participationIcon)
						.foregroundColor(participationColor)
						.fontWeight(.bold)
					Text(participationText)
						.font(.onestSemiBold(size: 18))
						.foregroundColor(participationColor)
				}
				.padding(.horizontal, 24)
				.padding(.vertical, 12)
				.background(.white)
				.cornerRadius(12)
				.overlay(
					RoundedRectangle(cornerRadius: 12)
						.stroke(Color(red: 0.95, green: 0.93, blue: 0.93), lineWidth: 1)  // border matching background
						.shadow(color: Color.black.opacity(0.50), radius: 2, x: -2, y: -2)  // dark shadow top
						.clipShape(RoundedRectangle(cornerRadius: 12))
						.shadow(color: Color.white.opacity(0.7), radius: 4, x: 4, y: 4)  // light shadow bottom
						.clipShape(RoundedRectangle(cornerRadius: 12))
				)
				.scaleEffect(scale)
			}
			.buttonStyle(PlainButtonStyle())
			.allowsHitTesting(true)
			.contentShape(Rectangle())

			Spacer()
			ParticipantsImagesView(
				activity: activity,
				selectedTab: $selectedTab,
				imageType: .participantsPopup
			)
		}
		.fullScreenCover(isPresented: $showingEditFlow) {
			ActivityCreationView(
				creatingUser: UserAuthViewModel.shared.spawnUser
					?? BaseUserDTO.danielAgapov,
				closeCallback: {
					showingEditFlow = false
				},
				selectedTab: .constant(.activities),
				startingStep: .dateTime
			)
		}
	}

	// Direct action method for better responsiveness
	private func handleParticipationAction() {
		if isUserCreator {
			// Initialize the creation view model with existing activity data
			ActivityCreationViewModel.initializeWithExistingActivity(activity)
			showingEditFlow = true
		} else {
			Task {
				await cardViewModel.toggleParticipation()
			}
		}
	}
}
