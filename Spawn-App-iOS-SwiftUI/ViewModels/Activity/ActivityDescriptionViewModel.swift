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
