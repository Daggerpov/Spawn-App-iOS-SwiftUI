import SwiftUI

struct UserActivitiesSection: View {
	var user: Nameable
	var profileViewModel: ProfileViewModel
	@ObservedObject private var locationManager = LocationManager.shared
	@Binding var showActivityDetails: Bool
	@State private var showFriendActivities: Bool = false

	@Environment(\.colorScheme) private var colorScheme

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

	// Theme-aware empty day cell color
	private var emptyDayCellColor: Color {
		colorScheme == .dark ? Color(hex: colorsGray700) : Color(hex: colorsGray200)
	}

	var body: some View {
		VStack(alignment: .leading, spacing: 32) {
			// Only show activities section if they are friends
			if profileViewModel.friendshipStatus == .friends {
				friendActivitiesSection
				calendarSection
			}

			addToSeeActivitiesSection
		}
		.navigationDestination(isPresented: $showFriendActivities) {
			FriendActivitiesShowAllView(
				user: user,
				profileViewModel: profileViewModel,
				showActivityDetails: $showActivityDetails
			)
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
					Text("Show All")
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
						ActivityCardView(
							userId: UserAuthViewModel.shared.spawnUser?.id ?? UUID(),
							activity: activity,
							color: getActivityColor(for: activity.id),
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

	// Calendar section showing friend's activities - per Figma design
	private var calendarSection: some View {
		VStack(spacing: 16) {
			// Days of the week header
			HStack(spacing: 6.618) {
				ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
					Text(day)
						.font(.onestMedium(size: 13))
						.foregroundColor(universalAccentColor)
						.frame(width: 46.33)
				}
			}

			if profileViewModel.isLoadingCalendar {
				ProgressView()
					.frame(maxWidth: .infinity, minHeight: 150)
			} else {
				// Calendar grid - 5 rows x 7 days
				VStack(spacing: 6.618) {
					ForEach(0..<5, id: \.self) { row in
						HStack(spacing: 6.618) {
							ForEach(0..<7, id: \.self) { col in
								calendarDayCell(row: row, col: col)
							}
						}
					}
				}
			}
		}
	}

	// Calendar day cell - shows activity or empty state
	@ViewBuilder
	private func calendarDayCell(row: Int, col: Int) -> some View {
		if row < profileViewModel.calendarActivities.count,
			col < profileViewModel.calendarActivities[row].count,
			let activity = profileViewModel.calendarActivities[row][col]
		{
			// Day cell with activity data
			FriendCalendarDayCell(activity: activity)
				.onTapGesture {
					showFriendActivities = true
				}
		} else {
			// Empty day cell - use dashed border for outside month, solid for in month
			emptyDayCell(row: row, col: col)
				.onTapGesture {
					showFriendActivities = true
				}
		}
	}

	// Empty day cell with appropriate styling per Figma
	@ViewBuilder
	private func emptyDayCell(row: Int, col: Int) -> some View {
		let isOutsideMonth = isDayOutsideCurrentMonth(row: row, col: col)

		if isOutsideMonth {
			RoundedRectangle(cornerRadius: 6.618)
				.stroke(style: StrokeStyle(lineWidth: 1.655, dash: [6, 6]))
				.foregroundColor(universalAccentColor.opacity(0.1))
				.frame(width: 46.33, height: 46.33)
		} else {
			ZStack {
				RoundedRectangle(cornerRadius: 6.618)
					.fill(emptyDayCellColor)
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
			}
		}
	}
	
	// Helper function to determine if a cell is outside the current month
	private func isDayOutsideCurrentMonth(row: Int, col: Int) -> Bool {
		let calendar = Calendar.current
		let now = Date()
		let currentMonth = calendar.component(.month, from: now)
		let currentYear = calendar.component(.year, from: now)
		
		// Calculate first day offset (0-6, where 0 = Sunday)
		var components = DateComponents()
		components.year = currentYear
		components.month = currentMonth
		components.day = 1
		
		guard let firstOfMonth = calendar.date(from: components) else {
			return false
		}
		
		let weekday = calendar.component(.weekday, from: firstOfMonth)
		let firstDayOffset = weekday - 1  // Convert from 1-7 to 0-6
		
		// Calculate days in month
		guard let range = calendar.range(of: .day, in: .month, for: firstOfMonth) else {
			return false
		}
		let daysInMonth = range.count
		
		// Calculate day index (0-34)
		let dayIndex = row * 7 + col
		
		// Day is outside month if it's before the first day or after the last day
		return dayIndex < firstDayOffset || dayIndex >= firstDayOffset + daysInMonth
	}

	// "Add to see activities" section for non-friends
	private var addToSeeActivitiesSection: some View {
		VStack(alignment: .leading, spacing: 12) {
			if profileViewModel.friendshipStatus != .friends {
				VStack(alignment: .center, spacing: 12) {
					Image(systemName: "location.fill")
						.font(.system(size: 32))
						.foregroundColor(dashedBorderColor)

					Text("Add \(FormatterService.shared.formatFirstName(user: user)) to see their upcoming spawns!")
						.font(.onestSemiBold(size: 16))
						.foregroundColor(.primary)
						.multilineTextAlignment(.center)

					Text("Connect with them to discover what they're up to!")
						.font(.onestRegular(size: 14))
						.foregroundColor(secondaryTextColor)
						.multilineTextAlignment(.center)
				}
				.frame(maxWidth: .infinity)
				.padding(.horizontal, 24)
				.padding(.vertical, 32)
				.background(
					RoundedRectangle(cornerRadius: 12)
						.stroke(style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
						.foregroundColor(dashedBorderColor)
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

#Preview {
	UserActivitiesSection(
		user: BaseUserDTO.danielAgapov,
		profileViewModel: ProfileViewModel(),
		showActivityDetails: .constant(false)
	)
}
