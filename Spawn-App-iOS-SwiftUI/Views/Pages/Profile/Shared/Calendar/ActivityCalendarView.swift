//
//  ActivityCalendarView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/14/24.
//

import SwiftUI

struct ActivityCalendarView: View {
	var profileViewModel: ProfileViewModel
	@ObservedObject var userAuth = UserAuthViewModel.shared
	@Environment(\.colorScheme) var colorScheme
	@Environment(\.dismiss) private var dismiss

	let userCreationDate: Date?
	let calendarOwnerName: String?

	@State private var currentMonth = Date()
	@State private var scrollOffset: CGFloat = 0
	@State private var hasInitiallyScrolled = false
	@State private var scrollProxy: ScrollViewProxy?
	@State private var isFirstAppearance = true

	var onDismiss: (() -> Void)?
	var onActivitySelected: ((CalendarActivityDTO) -> Void)?
	var onDayActivitiesSelected: ([CalendarActivityDTO]) -> Void

	var body: some View {
		ZStack {
			universalBackgroundColor
				.ignoresSafeArea()

			VStack(spacing: 0) {
				// Scrollable calendar content
				ScrollViewReader { proxy in
					ScrollView {
						LazyVStack(spacing: 32) {
							ForEach(monthsArray, id: \.self) { month in
								MonthCalendarView(
									month: month,
									profileViewModel: profileViewModel,
									userAuth: userAuth,
									onActivitySelected: onActivitySelected,
									onDayActivitiesSelected: onDayActivitiesSelected
								)
								.id(month)
							}
						}
						.padding(.horizontal, 8)
						.padding(.bottom, 16)  // Standard bottom padding
					}
					.onAppear {
						scrollProxy = proxy
						scrollToCurrentMonth(animated: isFirstAppearance)
					}
				}
			}
		}
		.navigationTitle(
			calendarOwnerName != nil ? "\(calendarOwnerName!)'s Activity Calendar" : "Your Activity Calendar"
		)
		.navigationBarTitleDisplayMode(.inline)
		.onAppear {
			// Fetch calendar data for current and upcoming months
			fetchCalendarData()

			// Reset scroll state when view reappears (e.g., returning from day activities)
			// This ensures we scroll to current month when coming back
			hasInitiallyScrolled = false
		}
		.onDisappear {
			// Mark that subsequent appearances are not the first
			isFirstAppearance = false
			// Reset navigation state when leaving the calendar view
			// This prevents the NavigationLink from getting stuck in active state
			onDismiss?()
		}
		.onChange(of: profileViewModel.allCalendarActivities) { _, _ in
			// When activities are loaded, scroll to current month (with animation on first load)
			if !hasInitiallyScrolled {
				scrollToCurrentMonth(animated: true)
			}
		}
	}

	/// Scrolls to the current month
	/// - Parameter animated: Whether to animate the scroll
	private func scrollToCurrentMonth(animated: Bool) {
		guard !hasInitiallyScrolled, let proxy = scrollProxy else { return }

		let today = Date()
		if let currentMonthDate = monthsArray.first(where: { month in
			Calendar.current.isDate(month, equalTo: today, toGranularity: .month)
		}) {
			// Use a small delay to ensure the ScrollView has rendered
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
				if animated {
					withAnimation(.easeInOut(duration: 0.5)) {
						proxy.scrollTo(currentMonthDate, anchor: .top)
					}
				} else {
					// Scroll instantly without animation when returning from navigation
					proxy.scrollTo(currentMonthDate, anchor: .top)
				}
				hasInitiallyScrolled = true
			}
		}
	}

	/// Computes the earliest date to show in the calendar based on:
	/// 1. The user's first activity date (if available)
	/// 2. The user's account creation date (if available)
	/// 3. Falls back to 6 months ago as a reasonable default
	private var earliestDateToShow: Date {
		let calendar = Calendar.current
		let today = Date()

		// First, try to get the earliest activity date from loaded activities
		if !profileViewModel.allCalendarActivities.isEmpty {
			let activityDates = profileViewModel.allCalendarActivities.map { $0.dateAsDate }
			if let earliestActivityDate = activityDates.min() {
				// Use the first day of the month containing the earliest activity
				let components = calendar.dateComponents([.year, .month], from: earliestActivityDate)
				if let firstDayOfMonth = calendar.date(from: components) {
					return firstDayOfMonth
				}
			}
		}

		// Second, fall back to user creation date if available
		if let userCreationDate = userCreationDate {
			let components = calendar.dateComponents([.year, .month], from: userCreationDate)
			if let firstDayOfMonth = calendar.date(from: components) {
				return firstDayOfMonth
			}
		}

		// Finally, fall back to 6 months ago as a reasonable default for new users
		return calendar.date(byAdding: .month, value: -6, to: today) ?? today
	}

	private var monthsArray: [Date] {
		let calendar = Calendar.current
		let today = Date()
		var months: [Date] = []

		let earliestDate = earliestDateToShow

		// Calculate how many months back we can go from today to the earliest date
		let monthsFromEarliestToToday = calendar.dateComponents([.month], from: earliestDate, to: today).month ?? 0
		let maxMonthsBack = max(0, monthsFromEarliestToToday)

		// Go back to the earliest date and forward 1 month into the future
		let startIndex = -maxMonthsBack
		let endIndex = 1

		for i in startIndex...endIndex {
			if let date = calendar.date(byAdding: .month, value: i, to: today) {
				months.append(date)
			}
		}

		return months
	}

	private func fetchCalendarData() {
		Task {
			await profileViewModel.fetchAllCalendarActivities()
		}
	}

}

#Preview {
	ActivityCalendarView(
		profileViewModel: ProfileViewModel(userId: UUID()),
		userCreationDate: nil,
		calendarOwnerName: nil,
		onDismiss: {},
		onActivitySelected: { _ in },
		onDayActivitiesSelected: { _ in }
	)
}
