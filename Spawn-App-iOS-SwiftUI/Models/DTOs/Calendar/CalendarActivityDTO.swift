import Foundation
import SwiftUI

struct CalendarActivityDTO: Codable, Identifiable, Sendable, Equatable {
	let id: UUID
	let date: String  // ISO format: YYYY-MM-DD (matches backend)
	let title: String?
	let icon: String?
	let colorHexCode: String?
	var activityId: UUID?

	// Computed property to get Date object from string
	var dateAsDate: Date {
		let formatter = DateFormatter()
		formatter.dateFormat = "yyyy-MM-dd"
		formatter.timeZone = TimeZone.current  // Use current timezone for display
		return formatter.date(from: date) ?? Date()
	}

	// Helper to create CalendarActivityDTO with Date input
	static func create(
		id: UUID,
		date: Date,
		title: String? = nil,
		icon: String? = nil,
		colorHexCode: String? = nil,
		activityId: UUID? = nil
	) -> CalendarActivityDTO {
		let formatter = DateFormatter()
		formatter.dateFormat = "yyyy-MM-dd"
		formatter.timeZone = TimeZone.current  // Convert to user's local timezone

		return CalendarActivityDTO(
			id: id,
			date: formatter.string(from: date),
			title: title,
			icon: icon,
			colorHexCode: colorHexCode,
			activityId: activityId
		)
	}
}
