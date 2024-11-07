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

struct FriendTag {
    var displayName: String
    var color: Color
    var friends: [AppUser]?
}

extension FriendTag {
    static let close = FriendTag(displayName: "Close Friends", color: Color(hex: "#704444"), friends: [AppUser.danielAgapov])
    static let sports = FriendTag(displayName: "Sports", color: Color(hex: "#8084ac"), friends: [AppUser.danielLee])
}
