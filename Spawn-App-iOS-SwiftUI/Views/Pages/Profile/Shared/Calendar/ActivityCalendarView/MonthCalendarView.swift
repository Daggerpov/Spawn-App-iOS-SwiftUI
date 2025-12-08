import SwiftUI

struct MonthCalendarView: View {
	let month: Date
	var profileViewModel: ProfileViewModel
	@ObservedObject var userAuth: UserAuthViewModel
	let onActivitySelected: ((CalendarActivityDTO) -> Void)?
	let onDayActivitiesSelected: ([CalendarActivityDTO]) -> Void

	var body: some View {
		VStack(alignment: .leading, spacing: 16) {
			// Month header
			Text(monthYearString())
				.font(.onestMedium(size: 16))
				.foregroundColor(figmaBlack300)
				.padding(.leading, 8)

			// Calendar grid - 4 days per row
			VStack(spacing: 8) {
				ForEach(0..<numberOfRows, id: \.self) { rowIndex in
					HStack(spacing: 8) {
						ForEach(0..<4, id: \.self) { dayIndex in
							let dayOffset = rowIndex * 4 + dayIndex
							let day = dayForOffset(dayOffset)

							CalendarDayTile(
								day: day,
								activities: getActivitiesForDay(day),
								isCurrentMonth: isCurrentMonth(day),
								tileSize: 86.4,  // Fixed tile size matching Figma specs
								onDayTapped: { activities in
									if activities.count == 1 {
										// Use the callback for single activities
										if let activity = activities.first {
											onActivitySelected?(activity)
										}
									} else if activities.count > 1 {
										onDayActivitiesSelected(activities)
									}
								}
							)
						}
					}
				}
			}
			.padding(.horizontal, 8)
		}
		.frame(maxWidth: .infinity)
	}

	private var numberOfRows: Int {
		let calendar = Calendar.current
		let range = calendar.range(of: .day, in: .month, for: month) ?? 1..<32
		let daysInMonth = range.count

		// Calculate number of rows needed for 4 days per row
		return Int(ceil(Double(daysInMonth) / 4.0))
	}

	private func dayForOffset(_ offset: Int) -> Date {
		let calendar = Calendar.current
		let firstOfMonth = calendar.dateInterval(of: .month, for: month)?.start ?? month

		return calendar.date(byAdding: .day, value: offset, to: firstOfMonth) ?? firstOfMonth
	}

	private func isCurrentMonth(_ date: Date) -> Bool {
		let calendar = Calendar.current
		return calendar.isDate(date, equalTo: month, toGranularity: .month)
	}

	private func getActivitiesForDay(_ date: Date) -> [CalendarActivityDTO] {
		// Use local calendar for date comparison since CalendarActivityDTO now uses local timezone
		let calendar = Calendar.current

		let filteredActivities = profileViewModel.allCalendarActivities.filter { activity in
			// Use local calendar for consistent date comparison since we now convert to local timezone
			calendar.isDate(activity.dateAsDate, inSameDayAs: date)
		}

		// Add debug logging for this view as well
		if !filteredActivities.isEmpty {
			print(
				"📅 ActivityCalendarView: Day \(Calendar.current.component(.day, from: date)) has \(filteredActivities.count) activities"
			)
		}

		return filteredActivities
	}

	private func monthYearString() -> String {
		let formatter = DateFormatter()
		formatter.dateFormat = "MMMM yyyy"
		return formatter.string(from: month)
	}
}
