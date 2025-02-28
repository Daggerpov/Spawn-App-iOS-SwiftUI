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
	var friends: [UserDTO]?
	var username: String
	var profilePicture: String?
	var firstName: String?
	var lastName: String?
	var bio: String?
	var friendTags: [FriendTag]?
	var email: String
	var associatedFriendTagsToOwner: [FriendTag]?  // only added property from `User`

	init(
		id: UUID,
		friends: [UserDTO]? = nil,
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

extension FriendUserDTO {
	static var danielAgapov: FriendUserDTO = {
		let id: UUID = UUID()
		return FriendUserDTO(
			id: id,
			username: "daggerpov",
			profilePicture: "Daniel_Agapov_pfp",
			firstName: "Daniel",
			lastName: "Agapov",
			bio: "This is my bio.",
			friendTags: [
				FriendTag(
					id: UUID(),
					displayName: "Biztech",
					colorHexCode: eventColorHexCodes[0]
				),
				FriendTag(
					id: UUID(),
					displayName: "Close Friends",
					colorHexCode: eventColorHexCodes[1]
				),
				FriendTag(
					id: UUID(),
					displayName: "Hobbies",
					colorHexCode: eventColorHexCodes[2]
				),
			],
			email: "daniel@agapov.com",
			associatedFriendTagsToOwner: [
				FriendTag(
					id: UUID(),
					displayName: "Close Friends",
					colorHexCode: eventColorHexCodes[1]
				),
				FriendTag(
					id: UUID(),
					displayName: "Hobbies",
					colorHexCode: eventColorHexCodes[2]
				),
			]
		)
	}()

	static var danielLee: FriendUserDTO = {
		let id: UUID = UUID()
		return FriendUserDTO(
			id: id,
			username: "uhdlee",
			profilePicture: "Daniel_Lee_pfp",
			firstName: "Daniel",
			lastName: "Lee",
			bio: "This is my bio.",
			friendTags: [
				FriendTag(
					id: UUID(),
					displayName: "Biztech",
					colorHexCode: eventColorHexCodes[0]
				),
				FriendTag(
					id: UUID(),
					displayName: "Close Friends",
					colorHexCode: eventColorHexCodes[1]
				),
				FriendTag(
					id: UUID(),
					displayName: "Hobbies",
					colorHexCode: eventColorHexCodes[2]
				),
			],
			email: "daniel2456@gmail.com",
			associatedFriendTagsToOwner: [
				FriendTag(
					id: UUID(),
					displayName: "Biztech",
					colorHexCode: eventColorHexCodes[0]
				),
				FriendTag(
					id: UUID(),
					displayName: "Close Friends",
					colorHexCode: eventColorHexCodes[1]
				),
				FriendTag(
					id: UUID(),
					displayName: "Hobbies",
					colorHexCode: eventColorHexCodes[2]
				),
			]
		)
	}()

	static let mockUsers: [FriendUserDTO] = {
		return [danielAgapov, danielLee]
	}()
}
