//
//  FullEventChatMessageDTO.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/6/24.
//

import Foundation

class FullEventChatMessageDTO: Identifiable, Codable, Equatable {
	var id: UUID
	var content: String
	var timestamp: Date
	var senderUser: BaseUserDTO
	var eventId: UUID
	// do I even need an `event` var here, if each `Event` has a list of chats?
	// -> it's a (event) 1 <-> many (chat) relationship
	var likedByUsers: [BaseUserDTO]?
	// tech note: in user's view of event, check if that user is in
	// the `ChatMessage`'s `likedBy` array (`[User]`)
	
	static func == (lhs: FullEventChatMessageDTO, rhs: FullEventChatMessageDTO) -> Bool {
		return lhs.id == rhs.id
	}

	init(
		id: UUID, content: String, timestamp: Date, senderUser: BaseUserDTO,
		eventId: UUID, likedByUsers: [BaseUserDTO]? = nil
	) {
		self.id = id
		self.content = content
		self.timestamp = timestamp
		self.senderUser = senderUser
		self.eventId = eventId
		self.likedByUsers = likedByUsers
	}
}

extension FullEventChatMessageDTO {
	var formattedTimestamp: String {
		return FormatterService.shared.timeAgo(from: timestamp)
	}

	static let dateFormatter: DateFormatter = {
		let formatter = DateFormatter()
		formatter.dateStyle = .short
		formatter.timeStyle = .short
		return formatter
	}()
	static let guysWya: FullEventChatMessageDTO = FullEventChatMessageDTO(
		id: UUID(),
		content: "yo guys, wya?",
		timestamp: Date().addingTimeInterval(-120),  // 2 minutes ago
		senderUser: BaseUserDTO.danielAgapov,
		eventId: Event.mockDinnerEvent.id,
		likedByUsers: [BaseUserDTO.danielAgapov, BaseUserDTO.danielLee]
	)
}
