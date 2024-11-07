//
//  FriendTag.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel on 11/6/24.
//

// The idea is to have the friends the logged in user has marked
// with a certain tag be contained within that friend tag.

// Tech note: when filtering feed based on friend tags, I can simply check
// the events against the event creator and see whether the event creator is
// one of the `FriendTag`'s `friends`.

struct FriendTag {
    var displayName: String
    var friends: [AppUser]?
}

extension FriendTag {
    static let close = FriendTag(displayName: "Close Friends", friends: [AppUser.danielAgapov])
    static let sports = FriendTag(displayName: "Sports", friends: [AppUser.danielLee])
}
