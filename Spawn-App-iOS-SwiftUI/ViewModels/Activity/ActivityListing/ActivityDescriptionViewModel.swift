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
	var apiService: IAPIService
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
		AppCache.shared.addOrUpdateActivity(updatedActivity)
		NotificationCenter.default.post(name: .activityUpdated, object: updatedActivity)
	}

	init(apiService: IAPIService, activity: FullFeedActivityDTO, users: [BaseUserDTO]? = [], senderUserId: UUID) {
		self.apiService = apiService
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

		// Update the activity in the cache
		AppCache.shared.addOrUpdateActivity(activity)

		// Notify UI
		objectWillChange.send()
	}

	/// Optimistically updates the activity icon immediately in the UI
	func optimisticallyUpdateActivityIcon(_ newIcon: String) {
		activity.icon = newIcon
		AppCache.shared.optimisticallyUpdateActivity(activity)
	}

	/// Optimistically updates both title and icon
	func optimisticallyUpdateActivity(title: String? = nil, icon: String? = nil) {
		if let title = title {
			activity.title = title
		}
		if let icon = icon {
			activity.icon = icon
		}
		AppCache.shared.optimisticallyUpdateActivity(activity)
	}

	/// Saves activity changes to the backend using partial update endpoint
	func saveActivityChanges() async {
		await setLoadingState(true)

		defer {
			Task { @MainActor in
				setLoadingState(false)
			}
		}

		print("📡 API Mode: \(MockAPIService.isMocking ? "MOCK" : "REAL")")

		guard let url = URL(string: APIService.baseURL + "activities/\(activity.id)/partial") else {
			print("❌ Error: Invalid URL for activity partial update")
			await setLoadingState(false, error: "Invalid URL for activity update")
			return
		}

		print("📡 Making API call to: \(url.absoluteString)")

		do {
			// Create a partial update DTO with just the fields we want to update
			let updateData = ActivityPartialUpdateDTO(
				title: activity.title ?? "",
				icon: activity.icon ?? ""
			)

			// Use PATCH method for partial updates
			let updatedActivity: FullFeedActivityDTO = try await apiService.patchData(
				from: url, with: updateData)

			await MainActor.run {
				self.activity = updatedActivity
				// Update cache with confirmed changes
				AppCache.shared.addOrUpdateActivity(updatedActivity)

				// Post notification for successful update immediately on main actor
				NotificationCenter.default.post(
					name: .activityUpdated,
					object: updatedActivity
				)
			}
		} catch let error as APIError {
			print("❌ API error saving activity changes: \(error)")
			print("❌ Error description: \(error.localizedDescription)")
			await MainActor.run {
				errorMessage = ErrorFormattingService.shared.formatAPIError(error)
			}
		} catch {
			print("❌ Unknown error saving activity changes: \(error)")
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

		// Use the correct API endpoint that matches the backend
		let urlString = "\(APIService.baseURL)activities/\(activity.id)/toggleStatus/\(senderUserId)"
		guard let url = URL(string: urlString) else {
			print("Invalid URL")
			return
		}

		do {
			// Send a PUT request and receive the updated activity in response
			let updatedActivity: FullFeedActivityDTO = try await apiService.updateData(
				EmptyRequestBody(), to: url, parameters: nil)

			// Update local state after a successful API call
			await updateActivityAfterAPISuccess(updatedActivity)
		} catch let error as APIError {
			await MainActor.run {
				// Handle specific API errors
				if case .invalidStatusCode(let statusCode) = error {
					if statusCode == 400 {
						// Activity is full
						NotificationCenter.default.post(
							name: NSNotification.Name("ShowActivityFullAlert"),
							object: nil,
							userInfo: ["message": "Sorry, this activity is full"]
						)
					} else {
						print("Error toggling participation (status \(statusCode)): \(error.localizedDescription)")
						self.errorMessage = "Failed to update participation status"
					}
				} else {
					print("Error toggling participation: \(error.localizedDescription)")
					self.errorMessage = "Failed to update participation status"
				}
			}
		} catch {
			await MainActor.run {
				print("Error toggling participation: \(error.localizedDescription)")
				self.errorMessage = ErrorFormattingService.shared.formatError(error)
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

		if let url = URL(string: APIService.baseURL + "chatMessages") {
			do {
				_ = try await self.apiService.sendData(
					chatMessage, to: url, parameters: nil)

				// After successfully sending the message, fetch the updated activity data
				await fetchUpdatedActivityData()

				// Clear any error message
				await MainActor.run {
					creationMessage = nil
				}
			} catch let error as APIError {
				print("Error sending message: \(error)")
				await MainActor.run {
					creationMessage = ErrorFormattingService.shared.formatAPIError(error)
				}
			} catch {
				print("Error sending message: \(error)")
				await MainActor.run {
					creationMessage = ErrorFormattingService.shared.formatError(error)
				}
			}
		}
	}

	// this method gets called after a chat message is sent, to update the
	// chat messages in the activity popup view, to include this chat message
	public func fetchUpdatedActivityData() async {
		if let url = URL(string: APIService.baseURL + "activities/\(activity.id)") {
			do {
				let updatedActivity: FullFeedActivityDTO = try await self.apiService.fetchData(
					from: url, parameters: ["requestingUserId": senderUserId.uuidString])

				// Update the activity on the main thread
				await MainActor.run {
					self.activity = updatedActivity
				}
			} catch let error as APIError {
				print("Error fetching updated activity data: \(ErrorFormattingService.shared.formatAPIError(error))")
			} catch {
				print("Error fetching updated activity data: \(ErrorFormattingService.shared.formatError(error))")
			}
		}
	}

	/// Reports the activity for inappropriate content
	func reportActivity(reporterUserId: UUID, reportType: ReportType, description: String) async {
		do {
			let reportingService = ReportingService(apiService: self.apiService)
			try await reportingService.reportActivity(
				reporterUserId: reporterUserId,
				activityId: activity.id,
				reportType: reportType,
				description: description
			)
			print("Activity reported successfully")
		} catch let error as APIError {
			await MainActor.run {
				errorMessage = ErrorFormattingService.shared.formatAPIError(error)
			}
		} catch {
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
