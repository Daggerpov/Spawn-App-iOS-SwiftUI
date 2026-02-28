import SwiftUI

struct FriendActivitiesShowAllView: View {
	let user: Nameable
	var profileViewModel: ProfileViewModel
	@Binding var showActivityDetails: Bool

	@Environment(\.presentationMode) var presentationMode
	@Environment(\.colorScheme) private var colorScheme

	@ObservedObject private var locationManager = LocationManager.shared

	var body: some View {
		NavigationStack {
			ZStack {
				// Background
				universalBackgroundColor
					.ignoresSafeArea()

				VStack(spacing: 0) {
					// Header
					headerView

					ScrollView {
						VStack(spacing: 12) {
							// Upcoming Activities Section
							upcomingActivitiesSection

							// Past Activities Section
							pastActivitiesSection
						}
						.padding(.horizontal, 16)
						.padding(.top, 16)
						.padding(.bottom, 100)  // Account for tab bar
					}
				}
			}
			.navigationBarHidden(true)
			.onChange(of: showActivityDetails) { _, isShowing in
				if isShowing, let activity = profileViewModel.selectedActivity {
					let activityColor = getActivityColor(for: activity.id)

					NotificationCenter.default.post(
						name: .showGlobalActivityPopup,
						object: nil,
						userInfo: ["activity": activity, "color": activityColor]
					)
					showActivityDetails = false
					profileViewModel.selectedActivity = nil
				}
			}
		}
		.onAppear {
			Task {
				await fetchFriendData()
			}
		}
	}

	// MARK: - Header View
	private var headerView: some View {
		HStack {
			// Back button
			Button(action: {
				presentationMode.wrappedValue.dismiss()
			}) {
				Image(systemName: "chevron.left")
					.font(.system(size: 20, weight: .semibold))
					.foregroundColor(universalAccentColor)
			}

			Spacer()

			Text("Activities by \(FormatterService.shared.formatFirstName(user: user))")
				.font(.onestMedium(size: 20))
				.foregroundColor(universalAccentColor)

			Spacer()

			// Invisible placeholder to balance the back button
			Image(systemName: "chevron.left")
				.font(.system(size: 20, weight: .semibold))
				.foregroundColor(.clear)
		}
		.padding(.horizontal, 24)
		.padding(.vertical, 12)
	}

	// MARK: - Upcoming Activities Section
	private var upcomingActivitiesSection: some View {
		VStack(alignment: .leading, spacing: 12) {
			// Section header
			HStack {
				Text("Upcoming Activities")
					.font(.onestSemiBold(size: 16))
					.foregroundColor(universalAccentColor)
				Spacer()
			}

			if profileViewModel.isLoadingUserActivities {
				ProgressView()
					.frame(maxWidth: .infinity, minHeight: 100)
			} else if upcomingActivities.isEmpty {
				emptyStateView(message: "No upcoming activities")
			} else {
				// Show all upcoming activities with full activity card style
				VStack(spacing: 12) {
					ForEach(upcomingActivities) { activity in
						let activityColor = getActivityColor(for: activity.id)
						let fullFeedActivity = activity.toFullFeedActivityDTO()

						ActivityCardView(
							userId: UserAuthViewModel.shared.spawnUser?.id ?? UUID(),
							activity: fullFeedActivity,
							color: activityColor,
							locationManager: locationManager,
							callback: { selectedActivity, color in
								profileViewModel.selectedActivity = selectedActivity
								showActivityDetails = true
							}
						)
					}
				}
			}
		}
	}

	// MARK: - Past Activities Section
	private var pastActivitiesSection: some View {
		VStack(alignment: .leading, spacing: 12) {
			// Section header
			HStack {
				Text("Past Activities")
					.font(.onestSemiBold(size: 16))
					.foregroundColor(universalAccentColor)
				Spacer()
			}

			if profileViewModel.isLoadingUserActivities {
				ProgressView()
					.frame(maxWidth: .infinity, minHeight: 100)
			} else if pastActivities.isEmpty {
				emptyStateView(message: "No past activities")
			} else {
				// Show all past activities with compact card style
				VStack(spacing: 12) {
					ForEach(pastActivities) { activity in
						let activityColor = getActivityColor(for: activity.id)

						CompactActivityCard(
							activity: activity,
							color: activityColor,
							onTap: {
								profileViewModel.selectedActivity = activity.toFullFeedActivityDTO()
								showActivityDetails = true
							}
						)
					}
				}
			}
		}
	}

