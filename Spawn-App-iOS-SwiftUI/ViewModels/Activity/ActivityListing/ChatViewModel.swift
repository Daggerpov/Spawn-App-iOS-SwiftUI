//
//  ChatViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Shane on 6/20/25.
//

import Foundation
import SwiftUI

class ChatViewModel: ObservableObject {
	private let apiService: IAPIService
	private let senderUserId: UUID
	@ObservedObject private var activity: FullFeedActivityDTO

	var chats: [FullActivityChatMessageDTO] {
		activity.chatMessages ?? []
	}
	@Published var creationMessage: String?

	// MARK: - Constants
	private enum ErrorMessages {
		static let emptyMessage = "Cannot send an empty message"
		static let sendError = "There was an error sending your chat message. Please try again."
		static let refreshError = "Unable to load messages. Please try again."
		static let invalidConfig = "Invalid server configuration. Please contact support."
		static let genericSendError = "Error sending message. Please try again."
	}

	init(senderUserId: UUID, activity: FullFeedActivityDTO) {
		self.senderUserId = senderUserId
		self.activity = activity
		apiService = MockAPIService.isMocking ? MockAPIService(userId: senderUserId) : APIService()
	}

	// MARK: - Helper Methods

	/// Set error message on main actor
	private func setErrorMessage(_ message: String?) async {
		await MainActor.run {
			creationMessage = message
		}
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
		await setErrorMessage(nil)

		// Validate the message is not empty
		let trimmedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
		guard !trimmedMessage.isEmpty else {
			print("Cannot send empty message")
			await setErrorMessage(ErrorMessages.emptyMessage)
			return
		}

		// Construct URL
		guard let url = URL(string: APIService.baseURL + "chatMessages") else {
			await setErrorMessage(ErrorMessages.invalidConfig)
			return
		}

		// Create chat message
		let chatMessage = CreateChatMessageDTO(
			content: trimmedMessage,
			senderUserId: senderUserId,
			activityId: activity.id
		)

		do {
			let response: FullActivityChatMessageDTO? = try await apiService.sendData(
				chatMessage, to: url, parameters: nil)

			await MainActor.run {
				guard let newChatMessage = response else {
					print("Error: No chat received from API after creating chat message")
					creationMessage = ErrorMessages.genericSendError
					return
				}

				// Add message and clear error
				addChatMessage(newChatMessage)
				creationMessage = nil
			}
		} catch {
			print("Error sending message: \(error)")
			await setErrorMessage(ErrorMessages.sendError)
		}
	}

	func refreshChat() async {
		// Construct URL
		guard let url = URL(string: APIService.baseURL + "activities/" + activity.id.uuidString + "/chats") else {
			await setErrorMessage(ErrorMessages.invalidConfig)
			return
		}

		do {
			let chats: [FullActivityChatMessageDTO] = try await apiService.fetchData(from: url, parameters: nil)

			await MainActor.run {
				// Only update if we actually got data
				if !chats.isEmpty || activity.chatMessages?.isEmpty == true {
					activity.chatMessages = chats
				}
				// Clear any error messages on successful refresh
				creationMessage = nil
			}
		} catch {
			print("Error refreshing chats: \(error)")
			// Only show refresh error if there are no existing messages
			if activity.chatMessages?.isEmpty != false {
				await setErrorMessage(ErrorMessages.refreshError)
			}
		}
	}
}
