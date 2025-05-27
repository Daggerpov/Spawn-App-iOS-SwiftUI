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
	@Binding var showEventDetails: Bool

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
		.sheet(isPresented: $showEventDetails) {
			if let event = profileViewModel.selectedEvent {
				// Use the same color scheme as EventCardView would
				let eventColor = event.isSelfOwned == true ?
				universalAccentColor : determineEventColor(for: event)

				EventDescriptionView(
					event: event,
					users: event.participantUsers,
					color: eventColor,
					userId: userAuth.spawnUser?.id ?? UUID()
				)
				.presentationDetents([.medium, .large])
			}
		}
	}

	private func handleDaySelection(activities: [CalendarActivityDTO]) {
		if activities.count == 1 {
			// If only one activity, directly open it
			handleEventSelection(activities[0])
		} else if activities.count > 1 {
			// If multiple activities, show day's events in a sheet
			Task {
				await profileViewModel.fetchAllCalendarActivities()
				await MainActor.run {
					showDayEvents(activities: activities)
				}
			}
		}
	}

	private func handleEventSelection(_ activity: CalendarActivityDTO) {
		// First close the calendar popup
		showCalendarPopup = false

		// Then fetch and show the event details
		Task {
			if let eventId = activity.eventId,
			   let _ = await profileViewModel.fetchEventDetails(eventId: eventId) {
				await MainActor.run {
					showEventDetails = true
				}
			}
		}
	}

	private func showDayEvents(activities: [CalendarActivityDTO]) {
		// Present a sheet with EventCardViews for each activity
		let sheet = UIViewController()
		let hostingController = UIHostingController(rootView: DayEventsView(
			activities: activities,
			onDismiss: {
				sheet.dismiss(animated: true)
			},
			onEventSelected: { activity in
				sheet.dismiss(animated: true) {
					self.handleEventSelection(activity)
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

	private func determineEventColor(for event: FullFeedEventDTO) -> Color {
		// Use event category color
		return event.category.color()
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

	private var gradientColors: [Color] {
		// Get up to 3 unique colors from activities
		let colors = activities.prefix(3).compactMap { activity -> Color? in
			if let colorHex = activity.colorHexCode, !colorHex.isEmpty {
				return Color(hex: colorHex)
			} else if let category = activity.eventCategory {
				return category.color()
			}
			return nil
		}

		// If no colors found, return default gray
		if colors.isEmpty {
			return [Color.gray.opacity(0.5)]
		}

		// If only one color, use it with different opacity
		if colors.count == 1 {
			return [colors[0].opacity(0.7), colors[0].opacity(0.9)]
		}

		return colors
	}

	var body: some View {
		ZStack {
			// Gradient background
			RoundedRectangle(cornerRadius: 6)
				.fill(
					LinearGradient(
						gradient: Gradient(colors: gradientColors),
						startPoint: .topLeading,
						endPoint: .bottomTrailing
					)
				)
				.frame(height: 32)
				.shadow(radius: 2)

			if activities.count <= 4 {
				// Show up to 4 icons in a grid
				let columns = [
					GridItem(.flexible(), spacing: 1),
					GridItem(.flexible(), spacing: 1),
				]

				LazyVGrid(columns: columns, spacing: 1) {
					ForEach(activities.prefix(4), id: \.id) { activity in
						activityIcon(for: activity)
							.foregroundColor(.white)
							.font(.system(size: 10))
					}
				}
			} else {
				// Show 2 icons + overflow indicator
				HStack {
					ForEach(0..<2, id: \.self) { index in
						if index < activities.count {
							activityIcon(for: activities[index])
								.foregroundColor(.white)
								.font(.system(size: 10))
						}
					}

					Text("+\(activities.count - 2)")
						.font(.system(size: 10))
						.foregroundColor(.white)
						.fontWeight(.bold)
				}
			}
		}
	}

	private func activityColor(for activity: CalendarActivityDTO) -> Color {
		// First check if activity has a custom color hex code
		if let colorHexCode = activity.colorHexCode, !colorHexCode.isEmpty {
			return Color(hex: colorHexCode)
		}

		// Fallback to category color
		guard let category = activity.eventCategory else {
			return Color.gray.opacity(0.6)  // Default color for null category
		}
		return category.color()
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
                                systemName: activity.eventCategory?.systemIcon()
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
		showEventDetails: .constant(false)
	)
}
