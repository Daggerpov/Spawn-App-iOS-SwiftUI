//
//  AppUser.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/6/24.
//

import SwiftUI

// My idea for now is that I'll be able to link a `User` to its `AppUser`, such
// that the `User` struct still comforms to `Codable` (which an `Image` property
// would prevent if I included it in that struct).

// tech note: for new friend searching, it should first be done by username, but
// we could also search by first name and last name, if provided (thus, optional types).

// tech note: for friend finding in map, can use `lastLocation`

class AppUser: Identifiable {
	var id: UUID {
		baseUser.id
	}
	var baseUser: User
	var username: String
	var profilePicture: Image?
	var firstName: String?
	var lastName: String?
	var bio: String?
	var friendTags: [FriendTag]?
	var lastLocation: Location?

	init(
		baseUser: User,
		username: String,
		profilePicture: Image? = nil,
		firstName: String? = nil,
		lastName: String? = nil,
		bio: String? = nil,
		friendTags: [FriendTag]? = nil,
		lastLocation: Location? = nil
	) {
		self.baseUser = baseUser
		self.username = username
		self.profilePicture = profilePicture
		self.firstName = firstName
		self.lastName = lastName
		self.bio = bio
		self.friendTags = friendTags
		self.lastLocation = lastLocation
	}
}

extension AppUser {
    static let danielAgapov: AppUser = AppUser(
		baseUser: User.danielAgapov,
        username: "daggerpov",
        firstName: "Daniel",
        lastName: "Agapov",
        bio: "This is my bio.",
        friendTags: [FriendTag(displayName: "Hobbies", color: colors.randomElement() ?? Color.blue, friends: [AppUser.danielLee])]
    )
        
    static let danielLee: AppUser = AppUser(
        baseUser: User.danielLee,
        username: "uhdlee",
        firstName: "Daniel",
        lastName: "Lee",
        bio: "This is my bio.",
        friendTags: [FriendTag.close, FriendTag.sports]
    )
}
