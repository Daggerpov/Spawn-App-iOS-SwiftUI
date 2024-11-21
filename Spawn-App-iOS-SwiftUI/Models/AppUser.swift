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

class AppUser: Identifiable, Codable {
    var id: UUID
    var friends: [AppUser]?
	var baseUser: User
	var username: String
	var profilePicture: String? // TODO: re-think data type later
	var firstName: String?
	var lastName: String?
	var bio: String?
	var friendTags: [FriendTag]?
	var lastLocation: Location?

	init(
        id: UUID,
        friends: [AppUser]? = nil,
		username: String,
		profilePicture: Image? = nil,
		firstName: String? = nil,
		lastName: String? = nil,
		bio: String? = nil,
		friendTags: [FriendTag]? = nil,
		lastLocation: Location? = nil
	) {
        self.id = id
        self.friends = friends
		self.username = username
		self.profilePicture = profilePicture
		self.firstName = firstName
		self.lastName = lastName
		self.bio = bio
        self.friendTags = friendTags
		self.lastLocation = lastLocation
        
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
        id: UUID(),
        friends: [],
        username: "daggerpov",
        profilePicture: Image("Daniel_Agapov_pfp"),
        firstName: "Daniel",
        lastName: "Agapov",
        bio: "This is my bio.",
        friendTags: [FriendTag(id: UUID(), displayName: "Hobbies", color: eventColors.randomElement() ?? Color.blue, friends: [AppUser.danielLee])]
    )
    
    static let danielLee: AppUser = AppUser(
        id: UUID(),
        friends: [],
        username: "uhdlee",
        profilePicture: Image("Daniel_Lee_pfp"),
        firstName: "Daniel",
        lastName: "Lee",
        bio: "This is my bio.",
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
        lastLocation: Location.mockLocation
    )
    
    static let shannon: AppUser = AppUser(
        id: UUID(),
        friends: [],
        username: "shannonaurl",
        profilePicture: Image("Shannon_pfp"),
        firstName: "Shannon",
        bio: "This is my bio."
    )
    static let jennifer: AppUser = AppUser(
        id: UUID(),
        friends: [],
        username: "jenntjen",
        profilePicture: Image("Jennifer_pfp"),
        firstName: "Jennifer",
        lastName: "Tjen",
        bio: "This is my bio."
    )
    static let michael: AppUser = AppUser(
        id: UUID(),
        friends: [],
        username: "michaeltham",
        profilePicture: Image("Michael_pfp"),
        firstName: "Michael",
        lastName: "Tham",
        bio: "This is my bio."
    )
    static let haley: AppUser = AppUser(
        id: UUID(),
        friends: [],
        username: "haleyusername",
        profilePicture: Image("Haley_pfp"),
        firstName: "Haley",
        bio: "This is my bio."
    )
    
    static let emptyUser: AppUser = AppUser(
        id: UUID(),
        friends: [],
        username: "Empty User"
    )
    
    static func setupFriends() {
        danielAgapov.friends = [danielLee, shannon, jennifer, michael, haley]
        danielLee.friends = [danielAgapov, jennifer, haley]
        shannon.friends = [danielAgapov, danielLee]
        jennifer.friends = [danielAgapov, danielLee, shannon]
        michael.friends = [danielAgapov, danielLee, shannon, jennifer]
        haley.friends = [danielAgapov, danielLee, shannon, jennifer, michael]
    }
    
    static let mockAppUsers: [AppUser] = {
        setupFriends()
        return [danielAgapov, danielLee, shannon, jennifer, michael, haley]
    } ()
}
