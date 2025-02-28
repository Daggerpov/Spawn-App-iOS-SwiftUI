//
//  ChatMessage.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/6/24.
//

import Foundation

class ChatMessage: Identifiable, Codable {
	var id: UUID
	var content: String
	var timestamp: Date
	var senderUser: UserDTO
	var eventId: UUID
	// do I even need an `event` var here, if each `Event` has a list of chats?
	// -> it's a (event) 1 <-> many (chat) relationship
	var likedBy: [UserDTO]?
	// tech note: in user's view of event, check if that user is in
	// the `ChatMessage`'s `likedBy` array (`[User]`)

	init(
		id: UUID, content: String, timestamp: Date, senderUser: UserDTO,
		eventId: UUID, likedBy: [UserDTO]? = nil
	) {
		self.id = id
		self.content = content
		self.timestamp = timestamp
		self.senderUser = senderUser
		self.eventId = eventId
		self.likedBy = likedBy
	}
}

extension ChatMessage {
	var formattedTimestamp: String {
		return FormatterService.shared.timeAgo(from: timestamp)
	}

	static let dateFormatter: DateFormatter = {
		let formatter = DateFormatter()
		formatter.dateStyle = .short
		formatter.timeStyle = .short
		return formatter
	}()
	static let guysWya: ChatMessage = ChatMessage(
		id: UUID(),
		content: "yo guys, wya?",
		timestamp: Date().addingTimeInterval(-120),  // 2 minutes ago
		senderUser: UserDTO.michael,
		eventId: Event.mockDinnerEvent.id,
		likedBy: UserDTO.mockUsers
	)
}
