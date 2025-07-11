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

	init(apiService: IAPIService, activity: FullFeedActivityDTO, users: [BaseUserDTO]? = [], senderUserId: UUID) {
		self.apiService = apiService
		self.activity = activity
		self.users = users
		self.senderUserId = senderUserId
		
		// Check if user is already participating
		fetchIsParticipating()
	}
	
	func fetchIsParticipating() {
		// Check if the user is in the participants list
		if let participants = activity.participantUsers {
			isParticipating = participants.contains { $0.id == senderUserId }
		}
	}
	
	// MARK: - Optimistic Updates for Activity Editing
	
	/// Optimistically updates the activity title immediately in the UI
	func optimisticallyUpdateActivityTitle(_ newTitle: String) {
		activity.title = newTitle
		AppCache.shared.optimisticallyUpdateActivity(activity)
		print("⚡ Optimistically updated activity title to: \(newTitle)")
	}
	
	/// Optimistically updates the activity icon immediately in the UI
	func optimisticallyUpdateActivityIcon(_ newIcon: String) {
		activity.icon = newIcon
		AppCache.shared.optimisticallyUpdateActivity(activity)
		print("⚡ Optimistically updated activity icon to: \(newIcon)")
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
		print("⚡ Optimistically updated activity: title=\(title ?? "unchanged"), icon=\(icon ?? "unchanged")")
	}
	
	/// Saves activity changes to the backend
	func saveActivityChanges() async {
		await MainActor.run {
			isLoading = true
			errorMessage = nil
		}
		
		defer {
			Task { @MainActor in
				isLoading = false
			}
		}
		
		print("🔄 Attempting to save activity changes for ID: \(activity.id)")
		print("📝 Activity title: '\(activity.title ?? "nil")', icon: '\(activity.icon ?? "nil")'")
		print("📡 API Mode: \(MockAPIService.isMocking ? "MOCK" : "REAL")")
		
		guard let url = URL(string: APIService.baseURL + "activities/\(activity.id)") else {
			print("❌ Error: Invalid URL for activity update")
			await MainActor.run {
				errorMessage = "Invalid URL for activity update"
			}
			return
		}
		
		print("📡 Making API call to: \(url.absoluteString)")
		
		do {
			// Create a simple update DTO with just the fields we want to update
			let updateData = [
				"title": activity.title ?? "",
				"icon": activity.icon ?? ""
			]
			
			print("📦 Sending update data: \(updateData)")
			
			let updatedActivity: FullFeedActivityDTO = try await apiService.updateData(
				updateData, to: url, parameters: nil)
			
			print("✅ API call successful, received updated activity:")
			print("📋 Updated activity - ID: \(updatedActivity.id), Title: '\(updatedActivity.title ?? "nil")', Icon: '\(updatedActivity.icon ?? "nil")'")
			
			await MainActor.run {
				self.activity = updatedActivity
				// Update cache with confirmed changes
				AppCache.shared.addOrUpdateActivity(updatedActivity)
				print("✅ Successfully saved activity changes to backend")
			}
		} catch let error as APIError {
			print("❌ APIError saving activity changes: \(error)")
			await MainActor.run {
				switch error {
				case .invalidStatusCode(let statusCode):
					errorMessage = "Server error (status \(statusCode)). Please try again."
				case .invalidData:
					errorMessage = "Invalid data format. Please try again."
				case .URLError:
					errorMessage = "Network error. Please check your connection."
				case .failedHTTPRequest(let description):
					errorMessage = "Request failed: \(description)"
				case .failedJSONParsing:
					errorMessage = "Failed to parse server response. Please try again."
				case .unknownError(let error):
					errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
				case .failedTokenSaving:
					errorMessage = "Authentication error. Please try logging in again."
				}
			}
		} catch {
			print("❌ Unknown error saving activity changes: \(error)")
			print("❌ Error type: \(type(of: error))")
			print("❌ Error description: \(error.localizedDescription)")
			await MainActor.run {
				errorMessage = "Failed to save changes: \(error.localizedDescription)"
			}
		}
	}
	
	/// Clears any error messages
	@MainActor
	func clearError() {
		errorMessage = nil
	}
	
	func toggleParticipation() async {
		// Toggle participation status
		let newStatus = !isParticipating
		
		// Construct URL for participation API
		if let url = URL(string: APIService.baseURL + "activities/\(activity.id)/participation") {
			do {
				let parameters = ["status": newStatus ? "PARTICIPATING" : "NOT_PARTICIPATING"]
				_ = try await self.apiService.sendData(
					EmptyRequestBody(), to: url, parameters: parameters)
				
				// Update local state on success
				await MainActor.run {
					self.isParticipating = newStatus
				}
			} catch {
				print("Error toggling participation: \(error)")
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
			} catch {
				print("Error sending message: \(error)")
				await MainActor.run {
					creationMessage = "There was an error sending your chat message. Please try again"
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
			} catch {
				print("Error fetching updated activity data: \(error)")
			}
		}
	}
} 
