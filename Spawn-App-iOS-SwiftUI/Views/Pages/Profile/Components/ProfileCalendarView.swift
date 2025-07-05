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
			HStack {
				ForEach(Array(zip(0..<weekDays.count, weekDays)), id: \.0) { index, day in
					Text(day)
						.font(.onestMedium(size: 9))
						.frame(maxWidth: .infinity)
						.foregroundColor(.gray)
				}
			}

			if profileViewModel.isLoadingCalendar {
				ProgressView()
					.frame(maxWidth: .infinity, minHeight: 150)
			} else {
				// Calendar grid (clickable to show popup)
				VStack(spacing: 3) {
					ForEach(0..<5, id: \.self) { row in
						HStack(spacing: 3) {
							ForEach(0..<7, id: \.self) { col in
								if let dayActivities = getDayActivities(row: row, col: col) {
									if dayActivities.isEmpty {
										// Empty day cell
										RoundedRectangle(cornerRadius: 6)
											.fill(Color.gray.opacity(0.2))
											.frame(height: 32)
									} else {
										// Mini day cell with multiple activities
										MiniDayCell(activities: dayActivities)
											.onTapGesture {
												handleDaySelection(activities: dayActivities)
											}
									}
								} else {
									RoundedRectangle(cornerRadius: 6)
										.fill(Color.gray.opacity(0.2))
										.frame(height: 32)
								}
							}
						}
					}
				}
				.onTapGesture {
					// Load all calendar activities before showing the popup
					Task {
						await profileViewModel.fetchAllCalendarActivities()
						await MainActor.run {
							showCalendarPopup = true
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

// Helper struct for the mini day cell in the profile view
struct MiniDayCell: View {
	let activities: [CalendarActivityDTO]
	
	var body: some View {
		ZStack {
			RoundedRectangle(cornerRadius: 6)
				.fill(Color.gray.opacity(0.3))
				.frame(height: 32)
			
			if activities.count == 1 {
				// Single activity - show its icon and color
				let activity = activities[0]
				RoundedRectangle(cornerRadius: 6)
					.fill(activityColor(for: activity))
					.frame(height: 32)
					.overlay(
						activityIcon(for: activity)
							.foregroundColor(.white)
					)
			} else if activities.count > 1 {
				// Multiple activities - show count and mixed colors
				RoundedRectangle(cornerRadius: 6)
					.fill(LinearGradient(
						gradient: Gradient(colors: activities.prefix(3).map { activityColor(for: $0) }),
						startPoint: .leading,
						endPoint: .trailing
					))
					.frame(height: 32)
					.overlay(
						Text("\(activities.count)")
							.font(.system(size: 10, weight: .bold))
							.foregroundColor(.white)
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
			return Color.gray.opacity(0.6)  // Default color for null activity ID
		}
		return getActivityColor(for: activityId)
	}

	private func activityIcon(for activity: CalendarActivityDTO) -> some View {
		Group {
			// If we have an icon from the backend, use it directly
			if let icon = activity.icon, !icon.isEmpty {
				Text(icon)
					.font(.system(size: 10))
			} else {
				// Fallback to system icon from the ActivityCategory enum
				Image(
					systemName: activity.activityCategory?.systemIcon()
					?? "star.fill"
				)
				.font(.system(size: 10))
			}
		}
	}
}

#Preview {
	ProfileCalendarView(
		profileViewModel: ProfileViewModel(userId: UUID()),
		showCalendarPopup: .constant(false),
		showActivityDetails: .constant(false)
	)
}
