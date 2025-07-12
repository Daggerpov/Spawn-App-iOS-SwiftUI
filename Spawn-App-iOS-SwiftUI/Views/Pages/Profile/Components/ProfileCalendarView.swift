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
			monthYearHeader
			weekDaysHeader
			calendarContent
		}
		.onAppear {
			fetchCalendarData()
		}
		.sheet(isPresented: $showActivityDetails) {
			if let activity = profileViewModel.selectedActivity {
				// Use the same color scheme as ActivityCardView would
				let activityColor = activity.isSelfOwned == true ?
				universalAccentColor : getActivityColor(for: activity.id)

				ActivityDetailModalView(
					activity: activity,
					activityColor: activityColor,
					onDismiss: {
						showActivityDetails = false
					}
				)
				.presentationDetents([.large])
				.presentationDragIndicator(.visible)
			}
		}
	}

	// MARK: - Computed Properties for Body Components
	
	private var monthYearHeader: some View {
		HStack {
			Text(monthYearString())
				.font(.onestMedium(size: 14))
				.foregroundColor(.primary)
			Spacer()
		}
		.padding(.horizontal, 4)
	}
	
	private var weekDaysHeader: some View {
		HStack(spacing: 4) {
			ForEach(0..<weekDays.count, id: \.self) { index in
				Text(weekDays[index])
					.font(.onestMedium(size: 9))
					.foregroundColor(Color(hex: "#8E8484"))
					.frame(width: 32, height: 12)
			}
		}
		.padding(.horizontal, 4)
	}
	
	private var calendarContent: some View {
		Group {
			if profileViewModel.isLoadingCalendar {
				loadingView
			} else {
				calendarGrid
			}
		}
	}
	
	private var loadingView: some View {
		ProgressView()
			.frame(maxWidth: .infinity, minHeight: 150)
	}
	
	private var calendarGrid: some View {
		VStack(spacing: 4) {
			ForEach(0..<5, id: \.self) { row in
				calendarRow(row)
			}
		}
		.padding(.horizontal, 4)
	}
	
	private func calendarRow(_ row: Int) -> some View {
		HStack(spacing: 4) {
			ForEach(0..<7, id: \.self) { col in
				calendarDayCell(row: row, col: col)
			}
		}
	}
	
	private func calendarDayCell(row: Int, col: Int) -> some View {
		let dayIndex = row * 7 + col
		
		return Group {
			if dayIndex < calendarDays.count, let date = calendarDays[dayIndex] {
				let dayActivities = getActivitiesForDate(date)
				
				if dayActivities.isEmpty {
					emptyDayCell
				} else {
					CalendarDayCell(activities: dayActivities, dayNumber: Calendar.current.component(.day, from: date))
						.onTapGesture {
							handleDaySelection(activities: dayActivities)
						}
				}
			} else {
				outsideMonthCell
			}
		}
	}
	
	private var emptyDayCell: some View {
		RoundedRectangle(cornerRadius: 4.5)
			.fill(figmaCalendarDayIcon)
			.frame(width: 32, height: 32)
			.shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 1)
			.onTapGesture {
				handleDaySelection(activities: [])
			}
	}
	
	private var outsideMonthCell: some View {
		RoundedRectangle(cornerRadius: 4.5)
			.fill(Color.clear)
			.frame(width: 32, height: 32)
	}

	private func handleDaySelection(activities: [CalendarActivityDTO]) {
		// NEW LOGIC: Handle single vs multiple activities differently
		if activities.count == 1 {
			// Single activity - show activity detail modal directly
			let activity = activities[0]
			handleActivitySelection(activity)
		} else {
			// Multiple activities - navigate to day activities page
			selectedDayActivities = activities
			
			DispatchQueue.main.async {
				self.navigateToDayActivities = true
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



	// Get activities for a specific date
	private func getActivitiesForDate(_ date: Date) -> [CalendarActivityDTO] {
		_ = Calendar.current
		
		// Create a UTC calendar for consistent date comparison
		var utcCalendar = Calendar.current
		utcCalendar.timeZone = TimeZone(secondsFromGMT: 0)!
		
		let filteredActivities = profileViewModel.allCalendarActivities.filter { activity in
			// Use UTC calendar for consistent date comparison since backend sends UTC dates
			let isSameDay = utcCalendar.isDate(activity.dateAsDate, inSameDayAs: date)
			return isSameDay
		}
		
		return filteredActivities
	}

	private var weekDays: [String] {
		["S", "M", "T", "W", "T", "F", "S"]
	}

	private func fetchCalendarData() {
		Task {
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
