//
//  ActivityDescriptionViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/9/24.
//

import Foundation

@Observable
@MainActor
final class ActivityDescriptionViewModel {
	var users: [BaseUserDTO]?
	var activity: FullFeedActivityDTO
	var senderUserId: UUID
	var dataService: DataService
	var creationMessage: String?
	var isParticipating: Bool = false
	var errorMessage: String?
	var isLoading: Bool = false

	private let errorNotificationService = ErrorNotificationService.shared

	// MARK: - Helper Methods

	/// Sets loading state and optional error message
	private func setLoadingState(_ loading: Bool, error: String? = nil) {
		isLoading = loading
		errorMessage = error
	}

	/// Updates activity and posts notification after successful API call
	private func updateActivityAfterAPISuccess(_ updatedActivity: FullFeedActivityDTO) {
		self.activity = updatedActivity
		self.isParticipating = updatedActivity.participationStatus == .participating
		NotificationCenter.default.post(name: .activityUpdated, object: updatedActivity)
	}

	init(
		activity: FullFeedActivityDTO, users: [BaseUserDTO]? = [], senderUserId: UUID,
		dataService: DataService? = nil
	) {
		self.dataService = dataService ?? DataService.shared
		self.activity = activity
		self.users = users
		self.senderUserId = senderUserId

		// Check if user is already participating
		fetchIsParticipating()
	}

	func fetchIsParticipating() {
		// Use the participationStatus from the activity DTO instead of checking the participants array
		// This ensures consistency with ActivityCardViewModel
		isParticipating = activity.participationStatus == .participating
	}

	// MARK: - Optimistic Updates for Activity Editing

	/// Optimistically updates the activity title
	func updateActivityTitle(_ newTitle: String) {
		activity.title = newTitle
	}

	/// Optimistically updates the activity icon immediately in the UI
	func optimisticallyUpdateActivityIcon(_ newIcon: String) {
		activity.icon = newIcon
	}

	/// Optimistically updates both title and icon
	func optimisticallyUpdateActivity(title: String? = nil, icon: String? = nil) {
		if let title = title {
			activity.title = title
		}
		if let icon = icon {
			activity.icon = icon
		}
	}

	/// Saves activity changes to the backend using partial update endpoint
	func saveActivityChanges() async {
		setLoadingState(true)

		defer { setLoadingState(false) }

		print("📡 Saving activity changes using DataService")

		// Create a partial update DTO with just the fields we want to update
		let updateData = ActivityPartialUpdateDTO(
			title: activity.title ?? "",
			icon: activity.icon ?? ""
		)

		// Use DataService with WriteOperationType
		let operationType = WriteOperationType.partialUpdateActivity(activityId: activity.id, update: updateData)
		let result: DataResult<FullFeedActivityDTO> = await dataService.write(
			operationType, body: updateData)

		switch result {
		case .success(let updatedActivity, _):
			self.activity = updatedActivity

			// Post notification for successful update immediately on main actor
			NotificationCenter.default.post(
				name: .activityUpdated,
				object: updatedActivity
			)

		case .failure(let error):
			print("❌ Error saving activity changes: \(error)")
			errorMessage = errorNotificationService.handleError(
				error, resource: .activity, operation: .update)
		}
	}

	/// Clears any error messages
	func clearError() {
		errorMessage = nil
	}

	func toggleParticipation() async {
		if senderUserId == activity.creatorUser.id {
			// Don't allow the creator to revoke participation in their event
			return
		}

		// Use DataService with WriteOperationType
		let operationType = WriteOperationType.toggleActivityParticipation(
			activityId: activity.id, userId: senderUserId)
		let result: DataResult<FullFeedActivityDTO> = await dataService.write(operationType)

		switch result {
		case .success(let updatedActivity, _):
			// Update local state after a successful API call
			updateActivityAfterAPISuccess(updatedActivity)

		case .failure(let error):
			// Check if it's an activity full error (status 400)
			if let dataError = error as? DataServiceError,
				case .apiFailed(let apiError) = dataError,
				let apiErrorTyped = apiError as? APIError,
				case .invalidStatusCode(let statusCode) = apiErrorTyped,
				statusCode == 400
			{
				// Activity is full - show notification via the existing handler
				NotificationCenter.default.post(
					name: NSNotification.Name("ShowActivityFullAlert"),
					object: nil,
					userInfo: ["message": "Sorry, this activity is full"]
				)
			} else {
				print("Error toggling participation: \(error)")
				self.errorMessage = errorNotificationService.handleError(
					error, resource: .activity, operation: .join)
			}
		}
	}

	func sendMessage(message: String) async {
		// Validate the message is not empty
		guard !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
			print("Cannot send empty message")
			creationMessage = "Cannot send an empty message"
			return
		}

		let trimmedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
		let chatMessage: CreateChatMessageDTO = CreateChatMessageDTO(
			content: trimmedMessage,
			senderUserId: senderUserId,
			activityId: activity.id
		)

		// Use DataService with WriteOperationType
		let operationType = WriteOperationType.sendChatMessage(message: chatMessage)
		let result: DataResult<FullActivityChatMessageDTO> = await dataService.write(
			operationType, body: chatMessage)

		switch result {
		case .success:
			// After successfully sending the message, fetch the updated activity data
			await fetchUpdatedActivityData()

			// Clear any error message
			creationMessage = nil

		case .failure(let error):
			print("Error sending message: \(error)")
			creationMessage = errorNotificationService.handleError(
				error, resource: .message, operation: .send)
		}
	}

	// this method gets called after a chat message is sent, to update the
	// chat messages in the activity popup view, to include this chat message
	public func fetchUpdatedActivityData() async {
		// Use DataService to fetch the updated activity (this should be a read operation)
		// For now, we'll keep the direct fetch, but this could be optimized later
		// by adding a DataType for single activity fetch
		let result: DataResult<[FullFeedActivityDTO]> = await dataService.read(
			.activities(userId: senderUserId),
			cachePolicy: .apiOnly
		)

		switch result {
		case .success(let activities, _):
			// Find the updated activity in the list
			if let updatedActivity = activities.first(where: { $0.id == activity.id }) {
				self.activity = updatedActivity
			}

		case .failure(let error):
			print("Error fetching updated activity data: \(ErrorFormattingService.shared.formatError(error))")
		}
	}

	/// Reports the activity for inappropriate content
	func reportActivity(reporterUserId: UUID, reportType: ReportType, description: String) async {
		// Create report DTO
		let report = CreateReportedContentDTO(
			reporterUserId: reporterUserId,
			contentId: activity.id,
			contentType: .activity,
			reportType: reportType,
			description: description
		)

		// Use DataService with WriteOperationType
		let operationType = WriteOperationType.reportActivity(report: report)
		let result: DataResult<EmptyResponse> = await dataService.writeWithoutResponse(operationType)

		switch result {
		case .success:
			print("Activity reported successfully")

		case .failure(let error):
			errorMessage = errorNotificationService.handleError(
				error, resource: .report, operation: .send)
		}
	}

	/// Updates the activity object and refreshes participation status
	public func updateActivity(_ updatedActivity: FullFeedActivityDTO) {
		self.activity = updatedActivity
		fetchIsParticipating()
	}
}
