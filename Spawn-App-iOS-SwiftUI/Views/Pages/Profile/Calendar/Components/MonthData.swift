import SwiftUI

// Data structure for each month
struct MonthData: Identifiable {
	let id = UUID()
	let date: Date
	let activities: [CalendarActivityDTO]
}
