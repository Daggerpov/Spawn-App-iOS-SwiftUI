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
	@State private var hasPerformedInitialScroll = false
	@State private var scrollProxy: ScrollViewProxy?
	@State private var lastSelectedDate: Date?  // Track the last selected day's date
	@State private var isReturningFromNavigation = false  // Track if we're returning from day activities
	@State private var previousActivityCount = 0  // Track activity count changes
	@State private var targetScrollId: String?  // Track the target scroll position using stable ID

	var onDismiss: (() -> Void)?
	var onActivitySelected: ((CalendarActivityDTO) -> Void)?
	var onDayActivitiesSelected: ([CalendarActivityDTO]) -> Void

	/// Creates a stable identifier for a month (e.g., "2024-01")
	private func monthId(for date: Date) -> String {
		let calendar = Calendar.current
		let year = calendar.component(.year, from: date)
		let month = calendar.component(.month, from: date)
		return "\(year)-\(String(format: "%02d", month))"
	}

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
									onDayActivitiesSelected: { activities in
										// Save the selected date before navigating
										if let firstActivity = activities.first {
											lastSelectedDate = firstActivity.dateAsDate
										}
										// Call the parent's callback
										onDayActivitiesSelected(activities)
									}
								)
								.id(monthId(for: month))  // Use stable string ID instead of Date
							}
						}
						.padding(.horizontal, 8)
						.padding(.bottom, 16)  // Standard bottom padding
					}
					.onAppear {
						scrollProxy = proxy
						// Perform scroll when view appears
						// If returning from navigation, scroll to the last selected date
						// Otherwise wait for activities to load before scrolling
						if isReturningFromNavigation {
							scrollToMonth(containing: lastSelectedDate ?? Date(), animated: false)
							isReturningFromNavigation = false
						} else if !profileViewModel.allCalendarActivities.isEmpty {
							// Activities already loaded (cached), scroll to current month
							scrollToCurrentMonth(animated: false)
						}
						// Otherwise, wait for activities to load (onChange will trigger scroll)
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
		}
		.onDisappear {
			// Mark that we're returning from navigation (e.g., day activities view)
			isReturningFromNavigation = true
			// Reset the scroll flag so we scroll properly when coming back
			hasPerformedInitialScroll = false
		}
		.onChange(of: profileViewModel.allCalendarActivities) { oldActivities, newActivities in
			// When activities are first loaded (or change significantly), scroll to current month
			// This handles the case where monthsArray changes after activities load
			let activityCountChanged = oldActivities.count != newActivities.count
			let isFirstLoad = !hasPerformedInitialScroll && !newActivities.isEmpty

			if isFirstLoad || (activityCountChanged && previousActivityCount == 0) {
				scrollToCurrentMonth(animated: !hasPerformedInitialScroll)
			}
			previousActivityCount = newActivities.count
		}
	}

	/// Scrolls to the current month
	/// - Parameter animated: Whether to animate the scroll
	private func scrollToCurrentMonth(animated: Bool) {
		scrollToMonth(containing: Date(), animated: animated)
		hasPerformedInitialScroll = true
	}

	/// Scrolls to the month containing the specified date
	/// - Parameters:
	///   - date: The date whose month to scroll to
	///   - animated: Whether to animate the scroll
	private func scrollToMonth(containing date: Date, animated: Bool) {
		guard let proxy = scrollProxy else { return }

		// Use stable string ID for reliable scrolling (e.g., "2024-01")
		let targetId = monthId(for: date)

		// Use a small delay to ensure the ScrollView has rendered
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
			if animated {
				withAnimation(.easeInOut(duration: 0.5)) {
					proxy.scrollTo(targetId, anchor: .top)
				}
			} else {
				// Scroll instantly without animation
				proxy.scrollTo(targetId, anchor: .top)
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
