//
//  ProfileCalendarView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/9/24.
//

import SwiftUI

struct ProfileCalendarView: View {
	@StateObject var profileViewModel: ProfileViewModel
	@StateObject var userAuth = UserAuthViewModel.shared

	@Binding var showCalendarPopup: Bool
	@Binding var showActivityDetails: Bool
	@Binding var navigateToCalendar: Bool

	@State private var currentMonth = Calendar.current.component(
		.month,
		from: Date()
	)
	@State private var currentYear = Calendar.current.component(
		.year,
		from: Date()
	)

	var body: some View {
		VStack(spacing: 8) {
			// Days of week header
			HStack(spacing: 4) {
				ForEach(Array(zip(0..<weekDays.count, weekDays)), id: \.0) { index, day in
					Text(day)
						.font(.onestMedium(size: 9))
						.foregroundColor(Color(hex: "#8E8484"))
						.frame(width: 32, height: 12)
				}
			}
			.padding(.horizontal, 4)

			if profileViewModel.isLoadingCalendar {
				ProgressView()
					.frame(maxWidth: .infinity, minHeight: 150)
			} else {
				// Calendar grid (clickable to show popup)
				VStack(spacing: 4) {
					ForEach(0..<5, id: \.self) { row in
						HStack(spacing: 4) {
							ForEach(0..<7, id: \.self) { col in
								if let dayActivities = getDayActivities(row: row, col: col) {
									if dayActivities.isEmpty {
										// Empty day cell
										RoundedRectangle(cornerRadius: 4.5)
											.fill(Color(hex: "#DBDBDB"))
											.frame(width: 32, height: 32)
											.shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 1)
									} else {
										// Day cell with activities
										CalendarDayCell(activities: dayActivities)
											.onTapGesture {
												handleDaySelection(activities: dayActivities)
											}
									}
								} else {
									// Days outside current month
									RoundedRectangle(cornerRadius: 4.5)
										.stroke(Color(hex: "#DBDBDB"), lineWidth: 0.5)
										.frame(width: 32, height: 32)
								}
							}
						}
					}
				}
				.padding(.horizontal, 4)
				.onTapGesture {
					// Only navigate when tapping on empty areas (not on activity days)
					// Load all calendar activities before navigating to calendar
					Task {
						await profileViewModel.fetchAllCalendarActivities()
						await MainActor.run {
							navigateToCalendar = true
						}
					}
				}
			}
		}
		.onAppear {
			fetchCalendarData()
		}
		.sheet(isPresented: $showActivityDetails) {
			if let activity = profileViewModel.selectedActivity {
				// Use the same color scheme as ActivityCardView would
				let activityColor = activity.isSelfOwned == true ?
				universalAccentColor : getActivityColor(for: activity.id)

				ActivityDescriptionView(
					activity: activity,
					users: activity.participantUsers,
					color: activityColor,
					userId: userAuth.spawnUser?.id ?? UUID()
				)
				.presentationDetents([.medium, .large])
			}
		}
	}

	private func handleDaySelection(activities: [CalendarActivityDTO]) {
		if activities.count == 1 {
			// If only one activity, directly open it
			handleActivitySelection(activities[0])
		} else if activities.count > 1 {
			// If multiple activities, show day's activities in a sheet
			Task {
				await profileViewModel.fetchAllCalendarActivities()
				await MainActor.run {
					showDayActivities(activities: activities)
				}
			}
		}
	}

	private func handleActivitySelection(_ activity: CalendarActivityDTO) {
		// First close the calendar popup
		showCalendarPopup = false

		// Then fetch and show the activity details
		Task {
			if let activityId = activity.activityId,
			   let _ = await profileViewModel.fetchActivityDetails(activityId: activityId) {
				await MainActor.run {
					showActivityDetails = true
				}
			}
		}
	}

	private func showDayActivities(activities: [CalendarActivityDTO]) {
		// Present a sheet with ActivityCardViews for each activity
		let sheet = UIViewController()
		let hostingController = UIHostingController(rootView: DayActivitiesView(
			activities: activities,
			onDismiss: {
				sheet.dismiss(animated: true)
			},
			onActivitySelected: { activity in
				sheet.dismiss(animated: true) {
					self.handleActivitySelection(activity)
				}
			}
		))

		sheet.addChild(hostingController)
		hostingController.view.frame = sheet.view.bounds
		sheet.view.addSubview(hostingController.view)
		hostingController.didMove(toParent: sheet)

		// Set up sheet presentation controller
		if let presentationController = sheet.presentationController as? UISheetPresentationController {
			presentationController.detents = [.medium(), .large()]
			presentationController.prefersGrabberVisible = true
		}

		// Present the sheet
		if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
		   let rootViewController = windowScene.windows.first?.rootViewController {
			rootViewController.present(sheet, animated: true)
		}
	}

	// Get array of activities for a specific day cell
	private func getDayActivities(row: Int, col: Int) -> [CalendarActivityDTO]? {
		// Convert the original single-activity grid to an array of activities per cell
		let activity = profileViewModel.calendarActivities[row][col]

		if activity == nil {
			return nil
		}

		// Find all activities for this day by date checking
		if let firstActivity = activity {
			let day = Calendar.current.component(.day, from: firstActivity.date)
			let month = Calendar.current.component(.month, from: firstActivity.date)
			let year = Calendar.current.component(.year, from: firstActivity.date)

			// Filter all activities matching this date
			return profileViewModel.allCalendarActivities.filter { act in
				let actDay = Calendar.current.component(.day, from: act.date)
				let actMonth = Calendar.current.component(.month, from: act.date)
				let actYear = Calendar.current.component(.year, from: act.date)

				return actDay == day && actMonth == month && actYear == year
			}
		}

		return []
	}

	private var weekDays: [String] {
		["S", "M", "T", "W", "T", "F", "S"]
	}

	private func fetchCalendarData() {
		Task {
			await profileViewModel.fetchCalendarActivities(
				month: currentMonth,
				year: currentYear
			)
			// Also fetch all activities to have them ready
			await profileViewModel.fetchAllCalendarActivities()
		}
	}

	private func monthYearString() -> String {
		let dateComponents = DateComponents(
			year: currentYear,
			month: currentMonth
		)
		if let date = Calendar.current.date(from: dateComponents) {
			let formatter = DateFormatter()
			formatter.dateFormat = "MMMM yyyy"
			return formatter.string(from: date)
		}
		return "\(currentMonth)/\(currentYear)"
	}
}

