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
	var friendIds: [UUID]?// TODO DANIEL: change to friendIds
	var username: String
	var profilePicture: String?  // TODO: re-think data type later
	var firstName: String?
	var lastName: String?
	var bio: String?
	var friendTagIds: [UUID]? // TODO DANIEL: change to friendTagIds
	var email: String

	init(
		id: UUID,
		friendIds: [UUID]? = nil,
		username: String,
		profilePicture: String? = nil,
		firstName: String? = nil,
		lastName: String? = nil,
		bio: String? = nil,
		friendTagIds: [UUID]? = nil,
		email: String
	) {
		self.id = id
		self.friendIds = friendIds
		self.username = username
		self.profilePicture = profilePicture
		self.firstName = firstName
		self.lastName = lastName
		self.bio = bio
		self.friendTagIds = friendTagIds
		self.email = email
	}
}

extension User {
	static var danielAgapov: User = {
		let id: UUID = UUID()
		let friendIds: [UUID] = [shannon.id, jennifer.id, michael.id, haley.id]
		return User(
			id: id,
			friendIds: friendIds,
			username: "daggerpov",
			profilePicture: "Daniel_Agapov_pfp",
			firstName: "Daniel",
			lastName: "Agapov",
			bio: "This is my bio.",
			friendTagIds: [
				FriendTag(
					id: UUID(),
					displayName: "Biztech",
					colorHexCode: eventColorHexCodes[0],
					ownerId: id,
					friends: [shannon, jennifer]
				).id,
				FriendTag(
					id: UUID(),
					displayName: "Close Friends",
					colorHexCode: eventColorHexCodes[1],
					ownerId: id,
					friends: [haley]
				).id,
				FriendTag(
					id: UUID(),
					displayName: "Hobbies",
					colorHexCode: eventColorHexCodes[2],
					ownerId: id,
					friends: [jennifer, haley, shannon]
				).id,
			],
			email: "daniel@agapov.com"
		)
	}()

	static var danielLee: User = {
		let friendIds: [UUID] = [shannon.id, jennifer.id, michael.id, haley.id]
		let id: UUID = UUID()
		return User(
			id: id,
			friendIds: friendIds,
			username: "uhdlee",
			profilePicture: "Daniel_Lee_pfp",
			firstName: "Daniel",
			lastName: "Lee",
			bio: "This is my bio.",
			friendTagIds: [
				FriendTag(
					id: UUID(),
					displayName: "Biztech",
					colorHexCode: eventColorHexCodes[0],
					ownerId: id,
					friends: [shannon]
				).id,
				FriendTag(
					id: UUID(),
					displayName: "Close Friends",
					colorHexCode: eventColorHexCodes[1],
					ownerId: id,
					friends: [haley]
				).id,
				FriendTag(
					id: UUID(),
					displayName: "Hobbies",
					colorHexCode: eventColorHexCodes[2],
					ownerId: id,
					friends: [jennifer, haley, shannon]
				).id,
			],
			email: "daniel2456@gmail.com"
		)
	}()

	static func setupFriends() {
		// Set up mutual friends after all static properties are initialized
		danielAgapov.friendIds = [shannon.id, jennifer.id, michael.id, haley.id]
		danielAgapov.friendTagIds = [
			FriendTag(
				id: UUID(),
				displayName: "Biztech",
				colorHexCode: eventColorHexCodes[0],
				ownerId: danielAgapov.id,
				friends: [shannon]
			).id,
			FriendTag(
				id: UUID(),
				displayName: "Close Friends",
				colorHexCode: eventColorHexCodes[1],
				ownerId: danielAgapov.id,
				friends: [haley]
			).id,
			FriendTag(
				id: UUID(),
				displayName: "Hobbies",
				colorHexCode: eventColorHexCodes[2],
				ownerId: danielAgapov.id,
				friends: [jennifer, haley, shannon]
			).id,
		]

		shannon.friendIds = [danielAgapov.id]
		jennifer.friendIds = [danielAgapov.id, shannon.id]
		michael.friendIds = [danielAgapov.id, shannon.id, jennifer.id]
		haley.friendIds = [danielAgapov.id, shannon.id, jennifer.id, michael.id]

	}

	static var shannon: User = User(
		id: UUID(),
		friendIds: [],
		username: "shannonaurl",
		profilePicture: "Shannon_pfp",
		firstName: "Shannon",
		bio: "This is my bio.",
		email: "shannon@gmail.com"
	)

	static var jennifer: User = User(
		id: UUID(),
		friendIds: [],
		username: "jenntjen",
		profilePicture: "Jennifer_pfp",
		firstName: "Jennifer",
		lastName: "Tjen",
		bio: "This is my bio.",
		email: "jennifer@gmail.com"
	)

	static var michael: User = User(
		id: UUID(),
		friendIds: [],
		username: "michaeltham",
		profilePicture: "Michael_pfp",
		firstName: "Michael",
		lastName: "Tham",
		bio: "This is my bio.",
		email: "haley@gmail.com"
	)

	static var haley: User = User(
		id: UUID(),
		friendIds: [],
		username: "haleyusername",
		profilePicture: "Haley_pfp",
		firstName: "Haley",
		bio: "This is my bio.",
		email: "haley@gmail.com"
	)

	static let mockUsers: [User] = {
		return [danielAgapov, shannon, jennifer, michael, haley]
	}()
}

// temporary, until we have real data, to help with user mock objects:
class ObservableUser: ObservableObject {
	@Published private(set) var user: User

	init(user: User) {
		self.user = user
	}

	var id: UUID {
		user.id
	}

	var friendIds: [UUID]? {
		user.friendIds
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
	var friendTagIds: [UUID]? {
		user.friendTagIds
	}
}
