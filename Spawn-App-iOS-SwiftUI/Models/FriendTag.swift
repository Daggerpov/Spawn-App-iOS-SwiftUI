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

import SwiftUI

class FriendTag: Identifiable {
    var id: UUID
    var displayName: String
    var color: Color
    var friends: [AppUser]?

    init(id: UUID, displayName: String, color: Color, friends: [AppUser]? = nil) {
        self.id = id
        self.displayName = displayName
		self.color = color
		self.friends = friends
	}
}

extension FriendTag {
    static let close = FriendTag(id: UUID(), displayName: "Close Friends", color: Color(hex: "#704444"), friends: [AppUser.danielAgapov])
    static let sports = FriendTag(id: UUID(), displayName: "Sports", color: Color(hex: "#8084ac"), friends: [AppUser.danielLee])
}
