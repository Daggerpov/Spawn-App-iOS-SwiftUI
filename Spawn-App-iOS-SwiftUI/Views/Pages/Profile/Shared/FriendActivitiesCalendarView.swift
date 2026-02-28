import SwiftUI

struct FriendActivitiesCalendarView: View {
	let user: Nameable
	var profileViewModel: ProfileViewModel
	@Binding var showActivityDetails: Bool
	/// When set to false by the calendar view (e.g. back tapped), parent pops this screen so we return to the profile.
	@Binding var isPresented: Bool

	@Environment(\.colorScheme) private var colorScheme
	@ObservedObject private var locationManager = LocationManager.shared

	@State private var showFullActivityList: Bool = false

	private var emptyDayCellColor: Color {
		colorScheme == .dark ? Color(hex: colorsGray700) : Color(hex: colorsGray200)
	}

	private var sortedActivities: [ProfileActivityDTO] {
		let upcomingActivities = profileViewModel.profileActivities
			.filter { !$0.isPastActivity }
			.sorted { activity1, activity2 in
				guard let start1 = activity1.startTime, let start2 = activity2.startTime else {
					return false
				}
				return start1 < start2
			}

		let pastActivities = profileViewModel.profileActivities
			.filter { $0.isPastActivity }
			.sorted { activity1, activity2 in
				guard let start1 = activity1.startTime, let start2 = activity2.startTime else {
					return false
				}
				return start1 > start2
			}

		return upcomingActivities + pastActivities
	}

	var body: some View {
		ZStack {
			universalBackgroundColor
				.ignoresSafeArea()

			ScrollView {
				VStack(alignment: .leading, spacing: 24) {
					activitiesSection
					calendarSection
				}
				.padding(.horizontal, 16)
				.padding(.top, 16)
				.padding(.bottom, 100)
			}
		}
		.navigationBarBackButtonHidden(true)
		.navigationBarTitleDisplayMode(.inline)
		.toolbar {
			ToolbarItem(placement: .navigationBarLeading) {
				Button(action: {
					isPresented = false
				}) {
					Image(systemName: "chevron.left")
						.font(.system(size: 20, weight: .semibold))
						.foregroundColor(universalAccentColor)
				}
			}
		}
		.navigationDestination(isPresented: $showFullActivityList) {
			FriendActivitiesShowAllView(
				user: user,
				profileViewModel: profileViewModel,
				showActivityDetails: $showActivityDetails
			)
		}
	}

	// MARK: - Activities Section
	private var activitiesSection: some View {
		VStack(alignment: .leading, spacing: 12) {
			HStack {
				Text("Activities by \(FormatterService.shared.formatFirstName(user: user))")
					.font(.onestSemiBold(size: 16))
					.foregroundColor(universalAccentColor)
				Spacer()
				Button(action: {
					showFullActivityList = true
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
				emptyActivitiesView
			} else {
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

	private var emptyActivitiesView: some View {
		VStack(spacing: 16) {
			Image(systemName: "calendar.badge.exclamationmark")
				.font(.system(size: 32))
				.foregroundColor(Color.gray.opacity(0.6))

			Text("\(FormatterService.shared.formatFirstName(user: user)) hasn't spawned any activities yet!")
				.font(.onestMedium(size: 16))
				.foregroundColor(.secondary)
				.multilineTextAlignment(.center)
		}
		.padding(32)
		.frame(maxWidth: .infinity)
		.background(
			RoundedRectangle(cornerRadius: 8)
				.stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
		)
	}

	// MARK: - Calendar Section
	private var calendarSection: some View {
		VStack(spacing: 16) {
			HStack(spacing: 6.618) {
				ForEach(Array(["S", "M", "T", "W", "T", "F", "S"].enumerated()), id: \.offset) { _, day in
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

	@ViewBuilder
	private func calendarDayCell(row: Int, col: Int) -> some View {
		if row < profileViewModel.calendarActivities.count,
			col < profileViewModel.calendarActivities[row].count,
			let activity = profileViewModel.calendarActivities[row][col]
		{
			FriendCalendarDayCell(activity: activity)
		} else {
			emptyDayCell(row: row, col: col)
		}
	}

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

	private func isDayOutsideCurrentMonth(row: Int, col: Int) -> Bool {
		let calendar = Calendar.current
		let now = Date()
		let currentMonth = calendar.component(.month, from: now)
		let currentYear = calendar.component(.year, from: now)

		var components = DateComponents()
		components.year = currentYear
		components.month = currentMonth
		components.day = 1

		guard let firstOfMonth = calendar.date(from: components) else {
			return false
		}

		let weekday = calendar.component(.weekday, from: firstOfMonth)
		let firstDayOffset = weekday - 1

		guard let range = calendar.range(of: .day, in: .month, for: firstOfMonth) else {
			return false
		}
		let daysInMonth = range.count
		let dayIndex = row * 7 + col

		return dayIndex < firstDayOffset || dayIndex >= firstDayOffset + daysInMonth
	}
}

// MARK: - Preview
@available(iOS 17, *)
#Preview {
	let viewModel: ProfileViewModel = {
		let vm = ProfileViewModel()
		vm.friendshipStatus = .friends
		vm.profileActivities = ProfileActivityDTO.mockActivities
		return vm
	}()

	NavigationStack {
		FriendActivitiesCalendarView(
			user: BaseUserDTO.danielAgapov,
			profileViewModel: viewModel,
			showActivityDetails: .constant(false),
			isPresented: .constant(true)
		)
	}
}
