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
    var email: String

	init(
		baseUser: User,
		username: String,
		profilePicture: Image? = nil,
		firstName: String? = nil,
		lastName: String? = nil,
		bio: String? = nil,
		friendTags: [FriendTag]? = nil,
		lastLocation: Location? = nil,
        email: String
	) {
		self.baseUser = baseUser
		self.username = username
		self.profilePicture = profilePicture
		self.firstName = firstName
		self.lastName = lastName
		self.bio = bio
        self.friendTags = friendTags
		self.lastLocation = lastLocation
        self.email = email
        
        // Add friends to the user's default "Everyone" tag
        if let friends = baseUser.friends {
            let everyoneTag = FriendTag(
                id: UUID(),
                displayName: "Everyone",
                color: Color(hex: "#asdfdf"),
                friends: []
            )
            
            // Append friends to the "Everyone" tag
            for friend in friends {
                if let appUser = AppUserService.shared.appUserLookup[friend.id] {
                    everyoneTag.friends?.append(appUser)
                }
            }
            
            // Insert the "Everyone" tag at the beginning of the friend's tags array
            self.friendTags?.insert(everyoneTag, at: 0)
        }
	}
}

extension AppUser {
    static let danielAgapov: AppUser = AppUser(
		baseUser: User.danielAgapov,
        username: "daggerpov",
        profilePicture: Image("Daniel_Agapov_pfp"),
        firstName: "Daniel",
        lastName: "Agapov",
        bio: "This is my bio.",
        friendTags: [FriendTag(id: UUID(), displayName: "Hobbies", color: eventColors.randomElement() ?? Color.blue, friends: [AppUser.danielLee])],
        email: "daniel@agapov.com"
    )
        
    static let danielLee: AppUser = AppUser(
        baseUser: User.danielLee,
        username: "uhdlee",
        profilePicture: Image("Daniel_Lee_pfp"),
        firstName: "Daniel",
        lastName: "Lee",
        bio: "",
        friendTags: [
            FriendTag(
                id: UUID(),
                displayName: "Biztech",
                color: eventColors[0],
                friends: [AppUser.shannon]
            ),
            FriendTag(
                id: UUID(),
                displayName: "Close Friends",
                color: eventColors[1],
                friends: [AppUser.haley]
            ),
            FriendTag(
                id: UUID(),
                displayName: "Hobbies",
                color: eventColors[2],
                friends: [AppUser.jennifer, AppUser.haley, AppUser.shannon]
            )
        ],
        lastLocation: Location.mockLocation,
        email: "daniel2456@gmail.com"
    )

    static let shannon: AppUser = AppUser(
        baseUser: User.shannon,
        username: "shannonaurl",
        profilePicture: Image("Shannon_pfp"),
        firstName: "Shannon",
        bio: "This is my bio.",
        email: "shannon@gmail.com"
    )
    static let jennifer: AppUser = AppUser(
        baseUser: User.jennifer,
        username: "jenntjen",
        profilePicture: Image("Jennifer_pfp"),
        firstName: "Jennifer",
        lastName: "Tjen",
        bio: "This is my bio.",
        email: "jennifer@gmail.com"
    )
    static let michael: AppUser = AppUser(
        baseUser: User.michael,
        username: "michaeltham",
        profilePicture: Image("Michael_pfp"),
        firstName: "Michael",
        lastName: "Tham",
        bio: "This is my bio.",
        email: "michael@gmail.com"
    )
    static let haley: AppUser = AppUser(
        baseUser: User.haley,
        username: "haleyusername",
        profilePicture: Image("Haley_pfp"),
        firstName: "Haley",
        bio: "This is my bio.",
        email: "haley@gmail.com"
    )
    
    static let emptyUser: AppUser = AppUser(
        baseUser: User.emptyUser,
        username: "Empty User",
        email: "empty@gmail.com"
    )

    static let mockAppUsers: [AppUser] = [danielAgapov, danielLee, shannon, jennifer, michael, haley]
}


