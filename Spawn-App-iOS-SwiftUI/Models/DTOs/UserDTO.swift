//
//  UserDTO.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-02-27.
//

import Foundation

struct UserDTO: Identifiable, Codable, Hashable {
	static func == (lhs: UserDTO, rhs: User) -> Bool {
		return lhs.id == rhs.id
	}

	var id: UUID
	var friends: [User]?
	var username: String
	var profilePicture: String?
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
