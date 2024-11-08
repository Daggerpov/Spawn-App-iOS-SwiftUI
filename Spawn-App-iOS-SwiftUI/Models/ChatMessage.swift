//
//  ChatMessage.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/6/24.
//

import Foundation

class ChatMessage: Identifiable, Codable {
    var id: UUID
    var timestamp: String // TODO: change data type alter
    var user: User
    // do I even need an `event` var here, if each `Event` has a list of chats?
    // -> it's a (event) 1 <-> many (chat) relationship
    var likedBy: [User]?
    // tech note: in user's view of event, check if that user is in
    // the `ChatMessage`'s `likedBy` array (`[User]`)

	init(id: UUID, timestamp: String, user: User, likedBy: [User]? = nil) {
		self.id = id
		self.timestamp = timestamp
		self.user = user
		self.likedBy = likedBy
	}
}
