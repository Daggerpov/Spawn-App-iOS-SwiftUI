//
//  DayActivitiesViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-05-05.
//

import SwiftUI

@Observable
@MainActor
final class DayActivitiesViewModel {
	var activities: [CalendarActivityDTO] = []
	var headerTitle: String = "Activities"
	private var fetchedActivities: [UUID: FullFeedActivityDTO] = [:]

	private var dataService: DataService

	init(activities: [CalendarActivityDTO], dataService: DataService? = nil) {
		self.activities = activities
		self.dataService = dataService ?? DataService.shared

		// Set the header title when initialized
		updateHeaderTitle()
	}

	// MARK: - Constants
	private enum DateFormat {
		static let fullDate = "MMMM d, yyyy"
	}

	// MARK: - Helper Methods

	/// Formats a date using the standard date format
	private func formatDateString(_ date: Date) -> String {
		let formatter = DateFormatter()
		formatter.dateFormat = DateFormat.fullDate
		return formatter.string(from: date)
	}

	// Format the date for display in the header
	private func updateHeaderTitle() {
		if let firstActivity = activities.first {
			headerTitle = formatDateString(firstActivity.dateAsDate)
		} else {
			headerTitle = "Activities"
		}
	}

	// Format a specific date
	func formatDate(_ date: Date) -> String {
		return formatDateString(date)
	}

	// Fetch all activities directly via API without checking cache, using parallel requests for faster loading
	func loadActivitiesIfNeeded() async {
		// Use withTaskGroup to fetch all activities in parallel
		await withTaskGroup(of: Void.self) { group in
			for activity in activities {
				guard let activityId = activity.activityId else { continue }

				group.addTask {
					// Always fetch activity details via API
					await self.fetchActivity(activityId)
				}
			}
		}
	}

	func fetchActivity(_ activityId: UUID) async {
		guard let requestingUserId = UserAuthViewModel.shared.spawnUser?.id else {
			print("Error: No user ID available for fetching activity")
			return
		}

		// Use centralized DataType configuration
		let result: DataResult<FullFeedActivityDTO> = await dataService.read(
			.activity(activityId: activityId, requestingUserId: requestingUserId),
			cachePolicy: .cacheFirst(backgroundRefresh: true)
		)

		switch result {
		case .success(let activity, _):
			// Store in our own dictionary
			fetchedActivities[activityId] = activity

		case .failure(let error):
			print("Error fetching activity: \(ErrorFormattingService.shared.formatError(error))")
		}
	}

	func getActivity(for activityId: UUID) -> FullFeedActivityDTO? {
		// First check our own fetched activities
		if let activity = fetchedActivities[activityId] {
			return activity
		}

		// No need to check app cache since we're making direct API calls
		return nil
	}

	func isActivityLoading(_ activityId: UUID) -> Bool {
		// An activity is considered loading if it's not in our fetchedActivities dictionary
		// and we have been asked to fetch it (which is implied by checking)
		return fetchedActivities[activityId] == nil
	}
}
