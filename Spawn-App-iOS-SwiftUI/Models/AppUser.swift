//
//  AppUser.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel on 11/6/24.
//

import SwiftUI

// My idea for now is that I'll be able to link a `User` to its `AppUser`, such
// that the `User` struct still comforms to `Codable` (which an `Image` property
// would prevent if I included it in that struct).

// tech note: for new friend searching, it should first be done by username, but
// we could also search by first name and last name, if provided (thus, optional types).

// tech note: for friend finding in map, can use `lastLocation`

struct AppUser: Identifiable {
    var id: UUID
    var baseUser: User
    var username: String
    var profilePicture: Image?
    var firstName: String?
    var lastName: String?
    var bio: String?
    var friendTags: [FriendTag]?
    var lastLocation: Location?
}

extension AppUser {
    static let danielAgapov: AppUser = AppUser(
        id: UUID(),
        baseUser: User.danielAgapov,
        username: "daggerpov",
        firstName: "Daniel",
        lastName: "Agapov",
        bio: "This is my bio.",
        friendTags: [FriendTag(displayName: "Hobbies", friends: [AppUser.danielLee])]
    )
        
    static let danielLee: AppUser = AppUser(
        id: UUID(),
        baseUser: User.danielLee,
        username: "uhdlee",
        firstName: "Daniel",
        lastName: "Lee",
        bio: "This is my bio.",
        friendTags: [FriendTag.close, FriendTag.sports]
    )
}