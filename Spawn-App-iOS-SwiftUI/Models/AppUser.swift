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

struct AppUser: Identifiable {
    var id: UUID
    var baseUser: User
    var profilePicture: Image?
    var username: String
    var firstName: String?
    var lastName: String?
    var bio: String?
    var friendTags: [FriendTag]?
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
