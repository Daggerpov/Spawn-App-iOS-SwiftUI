//
//  User.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/6/24.
//

import SwiftUI

// My idea for now is that I'll be able to link a `User` to its `User`, such
// that the `User` struct still comforms to `Codable` (which an `Image` property
// would prevent if I included it in that struct).

// tech note: for new friend searching, it should first be done by username, but
// we could also search by first name and last name, if provided (thus, optional types).

struct User: Identifiable, Codable, Hashable {
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id
    }

    var id: UUID
    var friends: [User]?
    var username: String
    var profilePicture: String? // TODO: re-think data type later
    var firstName: String?
    var lastName: String?
    var bio: String?
    var friendTags: [FriendTag]?
    var email: String
    
    init(
        id: UUID,
        friends: [User]? = nil,
        username: String,
        profilePicture: String? = nil,
        firstName: String? = nil,
        lastName: String? = nil,
        bio: String? = nil,
        friendTags: [FriendTag]? = nil,
        email: String
    ) {
        self.id = id
        self.friends = friends
        self.username = username
        self.profilePicture = profilePicture
        self.firstName = firstName
        self.lastName = lastName
        self.bio = bio
        self.friendTags = friendTags
        self.email = email
        
        // Add friends to the user's default "Everyone" tag
        if let friends = friends {
            var everyoneTag = FriendTag(
                id: UUID(),
                displayName: "Everyone",
                colorHexCode: "#asdfdf",
                friends: []
            )
            
            everyoneTag.friends = friends
            
            // Insert the "Everyone" tag at the beginning of the friend's tags array
            self.friendTags?.insert(everyoneTag, at: 0)
        }
    }
}

extension User {
    static var danielAgapov: User = User(
        id: UUID(),
        friends: [],
        username: "daggerpov",
        profilePicture: "Daniel_Agapov_pfp",
        firstName: "Daniel",
        lastName: "Agapov",
        bio: "This is my bio.",
        friendTags: [FriendTag(id: UUID(), displayName: "Hobbies", colorHexCode: eventColorHexCodes.randomElement() ?? "#ffffff", friends: [User.danielLee])],
        email: "daniel@agapov.com"
    )
    
    static var shannon: User = User(
        id: UUID(),
        friends: [],
        username: "shannonaurl",
        profilePicture: "Shannon_pfp",
        firstName: "Shannon",
        bio: "This is my bio.",
        email: "shannon@gmail.com"
    )
    static var jennifer: User = User(
        id: UUID(),
        friends: [],
        username: "jenntjen",
        profilePicture: "Jennifer_pfp",
        firstName: "Jennifer",
        lastName: "Tjen",
        bio: "This is my bio.",
        email: "jennifer@gmail.com"
    )
    static var michael: User = User(
        id: UUID(),
        friends: [],
        username: "michaeltham",
        profilePicture: "Michael_pfp",
        firstName: "Michael",
        lastName: "Tham",
        bio: "This is my bio.",
        email: "haley@gmail.com"
    )
    static var haley: User = User(
        id: UUID(),
        friends: [],
        username: "haleyusername",
        profilePicture: "Haley_pfp",
        firstName: "Haley",
        bio: "This is my bio.",
        email: "haley@gmail.com"
    )
    
    static let emptyUser: User = User(
        id: UUID(),
        friends: [],
        username: "empty username",
        bio: "This is my bio.",
        email: "haley@gmail.com"
    )
    
    // MARK: this method of setting up danielLee's friends
    // is messy, but works. The `setupFriends()` method
    // below doesn't quite do the job.
    
    // Can't be asked to fix this, since it's just for mocking
    
    static var danielLeeFrienddanielAgapov: User = User(
        id: UUID(),
        friends: [],
        username: "daggerpov",
        profilePicture: "Daniel_Agapov_pfp",
        firstName: "Daniel",
        lastName: "Agapov",
        bio: "This is my bio.",
        email: "daniel@agapov.com"
    )
    
    static var danielLeeFriendshannon: User = User(
        id: UUID(),
        friends: [],
        username: "shannonaurl",
        profilePicture: "Shannon_pfp",
        firstName: "Shannon",
        bio: "This is my bio.",
        email: "shannon@gmail.com"
    )
    static var danielLeeFriendjennifer: User = User(
        id: UUID(),
        friends: [],
        username: "jenntjen",
        profilePicture: "Jennifer_pfp",
        firstName: "Jennifer",
        lastName: "Tjen",
        bio: "This is my bio.",
        email: "jennifer@gmail.com"
    )
    static var danielLeeFriendmichael: User = User(
        id: UUID(),
        friends: [],
        username: "michaeltham",
        profilePicture: "Michael_pfp",
        firstName: "Michael",
        lastName: "Tham",
        bio: "This is my bio.",
        email: "haley@gmail.com"
    )
    static var danielLeeFriendhaley: User = User(
        id: UUID(),
        friends: [],
        username: "haleyusername",
        profilePicture: "Haley_pfp",
        firstName: "Haley",
        bio: "This is my bio.",
        email: "haley@gmail.com"
    )
    
    static let danielLeeFriendemptyUser: User = User(
        id: UUID(),
        friends: [],
        username: "empty username",
        bio: "This is my bio.",
        email: "haley@gmail.com"
    )
    
    static var danielLee: User = User(
        id: UUID(),
        friends: [
            emptyUser,
            danielLeeFriendhaley,
            danielLeeFriendmichael,
            danielLeeFriendshannon,
            danielLeeFriendjennifer,
            danielLeeFriendemptyUser,
            danielLeeFrienddanielAgapov
        ],
        username: "uhdlee",
        profilePicture: "Daniel_Lee_pfp",
        firstName: "Daniel",
        lastName: "Lee",
        bio: "This is my bio.",
        friendTags: [
            FriendTag(
                id: UUID(),
                displayName: "Biztech",
                colorHexCode: eventColorHexCodes[0],
                friends: [User.shannon]
            ),
            FriendTag(
                id: UUID(),
                displayName: "Close Friends",
                colorHexCode: eventColorHexCodes[1],
                friends: [User.haley]
            ),
            FriendTag(
                id: UUID(),
                displayName: "Hobbies",
                colorHexCode: eventColorHexCodes[2],
                friends: [User.jennifer, User.haley, User.shannon]
            )
        ],
        email: "daniel2456@gmail.com"
    )
    
    static func setupFriends() {
        danielAgapov.friends = [shannon, jennifer, michael, haley]
        shannon.friends = [danielAgapov]
        jennifer.friends = [danielAgapov, shannon]
        michael.friends = [danielAgapov, shannon, jennifer]
        haley.friends = [danielAgapov, shannon, jennifer, michael]
    }
    
    static let mockUsers: [User] = {
        return [danielAgapov, shannon, jennifer, michael, haley]
    } ()
}
