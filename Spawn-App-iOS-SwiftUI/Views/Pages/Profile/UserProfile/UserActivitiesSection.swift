import SwiftUI

struct UserActivitiesSection: View {
	var user: Nameable
	var profileViewModel: ProfileViewModel
	@ObservedObject private var locationManager = LocationManager.shared
	@Binding var showActivityDetails: Bool
	@State private var showFriendActivities: Bool = false
	@State private var showDayActivitiesFromFriend: Bool = false
	@State private var selectedDayActivities: [CalendarActivityDTO] = []

	// Adaptive colors for dark mode support
	private var secondaryTextColor: Color {
		Color(
			UIColor { traitCollection in
				switch traitCollection.userInterfaceStyle {
				case .dark:
					return UIColor(Color(hex: colorsGray300))  // Lighter for dark mode
				default:
					return UIColor(Color(red: 0.56, green: 0.52, blue: 0.52))  // Original for light mode
				}
			})
	}

	private var borderColor: Color {
		Color(
			UIColor { traitCollection in
				switch traitCollection.userInterfaceStyle {
				case .dark:
					return UIColor(Color(hex: colorsGray600))  // Visible border in dark mode
				default:
					return UIColor(Color(red: 0.56, green: 0.52, blue: 0.52))  // Original for light mode
				}
			})
	}

	private var dashedBorderColor: Color {
		Color(
			UIColor { traitCollection in
				switch traitCollection.userInterfaceStyle {
				case .dark:
					return UIColor(Color(hex: colorsGray500))  // Visible dashed border in dark mode
				default:
					return UIColor(Color.gray.opacity(0.4))  // Original for light mode
				}
			})
	}

	// Figma "Add to see" section: 1px dashed border and text (#8e8484)
	private var addToSeeMutedColor: Color { Color(hex: colorsAddToSeeMutedHex) }

	var body: some View {
		VStack(alignment: .leading, spacing: 32) {
			if profileViewModel.friendshipStatus == .friends {
				friendActivitiesSection
			}

			addToSeeActivitiesSection
		}
		.navigationDestination(isPresented: $showFriendActivities) {
			ActivityCalendarView(
				profileViewModel: profileViewModel,
				userCreationDate: profileViewModel.userProfileInfo?.dateCreated,
				calendarOwnerName: FormatterService.shared.formatFirstName(user: user),
				onDismiss: { showFriendActivities = false },
				onActivitySelected: { handleFriendActivitySelection($0) },
				onDayActivitiesSelected: { activities in
					selectedDayActivities = activities
					showDayActivitiesFromFriend = true
				}
			)
		}
		.navigationDestination(isPresented: $showDayActivitiesFromFriend) {
			DayActivitiesPageView(
				date: selectedDayActivities.first?.dateAsDate ?? Date(),
				initialActivities: selectedDayActivities,
				onDismiss: { showDayActivitiesFromFriend = false },
				onActivitySelected: { activity in
					showDayActivitiesFromFriend = false
					handleFriendActivitySelection(activity)
				}
			)
		}
	}

	/// Fetches full activity details and shows the global activity popup (same as own profile).
	private func handleFriendActivitySelection(_ activity: CalendarActivityDTO) {
		Task {
			if let activityId = activity.activityId,
				await profileViewModel.fetchActivityDetails(activityId: activityId) != nil
			{
				await MainActor.run {
					showActivityDetails = true
				}
			}
		}
	}

	// Computed property to sort activities as specified
	private var sortedActivities: [ProfileActivityDTO] {
		let upcomingActivities = profileViewModel.profileActivities
			.filter { !$0.isPastActivity }

		// Sort upcoming activities by soonest to latest
		let sortedUpcoming = upcomingActivities.sorted { activity1, activity2 in
			guard let start1 = activity1.startTime, let start2 = activity2.startTime else {
				return false
			}
			return start1 < start2
		}

		let pastActivities = profileViewModel.profileActivities
			.filter { $0.isPastActivity }

		// Sort past activities by most recent first
		let sortedPast = pastActivities.sorted { activity1, activity2 in
			guard let start1 = activity1.startTime, let start2 = activity2.startTime else {
				return false
			}
			return start1 > start2
		}

		// Combine upcoming activities followed by past activities
		return sortedUpcoming + sortedPast
	}

