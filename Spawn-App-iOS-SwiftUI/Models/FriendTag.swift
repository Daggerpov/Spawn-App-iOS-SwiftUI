//
//  FriendTag.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/6/24.
//

// The idea is to have the friends the logged in user has marked
// with a certain tag be contained within that friend tag.

// Tech note: when filtering feed based on friend tags, I can simply check
// the events against the event creator and see whether the event creator is
// one of the `FriendTag`'s `friends`.

import Foundation

class FriendTag: Identifiable {
    var id: UUID
    var displayName: String
    var colorHexCode: String
    var friends: [AppUser]?

    init(id: UUID, displayName: String, colorHexCode: String, friends: [AppUser]? = nil) {
        self.id = id
        self.displayName = displayName
		self.colorHexCode = colorHexCode
		self.friends = friends
	}
}

extension FriendTag {
    static let close = FriendTag(id: UUID(), displayName: "Close Friends", colorHexCode: "#9CA3DA", friends: [AppUser.danielAgapov])
    static let sports = FriendTag(id: UUID(), displayName: "Sports", colorHexCode: "#CB4B2E", friends: [AppUser.danielLee])
    static let hobbies = FriendTag(id: UUID(), displayName: "Hobbies", colorHexCode: "#A2C587", friends: [AppUser.danielLee])
    static let mockTags = [close, sports, hobbies]
}
