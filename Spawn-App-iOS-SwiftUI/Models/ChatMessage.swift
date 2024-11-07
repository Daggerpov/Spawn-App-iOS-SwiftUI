//
//  ChatMessage.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel on 11/6/24.
//

import Foundation

struct ChatMessage: Identifiable, Codable {
    var id: UUID
    var timestamp: String // TODO: change data type alter
    var user: User
    // do I even need an `event` var here, if each `Event` has a list of chats?
    // -> it's a (event) 1 <-> many (chat) relationship
    var likedBy: [User]?
    // tech note: in user's view of event, check if that user is in
    // the `ChatMessage`'s `likedBy` array (`[User]`)
}
