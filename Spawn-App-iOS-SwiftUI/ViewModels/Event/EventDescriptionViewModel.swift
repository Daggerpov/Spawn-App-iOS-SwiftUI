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
		let chatMessage: CreateChatMessageDTO = CreateChatMessageDTO(
			content: message,
			senderUserId: senderUserId,
			eventId: event.id
		)
		if let url = URL(string: APIService.baseURL + "chatMessages") {
			do {
				_ = try await self.apiService.sendData(
					chatMessage, to: url, parameters: nil)
			} catch {
				await MainActor.run {
					creationMessage =
					"There was an error sending your chat message. Please try again"
				}
			}
		}
	}
}
