import SwiftUI

// Calendar day cell component matching Figma design
struct CalendarDayCell: View {
	let activities: [CalendarActivityDTO]
	let dayNumber: Int

	@Environment(\.colorScheme) private var colorScheme

	// MARK: - Theme-aware colors

	private var cellTextColor: Color {
		// Use dark text on colored backgrounds for readability
		Color.black
	}

	private var shadowOpacity: Double {
		colorScheme == .dark ? 0.3 : 0.1
	}

	var body: some View {
		ZStack {
			if activities.count == 1, !activities.isEmpty {
				// Single activity - show its icon and color
				let activity = activities[0]
				RoundedRectangle(cornerRadius: 7)
					.fill(activityColor(for: activity))
					.frame(width: 46, height: 46)
					.shadow(color: Color.black.opacity(shadowOpacity), radius: 7, x: 0, y: 1.65)
					.overlay(
						activityIcon(for: activity)
							.font(.onestMedium(size: 26))
							.foregroundColor(cellTextColor)
					)
			} else if activities.count > 1, !activities.isEmpty {
				// Multiple activities - show primary activity color with count
				let primaryActivity = activities[0]
				RoundedRectangle(cornerRadius: 7)
					.fill(activityColor(for: primaryActivity))
					.frame(width: 46, height: 46)
					.shadow(color: Color.black.opacity(shadowOpacity), radius: 7, x: 0, y: 1.65)
					.overlay(
						VStack(spacing: 0) {
							activityIcon(for: primaryActivity)
								.font(.onestMedium(size: 20))
								.foregroundColor(cellTextColor)
							Text("\(activities.count)")
								.font(.onestMedium(size: 10))
								.foregroundColor(cellTextColor)
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
