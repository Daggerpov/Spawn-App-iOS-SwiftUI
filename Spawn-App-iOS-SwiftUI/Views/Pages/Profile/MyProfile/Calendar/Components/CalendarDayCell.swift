import SwiftUI

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
		// Use the same logic as the feed view - always use ActivityColorService assignment
		// Priority: activityId first (main activity), then calendar activity id as fallback
		if let activityId = activity.activityId {
			return getActivityColor(for: activityId)
		}

		// For calendar-only activities without activityId, use the calendar activity's own id
		return getActivityColor(for: activity.id)

		// Note: We ignore backend colorHexCode entirely like the feed view does
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
