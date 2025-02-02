//
//  FriendUserDTO.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-02-02.
//

import Foundation

struct FriendUserDTO: Identifiable, Codable, Hashable {
	static func == (lhs: FriendUserDTO, rhs: FriendUserDTO) -> Bool {
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
	var associatedFriendTagsToOwner: [FriendTag]? // only added property from `User`

	init(
		id: UUID,
		friends: [User]? = nil,
		username: String,
		profilePicture: String? = nil,
		firstName: String? = nil,
		lastName: String? = nil,
		bio: String? = nil,
		friendTags: [FriendTag]? = nil,
		email: String,
		associatedFriendTagsToOwner: [FriendTag]? = nil
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
		self.associatedFriendTagsToOwner = associatedFriendTagsToOwner

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
