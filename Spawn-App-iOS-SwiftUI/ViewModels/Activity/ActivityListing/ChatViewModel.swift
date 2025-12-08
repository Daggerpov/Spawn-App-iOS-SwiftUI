//
//  ChatViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Shane on 6/20/25.
//

import Foundation
import Observation
import SwiftUI

@Observable
@MainActor
final class ChatViewModel {
	private let dataService: DataService
	private let senderUserId: UUID
	// Note: activity is still ObservableObject; will be migrated separately
	private var activity: FullFeedActivityDTO

	var chats: [FullActivityChatMessageDTO] {
		activity.chatMessages ?? []
	}
	var creationMessage: String?

	// MARK: - Constants
	private enum ErrorMessages {
		static let emptyMessage = "Cannot send an empty message"
		static let sendError = "There was an error sending your chat message. Please try again."
		static let refreshError = "Unable to load messages. Please try again."
		static let invalidConfig = "Invalid server configuration. Please contact support."
		static let genericSendError = "Error sending message. Please try again."
	}

	init(senderUserId: UUID, activity: FullFeedActivityDTO, dataService: DataService? = nil) {
		self.senderUserId = senderUserId
		self.activity = activity
		self.dataService = dataService ?? DataService.shared
	}

	// MARK: - Helper Methods

	/// Set error message
	private func setErrorMessage(_ message: String?) {
		creationMessage = message
	}

	/// Add or update chat message in activity
	private func addChatMessage(_ newMessage: FullActivityChatMessageDTO) {
		if let existingMessages = activity.chatMessages,
			!existingMessages.contains(where: { $0.id == newMessage.id })
		{
			activity.chatMessages?.append(newMessage)
		} else if activity.chatMessages == nil {
			activity.chatMessages = [newMessage]
		}
	}

	func sendMessage(message: String) async {
		// Clear any previous error message
		setErrorMessage(nil)

		// Validate the message is not empty
		let trimmedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
		guard !trimmedMessage.isEmpty else {
			print("Cannot send empty message")
			setErrorMessage(ErrorMessages.emptyMessage)
			return
		}

		// Create chat message
		let chatMessage = CreateChatMessageDTO(
			content: trimmedMessage,
			senderUserId: senderUserId,
			activityId: activity.id
		)

		// Use DataService with WriteOperationType
		let operationType = WriteOperationType.sendChatMessage(message: chatMessage)
		let result: DataResult<FullActivityChatMessageDTO> = await dataService.write(
			operationType, body: chatMessage)

		switch result {
		case .success(let newChatMessage, _):
			// Add message and clear error
			addChatMessage(newChatMessage)
			creationMessage = nil

		case .failure(let error):
			print("Error sending message: \(error)")
			setErrorMessage(ErrorMessages.sendError)
		}
	}

	func refreshChat() async {
		// Use DataService to fetch activity chats
		let result: DataResult<[FullActivityChatMessageDTO]> = await dataService.read(
			.activityChats(activityId: activity.id),
			cachePolicy: .apiOnly  // Always fetch latest chat messages
		)

		switch result {
		case .success(let chats, source: _):
			// Only update if we actually got data
			if !chats.isEmpty || activity.chatMessages?.isEmpty == true {
				activity.chatMessages = chats
			}
			// Clear any error messages on successful refresh
			creationMessage = nil
		case .failure(let error):
			print("Error refreshing chats: \(error)")
			// Only show refresh error if there are no existing messages
			if activity.chatMessages?.isEmpty != false {
				setErrorMessage(ErrorMessages.refreshError)
			}
		}
	}
}
