//
//  ActivityCardViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/6/24.
//

import Foundation

class ActivityCardViewModel: ObservableObject {
	@Published var isParticipating: Bool = false
	var apiService: IAPIService  // Keep temporarily for operations not yet in DataService
	var dataService: DataService
	var userId: UUID
	var activity: FullFeedActivityDTO

	// MARK: - Helper Methods

	/// Updates activity and posts notification after successful API call
	@MainActor
	private func updateActivityAfterAPISuccess(_ updatedActivity: FullFeedActivityDTO) {
		self.activity = updatedActivity
		self.isParticipating = updatedActivity.participationStatus == .participating
		NotificationCenter.default.post(name: .activityUpdated, object: updatedActivity)
	}

	/// Handles activity full error (400 status code)
	@MainActor
	private func handleActivityFullError() {
		NotificationCenter.default.post(
			name: NSNotification.Name("ShowActivityFullAlert"),
			object: nil,
			userInfo: ["message": "Sorry, this activity is full"]
		)
	}

	init(apiService: IAPIService, userId: UUID, activity: FullFeedActivityDTO, dataService: DataService? = nil) {
		self.apiService = apiService  // Keep for operations not yet in DataService
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
			print("Error reporting activity: \(ErrorFormattingService.shared.formatAPIError(error))")
		} catch {
			print("Error reporting activity: \(ErrorFormattingService.shared.formatError(error))")
		}
	}

	/// Toggles the user's participation status in the activity
	public func toggleParticipation() async {
		if userId == activity.creatorUser.id {
			// Don't allow the creator to revoke participation in their event
			return
		}
		let urlString =
			"\(APIService.baseURL)activities/\(activity.id)/toggleStatus/\(userId)"
		guard let url = URL(string: urlString) else {
			print("Invalid URL")
			return
		}

		do {
			// Send a PUT request and receive the updated activity in response
			let updatedActivity: FullFeedActivityDTO = try await apiService.updateData(
				EmptyBody(), to: url, parameters: nil)

			// Update local state after a successful API call
			await updateActivityAfterAPISuccess(updatedActivity)
		} catch let error as APIError {
			await MainActor.run {
				// Handle specific API errors
				if case .invalidStatusCode(let statusCode) = error {
					if statusCode == 400 {
						// Activity is full
						handleActivityFullError()
					} else {
						print(
							"Error toggling participation (status \(statusCode)): \(ErrorFormattingService.shared.formatAPIError(error))"
						)
					}
				} else {
					print("Error toggling participation: \(ErrorFormattingService.shared.formatAPIError(error))")
				}
			}
		} catch {
			await MainActor.run {
				print("Error toggling participation: \(ErrorFormattingService.shared.formatError(error))")
			}
		}
	}

	/// Deletes the activity
	@MainActor
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
