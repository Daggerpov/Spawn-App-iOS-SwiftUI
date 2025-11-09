import SwiftUI

// Month view component
struct MonthView: View {
	let monthData: MonthData
	let today: Date
	let onDayTapped: ([CalendarActivityDTO]) -> Void

	private let calendar = Calendar.current

	// Get all days in the month
	private var daysInMonth: [Date] {
		guard calendar.dateInterval(of: .month, for: monthData.date) != nil,
			let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: monthData.date))
		else {
			return []
		}

		let numberOfDays = calendar.range(of: .day, in: .month, for: monthData.date)?.count ?? 30
		var days: [Date] = []

		for day in 1...numberOfDays {
			if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
				days.append(date)
			}
		}

		return days
	}

	var body: some View {
		VStack(spacing: 16) {
			// Month header
			HStack {
				Text(DateFormatter.monthYear.string(from: monthData.date))
					.font(.title2)
					.fontWeight(.semibold)
					.foregroundColor(.primary)

				Spacer()
			}

			// Days grid (4 columns)
			LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
				ForEach(daysInMonth, id: \.self) { date in
					DayCell(
						date: date,
						activities: activitiesForDate(date),
						isToday: calendar.isDate(date, inSameDayAs: today),
						onTapped: {
							let dayActivities = activitiesForDate(date)
							if !dayActivities.isEmpty {
								onDayTapped(dayActivities)
							}
						}
					)
				}
			}
		}
	}

	private func activitiesForDate(_ date: Date) -> [CalendarActivityDTO] {
		return monthData.activities.filter { activity in
			calendar.isDate(activity.dateAsDate, inSameDayAs: date)
		}
	}
}
