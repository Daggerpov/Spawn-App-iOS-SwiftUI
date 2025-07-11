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
	@Binding var navigateToDayActivities: Bool
	@Binding var selectedDayActivities: [CalendarActivityDTO]

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
				ForEach(0..<weekDays.count, id: \.self) { index in
					Text(weekDays[index])
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
											.fill(figmaCalendarDayIcon)
											.frame(width: 32, height: 32)
											.shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 1)
											.onTapGesture {
												print("🔥 ProfileCalendarView: Empty day cell tapped for date \(date)")
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
												print("🔥 ProfileCalendarView: Day cell tapped for date \(date) with \(dayActivities.count) activities")
												
												// Create a fresh copy of activities to ensure they don't get lost
												let activitiesCopy = Array(dayActivities)
												print("🔥 ProfileCalendarView: Created activities copy with \(activitiesCopy.count) activities")
												
												handleDaySelection(activities: activitiesCopy)
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
		print("🔥 ProfileCalendarView: handleDaySelection called with \(activities.count) activities")
		
		// Debug: Print activity details
		for (index, activity) in activities.enumerated() {
			print("🔥 ProfileCalendarView: Activity \(index + 1): \(activity.title ?? "No title"), Date: \(activity.date), ID: \(activity.activityId?.uuidString ?? "No ID")")
		}
		
		// Always set selectedDayActivities regardless of count
		selectedDayActivities = activities
		print("🔥 ProfileCalendarView: selectedDayActivities set to \(activities.count) activities")
		
		// Always navigate to day activities page for any day selection
		print("🔥 ProfileCalendarView: Navigating to day activities page")
		
		DispatchQueue.main.async {
			self.navigateToDayActivities = true
			print("🔥 ProfileCalendarView: navigateToDayActivities set to true")
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



	// Get activities for a specific date
	private func getActivitiesForDate(_ date: Date) -> [CalendarActivityDTO] {
		print("🔥 ProfileCalendarView: getActivitiesForDate called for date: \(date)")
		let calendar = Calendar.current
		let filteredActivities = profileViewModel.allCalendarActivities.filter { activity in
			let isMatch = calendar.isDate(activity.date, inSameDayAs: date)
			if isMatch {
				print("🔥 ProfileCalendarView: Found activity for date \(date): \(activity.title ?? "No title")")
			}
			return isMatch
		}
		
		print("🔥 ProfileCalendarView: Day \(Calendar.current.component(.day, from: date)) has \(filteredActivities.count) activities")
		
		// Debug: Print all activities and their dates
		if filteredActivities.isEmpty {
			print("🔥 ProfileCalendarView: No activities found for date \(date)")
			print("🔥 ProfileCalendarView: All available activities (\(profileViewModel.allCalendarActivities.count)):")
			for activity in profileViewModel.allCalendarActivities {
				print("  - \(activity.title ?? "No title"): \(activity.date)")
			}
		}
		
		return filteredActivities
	}

	private var weekDays: [String] {
		["S", "M", "T", "W", "T", "F", "S"]
	}

	private func fetchCalendarData() {
		print("🔥 ProfileCalendarView: fetchCalendarData called")
		Task {
			// Fetch all calendar activities instead of just current month
			print("🔥 ProfileCalendarView: Starting to fetch all calendar activities")
			await profileViewModel.fetchAllCalendarActivities()
			
			await MainActor.run {
				print("🔥 ProfileCalendarView: Finished fetching calendar activities. Total: \(profileViewModel.allCalendarActivities.count)")
				for (index, activity) in profileViewModel.allCalendarActivities.enumerated() {
					print("🔥 ProfileCalendarView: Activity \(index + 1): \(activity.title ?? "No title"), Date: \(activity.date)")
				}
			}
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
			if activities.count == 1, !activities.isEmpty {
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
			} else if activities.count > 1, !activities.isEmpty {
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
			return figmaCalendarDayIcon  // Default gray color
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
		navigateToCalendar: .constant(false),
		navigateToDayActivities: .constant(false),
		selectedDayActivities: .constant([])
	)
}
