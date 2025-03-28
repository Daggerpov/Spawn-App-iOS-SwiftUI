//
//  EventDescriptionViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/9/24.
//

import Foundation

class EventDescriptionViewModel: ObservableObject {
	@Published var users: [BaseUserDTO]?
	var event: FullFeedEventDTO
	var senderUserId: UUID
	var apiService: IAPIService
	var creationMessage: String?
	@Published var isParticipating: Bool = false

	init(apiService: IAPIService, event: FullFeedEventDTO, users: [BaseUserDTO]? = [], senderUserId: UUID) {
		self.apiService = apiService
		self.event = event
		self.users = users
		self.senderUserId = senderUserId
		
		// Check if user is already participating
		fetchIsParticipating()
	}
	
	func fetchIsParticipating() {
		// Check if the user is in the participants list
		if let participants = event.participantUsers {
			isParticipating = participants.contains { $0.id == senderUserId }
		}
	}
	
	func toggleParticipation() async {
		// Toggle participation status
		let newStatus = !isParticipating
		
		// Construct URL for participation API
		if let url = URL(string: APIService.baseURL + "events/\(event.id)/participation") {
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
			eventId: event.id
		)
		
		if let url = URL(string: APIService.baseURL + "chatMessages") {
			do {
				_ = try await self.apiService.sendData(
					chatMessage, to: url, parameters: nil)
				
				// After successfully sending the message, fetch the updated event data
				await fetchUpdatedEventData()
				
				// Generate a local notification for testing
				if !MockAPIService.isMocking {
					generateLocalChatNotification(message: trimmedMessage)
				}
				
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

	// Generate a local notification for a chat message (for testing purposes)
	private func generateLocalChatNotification(message: String) {
		// In a real app, this notification would come from the server
		// This is just for local testing of the notification UI
		
		// Only proceed if chat notifications are enabled in user preferences
		guard NotificationService.shared.chatMessagesEnabled else {
			print("Chat notifications are disabled by user preference")
			return
		}
		
		// Only show notification for messages from other users (not the current user)
		// In a real app, the server would handle this logic
		Task { @MainActor in
			// Add a slight delay to simulate server processing
			try? await Task.sleep(nanoseconds: 1_000_000_000)
			
			// Create notification with event and sender info
			let notificationTitle = "New message in \(event.title ?? "an event you created")"
			let notificationBody = "@\(event.creatorUser.username): \(message)"
			
			// Use the NotificationDataBuilder for consistent notification structure
			let userInfo = NotificationDataBuilder.chatMessage(
				eventId: event.id,
				senderId: event.creatorUser.id
			)
			
			// Schedule the notification
			NotificationService.shared.scheduleLocalNotification(
				title: notificationTitle,
				body: notificationBody,
				userInfo: userInfo
			)
		}
	}

	// this method gets called after a chat message is sent, to update the
	// chat messages in the event popup view, to include this chat message
	private func fetchUpdatedEventData() async {
		if let url = URL(string: APIService.baseURL + "events/\(event.id)") {
			do {
				let updatedEvent: FullFeedEventDTO = try await self.apiService.fetchData(
                    from: url, parameters: ["requestingUserId": senderUserId.uuidString])
				
				// Update the event on the main thread
				await MainActor.run {
					self.event = updatedEvent
				}
			} catch {
				print("Error fetching updated event data: \(error)")
			}
		}
	}
}
