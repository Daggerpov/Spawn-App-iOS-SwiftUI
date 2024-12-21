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
    var timestamp: String // TODO: change data type alter
    var userSenderId: UUID
	var eventId: UUID
    // do I even need an `event` var here, if each `Event` has a list of chats?
    // -> it's a (event) 1 <-> many (chat) relationship
    var likedBy: [User]?
    // tech note: in user's view of event, check if that user is in
    // the `ChatMessage`'s `likedBy` array (`[User]`)

    init(id: UUID, message: String, timestamp: String, user: User, likedBy: [User]? = nil) {
		self.id = id
        self.content = message
		self.timestamp = timestamp
		self.userSenderId = user
		self.likedBy = likedBy
	}
}

extension ChatMessage {
    static let guysWya: ChatMessage = ChatMessage(
        id: UUID(),
        message: "yo guys, wya?",
        timestamp: "2 minutes ago",
        user: User.michael,
        likedBy: User.mockUsers
    )
}
