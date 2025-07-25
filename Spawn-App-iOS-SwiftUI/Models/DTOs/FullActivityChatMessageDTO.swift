//
//  FullActivityChatMessageDTO.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/6/24.
//

import Foundation

class FullActivityChatMessageDTO: Identifiable, Codable, Equatable {
	var id: UUID
	var content: String
	var timestamp: Date
	var senderUser: BaseUserDTO
	var activityId: UUID
	// do I even need an `activity` var here, if each `Activity` has a list of chats?
	// -> it's a (activity) 1 <-> many (chat) relationship
	var likedByUsers: [BaseUserDTO]?
	// tech note: in user's view of activity, check if that user is in
	// the `ChatMessage`'s `likedBy` array (`[User]`)
	
	static func == (lhs: FullActivityChatMessageDTO, rhs: FullActivityChatMessageDTO) -> Bool {
		return lhs.id == rhs.id
	}

	init(
		id: UUID, content: String, timestamp: Date, senderUser: BaseUserDTO,
		activityId: UUID, likedByUsers: [BaseUserDTO]? = nil
	) {
		self.id = id
		self.content = content
		self.timestamp = timestamp
		self.senderUser = senderUser
		self.activityId = activityId
		self.likedByUsers = likedByUsers
	}
}

extension FullActivityChatMessageDTO {
	var formattedTimestamp: String {
		return FormatterService.shared.timeAgo(from: timestamp)
	}

	static let dateFormatter: DateFormatter = {
		let formatter = DateFormatter()
		formatter.dateStyle = .short
		formatter.timeStyle = .short
		return formatter
	}()

	static let mockChat1: FullActivityChatMessageDTO = FullActivityChatMessageDTO(
		id: UUID(),
		content: "yo guys, wya?",
		timestamp: Date().addingTimeInterval(-120),  // 2 minutes ago
		senderUser: BaseUserDTO.haley,
		activityId: FullFeedActivityDTO.mockDinnerActivity.id,
		likedByUsers: [BaseUserDTO.danielAgapov]
	)

	static let mockChat2: FullActivityChatMessageDTO = FullActivityChatMessageDTO(
		id: UUID(),
		content: "im by the SUBWAY!",
		timestamp: Date().addingTimeInterval(-30),  // 30s ago
		senderUser: BaseUserDTO.danielAgapov,
		activityId: FullFeedActivityDTO.mockDinnerActivity.id,
		likedByUsers: [BaseUserDTO.danielAgapov, BaseUserDTO.danielLee]
	)

	static let mockChat3: FullActivityChatMessageDTO = FullActivityChatMessageDTO(
		id: UUID(),
		content: "Please hurry up..",
		timestamp: Date().addingTimeInterval(-1),  // 1s ago
		senderUser: BaseUserDTO.danielLee,
		activityId: FullFeedActivityDTO.mockDinnerActivity.id,
		likedByUsers: []
	)

	static let mockChat4: FullActivityChatMessageDTO = FullActivityChatMessageDTO(
		id: UUID(),
		content: "Yo try to be there early",
		timestamp: Date().addingTimeInterval(-60 * 60),  // 1 hour ago
		senderUser: BaseUserDTO.danielAgapov,
		activityId: FullFeedActivityDTO.mockDinnerActivity.id,
		likedByUsers: [BaseUserDTO.haley, BaseUserDTO.danielLee, BaseUserDTO.danielAgapov]
	)

	static let mockChatroom: [FullActivityChatMessageDTO] = [.mockChat4, .mockChat1, .mockChat2, .mockChat3]
}