	// MARK: - Empty State View
	private func emptyStateView(message: String) -> some View {
		VStack(spacing: 8) {
			Text(message)
				.font(.onestMedium(size: 16))
				.foregroundColor(figmaBlack300)
		}
		.padding()
		.frame(maxWidth: .infinity)
	}

	// MARK: - Helper Properties
	private var upcomingActivities: [ProfileActivityDTO] {
		profileViewModel.profileActivities
			.filter { !$0.isPastActivity }
			.sorted { activity1, activity2 in
				guard let start1 = activity1.startTime, let start2 = activity2.startTime else {
					return false
				}
				return start1 < start2
			}
	}

	private var pastActivities: [ProfileActivityDTO] {
		profileViewModel.profileActivities
			.filter { $0.isPastActivity }
			.sorted { activity1, activity2 in
				guard let start1 = activity1.startTime, let start2 = activity2.startTime else {
					return false
				}
				return start1 > start2  // Most recent first
			}
	}

	// MARK: - Helper Methods
	private func fetchFriendData() async {
		// Data is already loaded from the parent view
	}
}

// MARK: - Compact Activity Card Component (for Past Activities)
struct CompactActivityCard: View {
	let activity: ProfileActivityDTO
	let color: Color
	let onTap: () -> Void

	var body: some View {
		Button(action: onTap) {
			HStack(spacing: 10) {
				// Left side - Activity info
				VStack(alignment: .leading, spacing: 6) {
					Text(activity.title ?? "Activity")
						.font(.onestSemiBold(size: 17))
						.foregroundColor(.white)
						.lineLimit(1)

					Text(subtitleText)
						.font(.onestMedium(size: 13))
						.foregroundColor(.white.opacity(0.8))
						.lineLimit(1)
				}

				Spacer()

				// Right side - Participant avatars
				participantAvatars
			}
			.padding(.horizontal, 16)
			.padding(.vertical, 13)
			.background(
				RoundedRectangle(cornerRadius: 12)
					.fill(color)
					.shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 2)
			)
		}
		.buttonStyle(PlainButtonStyle())
	}

	private var subtitleText: String {
		var parts: [String] = []

		// Location
		if let location = activity.location?.name {
			parts.append(location)
		}

		// Date
		if let startTime = activity.startTime {
			let formatter = DateFormatter()
			formatter.dateFormat = "MMMM d"
			parts.append(formatter.string(from: startTime))
		}

		return parts.joined(separator: " • ")
	}

	private var participantAvatars: some View {
		let participants = activity.participantUsers ?? []
		let displayCount = min(participants.count, 2)
		let extraCount = participants.count - displayCount

		return HStack(spacing: -8) {
			// Show first 2 participant avatars
			ForEach(0..<displayCount, id: \.self) { index in
				let participant = participants[index]
				avatarView(for: participant)
			}

			// Show +N count if there are more participants
			if extraCount > 0 {
				ZStack {
					Circle()
						.fill(Color.white)
						.frame(width: 34, height: 34)

					Text("+\(extraCount)")
						.font(.system(size: 12, weight: .bold))
						.foregroundColor(color)
				}
			}
		}
	}

	@ViewBuilder
	private func avatarView(for user: BaseUserDTO) -> some View {
		if let profilePicture = user.profilePicture, !profilePicture.isEmpty {
			if MockAPIService.isMocking {
				Image(profilePicture)
					.resizable()
					.aspectRatio(contentMode: .fill)
					.frame(width: 34, height: 34)
					.clipShape(Circle())
					.overlay(Circle().stroke(Color.white, lineWidth: 2))
			} else {
				AsyncImage(url: URL(string: profilePicture)) { phase in
					switch phase {
					case .success(let image):
						image
							.resizable()
							.aspectRatio(contentMode: .fill)
							.frame(width: 34, height: 34)
							.clipShape(Circle())
							.overlay(Circle().stroke(Color.white, lineWidth: 2))
					default:
						Circle()
							.fill(Color.gray.opacity(0.3))
							.frame(width: 34, height: 34)
							.overlay(Circle().stroke(Color.white, lineWidth: 2))
					}
				}
			}
		} else {
			Circle()
				.fill(Color.gray.opacity(0.3))
				.frame(width: 34, height: 34)
				.overlay(Circle().stroke(Color.white, lineWidth: 2))
		}
	}
}

// MARK: - Preview
#Preview {
	FriendActivitiesShowAllView(
		user: BaseUserDTO.danielAgapov,
		profileViewModel: ProfileViewModel(),
		showActivityDetails: .constant(false)
	)
}
