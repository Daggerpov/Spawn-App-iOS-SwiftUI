//
//  ActivityCardViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/6/24.
//

import Foundation

@Observable
@MainActor
final class ActivityCardViewModel {
	var isParticipating: Bool = false
	var dataService: DataService
	var userId: UUID
	var activity: FullFeedActivityDTO

	// MARK: - Helper Methods

	/// Updates activity and posts notification after successful API call
	private func updateActivityAfterAPISuccess(_ updatedActivity: FullFeedActivityDTO) {
		self.activity = updatedActivity
		self.isParticipating = updatedActivity.participationStatus == .participating
		NotificationCenter.default.post(name: .activityUpdated, object: updatedActivity)
	}

	/// Handles activity full error (400 status code)
	private func handleActivityFullError() {
		NotificationCenter.default.post(
			name: NSNotification.Name("ShowActivityFullAlert"),
			object: nil,
			userInfo: ["message": "Sorry, this activity is full"]
		)
	}

	init(userId: UUID, activity: FullFeedActivityDTO, dataService: DataService? = nil) {
		self.dataService = dataService ?? DataService.shared
		self.userId = userId
		self.activity = activity
		// Initialize the participation status correctly
		fetchIsParticipating()
	}

	/// returns whether the logged in app user is participating in the activity
	public func fetchIsParticipating() {
		// Use the participationStatus from the activity DTO instead of checking the participants array
		self.isParticipating = activity.participationStatus == .participating
	}

	/// Updates the activity object and refreshes participation status
	public func updateActivity(_ updatedActivity: FullFeedActivityDTO) {
		self.activity = updatedActivity
		fetchIsParticipating()
	}

	/// Reports the activity for inappropriate content
	func reportActivity(reporterUserId: UUID, reportType: ReportType, description: String) async {
		let reportDTO = CreateReportedContentDTO(
			reporterUserId: reporterUserId,
			contentId: activity.id,
			contentType: .activity,
			reportType: reportType,
			description: description
		)

		// Use DataService with WriteOperationType
		let result: DataResult<EmptyResponse> = await dataService.writeWithoutResponse(
			.reportActivity(report: reportDTO)
		)

		switch result {
		case .success:
			print("Activity reported successfully")
		case .failure(let error):
			print("Error reporting activity: \(ErrorFormattingService.shared.formatError(error))")
		}
	}

	/// Toggles the user's participation status in the activity
	public func toggleParticipation() async {
		if userId == activity.creatorUser.id {
			// Don't allow the creator to revoke participation in their event
			return
		}

		// Use DataService with WriteOperationType
		let result: DataResult<FullFeedActivityDTO> = await dataService.write(
			.toggleActivityParticipation(activityId: activity.id, userId: userId)
		)

		switch result {
		case .success(let updatedActivity, _):
			// Update local state after a successful API call
			updateActivityAfterAPISuccess(updatedActivity)

		case .failure(let error):
			// Handle specific API errors
			if let apiError = error as? APIError,
				case .invalidStatusCode(let statusCode) = apiError
			{
				if statusCode == 400 {
					// Activity is full
					handleActivityFullError()
				} else {
					print(
						"Error toggling participation (status \(statusCode)): \(ErrorFormattingService.shared.formatAPIError(apiError))"
					)
				}
			} else {
				print("Error toggling participation: \(ErrorFormattingService.shared.formatError(error))")
			}
		}
	}

	/// Deletes the activity
	public func deleteActivity() async throws {
		// Use DataService with WriteOperationType
		let result: DataResult<EmptyResponse> = await dataService.writeWithoutResponse(
			.deleteActivity(activityId: activity.id)
		)

		// Handle the result
		switch result {
		case .success:
			// Post notification for activity deletion
			NotificationCenter.default.post(
				name: .activityDeleted,
				object: activity.id
			)
		case .failure(let error):
			throw error
		}
	}
}
