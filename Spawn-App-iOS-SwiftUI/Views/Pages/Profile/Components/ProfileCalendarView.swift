//
//  ProfileCalendarView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/9/24.
//

import SwiftUI

struct TimeoutError: Error {}

struct ProfileCalendarView: View {
	@StateObject var profileViewModel: ProfileViewModel
	@StateObject var userAuth = UserAuthViewModel.shared

	@Binding var showCalendarPopup: Bool
	@Binding var showActivityDetails: Bool
	@Binding var navigateToCalendar: Bool

	@State private var currentDate = Date()
	
	private var currentMonth: Int {
		Calendar.current.component(.month, from: currentDate)
	}
	
	private var currentYear: Int {
		Calendar.current.component(.year, from: currentDate)
	}
	
	private var calendarDays: [Date?] {
		let calendar = Calendar.current
		let firstDayOfMonth = calendar.date(from: DateComponents(year: currentYear, month: currentMonth, day: 1))!
		let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth) - 1 // 0-indexed
		let daysInMonth = calendar.range(of: .day, in: .month, for: firstDayOfMonth)!.count
		
		var days: [Date?] = []
		
		// Add empty days for the beginning of the month
		for _ in 0..<firstWeekday {
			days.append(nil)
		}
		
		// Add actual days of the month
		for day in 1...daysInMonth {
			if let date = calendar.date(from: DateComponents(year: currentYear, month: currentMonth, day: day)) {
				days.append(date)
			}
		}
		
		// Fill to 35 days (5 rows × 7 days)
		while days.count < 35 {
			days.append(nil)
		}
		
		return days
	}

	var body: some View {
		VStack(spacing: 8) {
			// Month/Year header
			HStack {
				Text(monthYearString())
					.font(.onestMedium(size: 14))
					.foregroundColor(.primary)
				Spacer()
			}
			.padding(.horizontal, 4)
			
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
								let dayIndex = row * 7 + col
								if dayIndex < calendarDays.count, let date = calendarDays[dayIndex] {
									let dayActivities = getActivitiesForDate(date)
									if dayActivities.isEmpty {
										// Empty day cell
										RoundedRectangle(cornerRadius: 4.5)
											.fill(Color(hex: "#DBDBDB"))
											.frame(width: 32, height: 32)
											.shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 1)
											.overlay(
												Text("\(Calendar.current.component(.day, from: date))")
													.font(.onestMedium(size: 10))
													.foregroundColor(.black)
											)
											.onTapGesture {
												// Navigate to full calendar view on empty day tap
												Task {
													do {
														// Add timeout to prevent hanging
														try await withTimeout(seconds: 3) {
															await profileViewModel.fetchAllCalendarActivities()
														}
														await MainActor.run {
															navigateToCalendar = true
														}
													} catch {
														// If fetching fails or times out, still allow navigation to calendar
														// The calendar view will handle the empty state
														print("Failed to fetch calendar activities: \(error)")
														await MainActor.run {
															navigateToCalendar = true
														}
													}
												}
											}
									} else {
										// Day cell with activities
										CalendarDayCell(activities: dayActivities, dayNumber: Calendar.current.component(.day, from: date))
											.onTapGesture {
												handleDaySelection(activities: dayActivities)
											}
									}
								} else {
									// Empty cell for days outside the month
									RoundedRectangle(cornerRadius: 4.5)
										.fill(Color.clear)
										.frame(width: 32, height: 32)
								}
							}
						}
					}
				}
				.padding(.horizontal, 4)
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
			showDayActivities(activities: activities)
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
		let hostingController = UIHostingController(rootView: DayActivitiesPageView(
			date: activities.first?.date ?? Date(),
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

		// Set up sheet presentation with detents
		sheet.modalPresentationStyle = .pageSheet
		if let sheetPresentationController = sheet.sheetPresentationController {
			sheetPresentationController.detents = [.medium(), .large()]
			sheetPresentationController.prefersGrabberVisible = true
		}

		// Present the sheet
		if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
		   let rootViewController = windowScene.windows.first?.rootViewController {
			rootViewController.present(sheet, animated: true)
		}
	}

	// Get activities for a specific date
	private func getActivitiesForDate(_ date: Date) -> [CalendarActivityDTO] {
		let calendar = Calendar.current
		return profileViewModel.allCalendarActivities.filter { activity in
			calendar.isDate(activity.date, inSameDayAs: date)
		}
	}

	private var weekDays: [String] {
		["S", "M", "T", "W", "T", "F", "S"]
	}

	private func fetchCalendarData() {
		Task {
			// Fetch all calendar activities instead of just current month
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
	
	private func withTimeout<T>(seconds: Double, operation: @escaping () async throws -> T) async throws -> T {
		try await withThrowingTaskGroup(of: T.self) { group in
			group.addTask {
				try await operation()
			}
			
			group.addTask {
				try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
				throw TimeoutError()
			}
			
			guard let result = try await group.next() else {
				throw TimeoutError()
			}
			
			group.cancelAll()
			return result
		}
	}
}

// Calendar day cell component matching Figma design
struct CalendarDayCell: View {
	let activities: [CalendarActivityDTO]
	let dayNumber: Int
	
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
						VStack(spacing: 1) {
							activityIcon(for: activity)
								.font(.onestMedium(size: 12))
								.foregroundColor(.black)
							Text("\(dayNumber)")
								.font(.onestMedium(size: 8))
								.foregroundColor(.black)
						}
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
								.font(.onestMedium(size: 10))
								.foregroundColor(.black)
							Text("\(activities.count)")
								.font(.onestMedium(size: 8))
								.foregroundColor(.black)
							Text("\(dayNumber)")
								.font(.onestMedium(size: 6))
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
				// Fallback to default emoji
				Text("⭐️")
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
