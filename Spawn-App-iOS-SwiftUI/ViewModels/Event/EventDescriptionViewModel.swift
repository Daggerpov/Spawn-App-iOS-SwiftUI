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

	init(apiService: IAPIService, event: FullFeedEventDTO, users: [BaseUserDTO]? = [], senderUserId: UUID) {
		self.apiService = apiService
		self.event = event
		self.users = users
		self.senderUserId = senderUserId
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
