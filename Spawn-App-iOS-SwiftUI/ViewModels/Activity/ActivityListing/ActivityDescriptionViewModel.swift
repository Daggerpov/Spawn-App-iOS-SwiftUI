//
//  ActivityDescriptionViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/9/24.
//

import Foundation

class ActivityDescriptionViewModel: ObservableObject {
	@Published var users: [BaseUserDTO]?
	var activity: FullFeedActivityDTO
	var senderUserId: UUID
	var dataService: DataService
	var creationMessage: String?
	@Published var isParticipating: Bool = false
	@Published var errorMessage: String?
	@Published var isLoading: Bool = false

	// MARK: - Helper Methods

	/// Sets loading state and optional error message
	@MainActor
	private func setLoadingState(_ loading: Bool, error: String? = nil) {
		isLoading = loading
		errorMessage = error
	}

	/// Updates activity and posts notification after successful API call
	@MainActor
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
	@MainActor
	func updateActivityTitle(_ newTitle: String) {
		activity.title = newTitle

		// Notify UI
		objectWillChange.send()
	}

	/// Optimistically updates the activity icon immediately in the UI
	func optimisticallyUpdateActivityIcon(_ newIcon: String) {
		activity.icon = newIcon
		objectWillChange.send()
	}

	/// Optimistically updates both title and icon
	func optimisticallyUpdateActivity(title: String? = nil, icon: String? = nil) {
		if let title = title {
			activity.title = title
		}
		if let icon = icon {
			activity.icon = icon
		}
		objectWillChange.send()
	}

	/// Saves activity changes to the backend using partial update endpoint
	func saveActivityChanges() async {
		await setLoadingState(true)

		defer {
			Task { @MainActor in
				setLoadingState(false)
			}
		}

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
			await MainActor.run {
				self.activity = updatedActivity

				// Post notification for successful update immediately on main actor
				NotificationCenter.default.post(
					name: .activityUpdated,
					object: updatedActivity
				)
			}

		case .failure(let error):
			print("❌ Error saving activity changes: \(error)")
			await MainActor.run {
				errorMessage = ErrorFormattingService.shared.formatError(error)
			}
		}
	}

	/// Clears any error messages
	@MainActor
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
			await updateActivityAfterAPISuccess(updatedActivity)

		case .failure(let error):
			await MainActor.run {
				// Check if it's an activity full error (status 400)
				if let dataError = error as? DataError,
					case .apiError(let apiError) = dataError,
					case .invalidStatusCode(let statusCode) = apiError,
					statusCode == 400
				{
					// Activity is full
					NotificationCenter.default.post(
						name: NSNotification.Name("ShowActivityFullAlert"),
						object: nil,
						userInfo: ["message": "Sorry, this activity is full"]
					)
				} else {
					print("Error toggling participation: \(error)")
					self.errorMessage = "Failed to update participation status"
				}
			}
		}
	}

	func sendMessage(message: String) async {
		// Validate the message is not empty
		guard !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
			print("Cannot send empty message")
			await MainActor.run {
				creationMessage = "Cannot send an empty message"
			}
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
			await MainActor.run {
				creationMessage = nil
			}

		case .failure(let error):
			print("Error sending message: \(error)")
			await MainActor.run {
				creationMessage = ErrorFormattingService.shared.formatError(error)
			}
		}
	}

	// this method gets called after a chat message is sent, to update the
	// chat messages in the activity popup view, to include this chat message
	public func fetchUpdatedActivityData() async {
		// Use DataService to fetch the updated activity (this should be a read operation)
		// For now, we'll keep the direct fetch, but this could be optimized later
		// by adding a DataType for single activity fetch
		let result: DataResult<[FullFeedActivityDTO]> = await dataService.read(
			.activities(userId: senderUserId, filterType: .all),
			cachePolicy: .networkOnly
		)

		switch result {
		case .success(let activities, _):
			// Find the updated activity in the list
			if let updatedActivity = activities.first(where: { $0.id == activity.id }) {
				await MainActor.run {
					self.activity = updatedActivity
				}
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
			await MainActor.run {
				errorMessage = ErrorFormattingService.shared.formatError(error)
			}
		}
	}

	/// Updates the activity object and refreshes participation status
	public func updateActivity(_ updatedActivity: FullFeedActivityDTO) {
		self.activity = updatedActivity
		fetchIsParticipating()
	}
}
