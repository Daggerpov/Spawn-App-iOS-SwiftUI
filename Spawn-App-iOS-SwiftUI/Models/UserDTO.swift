//
//  User.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/6/24.
//

import Foundation

// My idea for now is that I'll be able to link a `User` to its `User`, such
// that the `User` struct still comforms to `Codable` (which an `Image` property
// would prevent if I included it in that struct).

// tech note: for new friend searching, it should first be done by username, but
// we could also search by first name and last name, if provided (thus, optional types).

struct UserDTO: Identifiable, Codable, Hashable {
	static func == (lhs: UserDTO, rhs: UserDTO) -> Bool {
		return lhs.id == rhs.id
	}

	var id: UUID
	var friends: [UserDTO]?
	var username: String
	var profilePicture: String?
	var firstName: String?
	var lastName: String?
	var bio: String?
	var friendTags: [FriendTag]?
	var email: String

	init(
		id: UUID,
		friends: [UserDTO]? = nil,
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

extension UserDTO {
	static var danielAgapov: UserDTO = {
		let id: UUID = UUID()
		let friends: [UserDTO] = [shannon, jennifer, michael, haley]
		return UserDTO(
			id: id,
			friends: friends,
			username: "daggerpov",
			profilePicture: "Daniel_Agapov_pfp",
			firstName: "Daniel",
			lastName: "Agapov",
			bio: "This is my bio.",
			friendTags: [
				FriendTag(
					id: UUID(),
					displayName: "Biztech",
					colorHexCode: eventColorHexCodes[0],
					friends: [shannon, jennifer]
				),
				FriendTag(
					id: UUID(),
					displayName: "Close Friends",
					colorHexCode: eventColorHexCodes[1],
					friends: [haley]
				),
				FriendTag(
					id: UUID(),
					displayName: "Hobbies",
					colorHexCode: eventColorHexCodes[2],
					friends: [jennifer, haley, shannon]
				),
			],
			email: "daniel@agapov.com"
		)
	}()

	static var danielLee: UserDTO = {
		let friends: [UserDTO] = [shannon, jennifer, michael, haley]
		let id: UUID = UUID()
		return UserDTO(
			id: id,
			friends: friends,
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
					friends: [shannon]
				),
				FriendTag(
					id: UUID(),
					displayName: "Close Friends",
					colorHexCode: eventColorHexCodes[1],
					friends: [haley]
				),
				FriendTag(
					id: UUID(),
					displayName: "Hobbies",
					colorHexCode: eventColorHexCodes[2],
					friends: [jennifer, haley, shannon]
				),
			],
			email: "daniel2456@gmail.com"
		)
	}()

	static func setupFriends() {
		// Set up mutual friends after all static properties are initialized
		danielAgapov.friends = [shannon, jennifer, michael, haley]
		danielAgapov.friendTags = [
			FriendTag(
				id: UUID(),
				displayName: "Biztech",
				colorHexCode: eventColorHexCodes[0],
				friends: [shannon]
			),
			FriendTag(
				id: UUID(),
				displayName: "Close Friends",
				colorHexCode: eventColorHexCodes[1],
				friends: [haley]
			),
			FriendTag(
				id: UUID(),
				displayName: "Hobbies",
				colorHexCode: eventColorHexCodes[2],
				friends: [jennifer, haley, shannon]
			),
		]

		shannon.friends = [danielAgapov]
		jennifer.friends = [danielAgapov, shannon]
		michael.friends = [danielAgapov, shannon, jennifer]
		haley.friends = [danielAgapov, shannon, jennifer, michael]

	}

	static var shannon: UserDTO = UserDTO(
		id: UUID(),
		friends: [],
		username: "shannonaurl",
		profilePicture: "Shannon_pfp",
		firstName: "Shannon",
		bio: "This is my bio.",
		email: "shannon@gmail.com"
	)

	static var jennifer: UserDTO = UserDTO(
		id: UUID(),
		friends: [],
		username: "jenntjen",
		profilePicture: "Jennifer_pfp",
		firstName: "Jennifer",
		lastName: "Tjen",
		bio: "This is my bio.",
		email: "jennifer@gmail.com"
	)

	static var michael: UserDTO = UserDTO(
		id: UUID(),
		friends: [],
		username: "michaeltham",
		profilePicture: "Michael_pfp",
		firstName: "Michael",
		lastName: "Tham",
		bio: "This is my bio.",
		email: "haley@gmail.com"
	)

	static var haley: UserDTO = UserDTO(
		id: UUID(),
		friends: [],
		username: "haleyusername",
		profilePicture: "Haley_pfp",
		firstName: "Haley",
		bio: "This is my bio.",
		email: "haley@gmail.com"
	)

	static let mockUsers: [UserDTO] = {
		return [danielAgapov, shannon, jennifer, michael, haley]
	}()
}

// temporary, until we have real data, to help with user mock objects:
class ObservableUser: ObservableObject {
	@Published private(set) var user: UserDTO

	init(user: UserDTO) {
		self.user = user
	}

	var id: UUID {
		user.id
	}

	var friends: [UserDTO]? {
		user.friends
	}
	var username: String {
		user.username
	}
	var profilePicture: String? {
		user.profilePicture
	}

	var firstName: String? {
		user.firstName
	}
	var lastName: String? {
		user.lastName
	}
	var bio: String? {
		user.bio
	}
	var friendTags: [FriendTag]? {
		user.friendTags
	}
}