// Calendar day cell component matching Figma design
struct CalendarDayCell: View {
	let activities: [CalendarActivityDTO]
	
	var body: some View {
		ZStack {
			if activities.count == 1 {
				// Single activity - show its icon and color
				let activity = activities[0]
				RoundedRectangle(cornerRadius: 4.5)
					.fill(activityColor(for: activity))
					.frame(width: 32, height: 32)
					.shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 1)
					.overlay(
						activityIcon(for: activity)
							.font(.onestMedium(size: 18))
							.foregroundColor(.black)
					)
			} else if activities.count > 1 {
				// Multiple activities - show primary activity color with count
				let primaryActivity = activities[0]
				RoundedRectangle(cornerRadius: 4.5)
					.fill(activityColor(for: primaryActivity))
					.frame(width: 32, height: 32)
					.shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 1)
					.overlay(
						VStack(spacing: 0) {
							activityIcon(for: primaryActivity)
								.font(.onestMedium(size: 12))
								.foregroundColor(.black)
							Text("\(activities.count)")
								.font(.onestMedium(size: 8))
								.foregroundColor(.black)
						}
					)
			}
		}
	}
	
	private func activityColor(for activity: CalendarActivityDTO) -> Color {
		// First check if activity has a custom color hex code
		if let colorHexCode = activity.colorHexCode, !colorHexCode.isEmpty {
			return Color(hex: colorHexCode)
		}

		// Fallback to activity color based on ID
		guard let activityId = activity.activityId else {
			return Color(hex: "#DBDBDB")  // Default gray color
		}
		return getActivityColor(for: activityId)
	}

	private func activityIcon(for activity: CalendarActivityDTO) -> some View {
		Group {
			// If we have an icon from the backend, use it directly
			if let icon = activity.icon, !icon.isEmpty {
				Text(icon)
			} else {
				// Fallback to system icon from the ActivityCategory enum
				Image(
					systemName: activity.activityCategory?.systemIcon()
					?? "star.fill"
				)
			}
		}
	}
}

#Preview {
	ProfileCalendarView(
		profileViewModel: ProfileViewModel(userId: UUID()),
		showCalendarPopup: .constant(false),
		showActivityDetails: .constant(false),
		navigateToCalendar: .constant(false)
	)
}
