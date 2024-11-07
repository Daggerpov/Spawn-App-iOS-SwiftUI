//
//  FriendTag.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel on 11/6/24.
//

// The idea is to have the friends the logged in user has marked
// with a certain tag be contained within that friend tag.

struct FriendTag {
    var displayName: String
    var friends: [AppUser]?
}