	// User Activities Section for friend profiles
	private var friendActivitiesSection: some View {
		VStack(alignment: .leading, spacing: 12) {
			HStack {
				Text("Activities by \(FormatterService.shared.formatFirstName(user: user))")
					.font(.onestSemiBold(size: 16))
					.foregroundColor(universalAccentColor)
				Spacer()
				Button(action: {
					showFriendActivities = true
				}) {
					Text("See More")
						.font(.onestMedium(size: 14))
						.foregroundColor(universalSecondaryColor)
				}
			}

			if profileViewModel.isLoadingUserActivities {
				HStack {
					Spacer()
					ProgressView()
					Spacer()
				}
			} else if profileViewModel.profileActivities.isEmpty {
				VStack(spacing: 16) {
					Image(systemName: "calendar.badge.exclamationmark")
						.font(.system(size: 32))
						.foregroundColor(secondaryTextColor.opacity(0.8))

					Text("\(FormatterService.shared.formatFirstName(user: user)) hasn't spawned any activities yet!")
						.font(.onestMedium(size: 16))
						.foregroundColor(secondaryTextColor)
						.multilineTextAlignment(.center)
				}
				.padding(32)
				.frame(maxWidth: .infinity)
				.background(
					RoundedRectangle(cornerRadius: 8)
						.stroke(borderColor, lineWidth: 0.5)
				)
			} else {
				// Vertical stack of activity cards (max 2) - per Figma design
				VStack(spacing: 12) {
					ForEach(Array(sortedActivities.prefix(2))) { activity in
						let fullFeedActivity = activity.toFullFeedActivityDTO()
						ActivityCardView(
							userId: UserAuthViewModel.shared.spawnUser?.id ?? UUID(),
							activity: fullFeedActivity,
							color: getActivityColor(for: activity.id),
							locationManager: locationManager,
							callback: { selectedActivity, color in
								profileViewModel.selectedActivity = selectedActivity
								showActivityDetails = true
							},
							horizontalPadding: 0
						)
					}
				}
			}
		}
	}

	// "Add to see activities" section for non-friends (Figma: stars icon, 16px gap, 32px padding, 8px radius, 1px dashed #8e8484)
	private var addToSeeActivitiesSection: some View {
		VStack(alignment: .leading, spacing: 12) {
			if profileViewModel.friendshipStatus != .friends {
				VStack(alignment: .center, spacing: 16) {
					// Figma: stars-01 icon 32×32
					Image("AddToSeeStarsIcon")
						.resizable()
						.scaledToFit()
						.frame(width: 32, height: 32)

					Text("Add \(FormatterService.shared.formatFirstName(user: user)) to see their upcoming spawns!")
						.font(.onestMedium(size: 16))
						.foregroundColor(addToSeeMutedColor)
						.multilineTextAlignment(.center)
				}
				.frame(maxWidth: .infinity)
				.padding(32)
				.background(
					RoundedRectangle(cornerRadius: 8)
						.stroke(style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
						.foregroundColor(addToSeeMutedColor)
				)
			}
		}
	}
}

// MARK: - Friend Calendar Day Cell Component
struct FriendCalendarDayCell: View {
	let activity: CalendarActivityDTO

	var body: some View {
		ZStack {
			RoundedRectangle(cornerRadius: 6.618)
				.fill(activityColor)
				.frame(width: 46.33, height: 46.33)
				.shadow(color: Color.black.opacity(0.1), radius: 6.618, x: 0, y: 1.655)

			// Inner highlight effect per Figma
			RoundedRectangle(cornerRadius: 6.618)
				.fill(
					LinearGradient(
						colors: [Color.white.opacity(0.5), Color.clear],
						startPoint: .top,
						endPoint: .bottom
					)
				)
				.frame(width: 46.33, height: 46.33)
				.allowsHitTesting(false)

			// Emoji icon
			if let icon = activity.icon, !icon.isEmpty {
				Text(icon)
					.font(.onestMedium(size: 26.47))
			} else {
				Text("⭐️")
					.font(.onestMedium(size: 26.47))
			}
		}
	}

	private var activityColor: Color {
		// First check if activity has a custom color hex code
		if let colorHexCode = activity.colorHexCode, !colorHexCode.isEmpty {
			return Color(hex: colorHexCode)
		}

		// Fallback to activity color based on ID
		guard let activityId = activity.activityId else {
			return Color(hex: colorsGray200)  // Default gray color
		}
		return getActivityColor(for: activityId)
	}
}

@available(iOS 17, *)
#Preview("With Activities") {
	let viewModel: ProfileViewModel = {
		let vm = ProfileViewModel()
		vm.friendshipStatus = .friends
		vm.profileActivities = ProfileActivityDTO.mockActivities
		return vm
	}()

	UserActivitiesSection(
		user: BaseUserDTO.danielAgapov,
		profileViewModel: viewModel,
		showActivityDetails: .constant(false)
	)
	.padding(.horizontal, 16)
	.background(universalBackgroundColor)
}

@available(iOS 17, *)
#Preview("Empty Activities") {
	let viewModel: ProfileViewModel = {
		let vm = ProfileViewModel()
		vm.friendshipStatus = .friends
		vm.profileActivities = []
		return vm
	}()

	UserActivitiesSection(
		user: BaseUserDTO.danielAgapov,
		profileViewModel: viewModel,
		showActivityDetails: .constant(false)
	)
	.padding(.horizontal, 16)
	.background(universalBackgroundColor)
}

@available(iOS 17, *)
#Preview("Not Friends") {
	let viewModel: ProfileViewModel = {
		let vm = ProfileViewModel()
		vm.friendshipStatus = .none
		return vm
	}()

	UserActivitiesSection(
		user: BaseUserDTO.danielAgapov,
		profileViewModel: viewModel,
		showActivityDetails: .constant(false)
	)
	.padding(.horizontal, 16)
	.background(universalBackgroundColor)
}
